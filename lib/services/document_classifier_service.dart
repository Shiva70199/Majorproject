import 'dart:typed_data';
import 'dart:convert';
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
      
      // Debug: Print the URL being used
      print('🔍 Classification URL: $functionUrl');
      print('🔍 Railway URL: https://majorproject-production-a70b.up.railway.app');
      print('🔍 Using custom server: $_usesCustomServer');
      
      // Verify we're using Railway, not Supabase
      if (functionUrl.contains('supabase.co')) {
        throw Exception('ERROR: Still using Supabase URL! Expected Railway URL. Please restart the app completely.');
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
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Parse response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        
        return DocumentClassificationResult(
          isAcademic: jsonResponse['is_academic'] as bool? ?? false,
          score: jsonResponse['score'] as int? ?? 0,
          text: jsonResponse['text'] as String? ?? '',
          reason: jsonResponse['reason'] as String? ?? 'No reason provided',
          matchedKeywords: jsonResponse['matched_keywords'] != null
              ? List<String>.from(jsonResponse['matched_keywords'] as List)
              : null,
        );
      } else {
        // Handle error response
        try {
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorJson['error'] as String? ?? 
                              errorJson['message'] as String? ?? 
                              'Unknown error';
          
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: $errorMessage',
          );
        } catch (_) {
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: HTTP ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      // Handle network or other errors
      return DocumentClassificationResult(
        isAcademic: false,
        score: 0,
        text: '',
        reason: 'Classification error: ${e.toString()}',
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
      
      // Create JSON request body
      final requestBody = json.encode({
        'image': base64Image,
      });
      
      // Send POST request
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: headers,
        body: requestBody,
      );
      
      // Parse response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        
        return DocumentClassificationResult(
          isAcademic: jsonResponse['is_academic'] as bool? ?? false,
          score: jsonResponse['score'] as int? ?? 0,
          text: jsonResponse['text'] as String? ?? '',
          reason: jsonResponse['reason'] as String? ?? 'No reason provided',
          matchedKeywords: jsonResponse['matched_keywords'] != null
              ? List<String>.from(jsonResponse['matched_keywords'] as List)
              : null,
        );
      } else {
        try {
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorJson['error'] as String? ?? 
                              errorJson['message'] as String? ?? 
                              'Unknown error';
          
          return DocumentClassificationResult(
            isAcademic: false,
            score: 0,
            text: '',
            reason: 'Classification failed: $errorMessage',
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
    } catch (e) {
      return DocumentClassificationResult(
        isAcademic: false,
        score: 0,
        text: '',
        reason: 'Classification error: ${e.toString()}',
      );
    }
  }
}

