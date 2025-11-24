import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabaseUrl, supabaseAnonKey;

/// Result of document classification
class DocumentClassificationResult {
  final bool isAcademic;
  final int score;
  final String text;
  final String reason;
  final List<String>? matchedKeywords;

  const DocumentClassificationResult({
    required this.isAcademic,
    required this.score,
    required this.text,
    required this.reason,
    this.matchedKeywords,
  });

  /// Check if document is valid (academic)
  bool get isValid => isAcademic;
}

/// Service for classifying documents using Donut-base model
/// Supports both Supabase Edge Functions and standalone servers (Railway, Render, etc.)
class DocumentClassifierService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Configurable classification server URL
  // Set this to your deployed server URL (Railway, Render, etc.)
  // Leave null to use Supabase Edge Function
  static const String customClassificationUrl = 'https://majorproject-production-a70b.up.railway.app';
  
  /// Get the classification endpoint URL
  String get _classificationUrl {
    // Use Railway server (hardcoded for reliability)
    const railwayUrl = 'https://majorproject-production-a70b.up.railway.app';
    if (railwayUrl.isNotEmpty) {
      // Use Railway server
      return railwayUrl.endsWith('/classify') 
          ? railwayUrl 
          : '${railwayUrl.replaceAll(RegExp(r'/$'), '')}/classify';
    }
    // Fallback to customClassificationUrl if railwayUrl is empty (should not happen)
    if (customClassificationUrl.isNotEmpty) {
      return customClassificationUrl.endsWith('/classify') 
          ? customClassificationUrl 
          : '${customClassificationUrl.replaceAll(RegExp(r'/$'), '')}/classify';
    }
    // Default: Use Supabase Edge Function (should not be used)
    return '$supabaseUrl/functions/v1/classifyDocument';
  }
  
  /// Check if using custom server (doesn't need auth token)
  bool get _usesCustomServer => customClassificationUrl.isNotEmpty;

  /// Test connection to classification server
  /// Returns true if server is reachable, false otherwise
  Future<bool> testConnection() async {
    try {
      final healthUrl = _classificationUrl.replaceAll('/classify', '/health');
      if (kDebugMode) {
        debugPrint('🔍 Testing connection to: $healthUrl');
      }
      
      final response = await http.get(
        Uri.parse(healthUrl),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Server connection successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Server returned status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Connection test failed: $e');
      }
      return false;
    }
  }

  /// Classify a document image using Donut-base model
  /// 
  /// Sends the image to the classification server (Supabase Edge Function or standalone)
  /// which uses the Donut-base Vision Transformer to extract text and classify
  /// the document as academic or non-academic.
  /// 
  /// Args:
  ///   - fileBytes: Raw image bytes (JPEG/PNG)
  ///   - fileName: Optional filename for logging
  /// 
  /// Returns:
  ///   - DocumentClassificationResult with classification details
  Future<DocumentClassificationResult> classifyDocument({
    required Uint8List fileBytes,
    String? fileName,
  }) async {
    try {
      final functionUrl = _classificationUrl;
      
      // Debug: Log the URL being used (using debugPrint for Flutter best practices)
      if (kDebugMode) {
        debugPrint('🔍 Classification URL: $functionUrl');
        debugPrint('🔍 Railway URL: https://majorproject-production-a70b.up.railway.app');
        debugPrint('🔍 Using custom server: $_usesCustomServer');
        debugPrint('🔍 File size: ${fileBytes.length} bytes');
        debugPrint('🔍 File name: ${fileName ?? "unknown"}');
      }
      
      // Verify we're using Railway, not Supabase
      if (functionUrl.contains('supabase.co')) {
        throw Exception('ERROR: Still using Supabase URL! Expected Railway URL. Please restart the app completely.');
      }
      
      // For web, use base64 encoding (more reliable than multipart on web)
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('🌐 Using base64 encoding for web platform');
        }
        return await classifyDocumentBase64(
          fileBytes: fileBytes,
          fileName: fileName,
        );
      }
      
      // For mobile/desktop, use multipart
      if (kDebugMode) {
        debugPrint('📱 Using multipart encoding for mobile/desktop platform');
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(functionUrl));
      
      // Add authorization header (only for Supabase Edge Functions)
      if (!_usesCustomServer) {
        final session = _supabase.auth.currentSession;
        final authToken = session?.accessToken ?? supabaseAnonKey;
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Don't set Content-Type header - let http package set it with boundary
      
      // Add file as multipart
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'document.jpg',
        ),
      );
      
      if (kDebugMode) {
        debugPrint('📤 Sending request to: $functionUrl');
      }
      
      // Send request with extended timeout (first request loads model, takes 30-60s)
      // Total timeout: 120 seconds for request + 60 seconds for response = 180s max
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Request timeout: Server did not respond within 120 seconds. This may happen on the first request while the model is loading. Please try again.');
        },
      );
      
      if (kDebugMode) {
        debugPrint('📥 Received response: ${streamedResponse.statusCode}');
      }
      
      final response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Response timeout: Could not read response body within 60 seconds. The model may still be loading. Please try again.');
        },
      );
      
      if (kDebugMode) {
        debugPrint('📄 Response body length: ${response.body.length}');
        debugPrint('📄 Response status: ${response.statusCode}');
      }
      
      // Parse response
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          
          if (kDebugMode) {
            debugPrint('✅ Classification successful: ${jsonResponse['is_academic']}');
            debugPrint('📊 Score: ${jsonResponse['score']}');
          }
          
          return DocumentClassificationResult(
            isAcademic: jsonResponse['is_academic'] as bool? ?? false,
            score: jsonResponse['score'] as int? ?? 0,
            text: jsonResponse['text'] as String? ?? '',
            reason: jsonResponse['reason'] as String? ?? 'No reason provided',
            matchedKeywords: jsonResponse['matched_keywords'] != null
                ? List<String>.from(jsonResponse['matched_keywords'] as List)
                : null,
          );
        } catch (parseError) {
          if (kDebugMode) {
            debugPrint('❌ JSON parse error: $parseError');
            debugPrint('❌ Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          }
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Invalid response from server. Please check server logs.',
          );
        }
      } else {
        // Handle error response
        if (kDebugMode) {
          debugPrint('❌ Error response: ${response.statusCode}');
          debugPrint('❌ Response body: ${response.body}');
        }
        
        try {
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorJson['error'] as String? ?? 
                              errorJson['message'] as String? ?? 
                              'Unknown error';
          
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: $errorMessage (HTTP ${response.statusCode})',
          );
        } catch (_) {
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: HTTP ${response.statusCode} - ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}',
          );
        }
      }
    } catch (e, stackTrace) {
      // Handle network or other errors
      if (kDebugMode) {
        debugPrint('❌ Classification exception: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      
      String errorMessage = e.toString();
      
      // Provide more helpful error messages
      if (errorMessage.contains('Failed host lookup') || errorMessage.contains('SocketException')) {
        errorMessage = 'Cannot connect to classification server. Please check your internet connection and ensure the server is running.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Request timed out. The server may be overloaded. Please try again.';
      } else if (errorMessage.contains('CORS')) {
        errorMessage = 'CORS error. Please check server CORS configuration.';
      }
      
      return DocumentClassificationResult(
        isAcademic: false,
        score: 0,
        text: '',
        reason: 'Classification error: $errorMessage',
      );
    }
  }

  /// Alternative method: Classify using base64 encoding
  /// (Useful if multipart doesn't work in some environments)
  Future<DocumentClassificationResult> classifyDocumentBase64({
    required Uint8List fileBytes,
    String? fileName,
  }) async {
    try {
      final functionUrl = _classificationUrl;
      
      if (kDebugMode) {
        debugPrint('🌐 Base64 classification - URL: $functionUrl');
        debugPrint('🌐 File size: ${fileBytes.length} bytes');
      }
      
      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Add auth token (only for Supabase Edge Functions)
      if (!_usesCustomServer) {
        final session = _supabase.auth.currentSession;
        final authToken = session?.accessToken ?? supabaseAnonKey;
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Encode image to base64
      final base64Image = base64Encode(fileBytes);
      
      if (kDebugMode) {
        debugPrint('🌐 Base64 encoded size: ${base64Image.length} characters');
      }
      
      // Create JSON request body
      final requestBody = json.encode({
        'image': base64Image,
      });
      
      if (kDebugMode) {
        debugPrint('📤 Sending base64 request to: $functionUrl');
      }
      
      // Send POST request with extended timeout (first request loads model, takes 30-60s)
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Request timeout: Server did not respond within 120 seconds. This may happen on the first request while the model is loading. Please try again.');
        },
      );
      
      if (kDebugMode) {
        debugPrint('📥 Base64 response: ${response.statusCode}');
        debugPrint('📄 Response body length: ${response.body.length}');
      }
      
      // Parse response
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
          
          if (kDebugMode) {
            debugPrint('✅ Base64 classification successful: ${jsonResponse['is_academic']}');
          }
          
          return DocumentClassificationResult(
            isAcademic: jsonResponse['is_academic'] as bool? ?? false,
            score: jsonResponse['score'] as int? ?? 0,
            text: jsonResponse['text'] as String? ?? '',
            reason: jsonResponse['reason'] as String? ?? 'No reason provided',
            matchedKeywords: jsonResponse['matched_keywords'] != null
                ? List<String>.from(jsonResponse['matched_keywords'] as List)
                : null,
          );
        } catch (parseError) {
          if (kDebugMode) {
            debugPrint('❌ Base64 JSON parse error: $parseError');
          }
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Invalid response from server. Please check server logs.',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Base64 error response: ${response.statusCode}');
          debugPrint('❌ Response body: ${response.body}');
        }
        
        try {
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorJson['error'] as String? ?? 
                              errorJson['message'] as String? ?? 
                              'Unknown error';
          
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: $errorMessage (HTTP ${response.statusCode})',
          );
        } catch (_) {
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: HTTP ${response.statusCode}',
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Base64 classification exception: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      
      String errorMessage = e.toString();
      
      // Provide more helpful error messages
      if (errorMessage.contains('Failed host lookup') || errorMessage.contains('SocketException')) {
        errorMessage = 'Cannot connect to classification server. Please check your internet connection and ensure the server is running.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Request timed out. The server may be overloaded. Please try again.';
      } else if (errorMessage.contains('CORS')) {
        errorMessage = 'CORS error. Please check server CORS configuration.';
      }
      
      return DocumentClassificationResult(
        isAcademic: false,
        score: 0,
        text: '',
        reason: 'Classification error: $errorMessage',
      );
    }
  }
}

