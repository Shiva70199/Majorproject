import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../models/document_category.dart';
import '../services/supa_service.dart';
import '../widgets/glass_button.dart';

/// Document view screen for viewing and downloading documents
/// Creates a signed URL from Supabase Storage to access the file
class DocumentViewScreen extends StatefulWidget {
  final Map<String, dynamic> document;
  final bool isReviewer;
  final String? reviewerId;
  final void Function(DocumentStatus status)? onStatusChanged;

  const DocumentViewScreen({
    super.key,
    required this.document,
    this.isReviewer = false,
    this.reviewerId,
    this.onStatusChanged,
  });

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  // Service instance
  final _supaService = SupaService();
  
  // Signed URL for the document
  String? _signedUrl;
  
  // Loading states
  bool _isLoadingUrl = true;
  bool _isDownloading = false;

  String get _categoryLabel =>
      DocumentCategories.byId(widget.document['category'] as String?)
          ?.label ??
      (widget.document['category']?.toString() ?? 'Unknown');

  @override
  void initState() {
    super.initState();
    // Generate signed URL when screen opens
    _generateSignedUrl();
  }

  /// Generate a signed URL for the document
  Future<void> _generateSignedUrl() async {
    setState(() => _isLoadingUrl = true);

    try {
      final filePath = widget.document['file_path'] as String;
      
      // Get signed URL from Supabase Storage (valid for 1 hour)
      final url = await _supaService.getSignedUrl(
        filePath: filePath,
        expiresIn: 3600,
      );
      
      setState(() {
        _signedUrl = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUrl = false);
      }
    }
  }

  /// Download the document to device storage
  Future<void> _downloadDocument() async {
    if (_signedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // On web: open the signed URL in a new tab to trigger browser download
      if (kIsWeb) {
        final uri = Uri.parse(_signedUrl!);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) {
          throw Exception('Could not open download URL');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening document...'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Download file from signed URL
      final response = await http.get(Uri.parse(_signedUrl!));
      
      if (response.statusCode == 200) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final fileName = widget.document['file_name'] as String;
        final filePath = '${directory.path}/$fileName';
        
        // Save file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Open the file
        await OpenFile.open(filePath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document downloaded and opened'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _openInBrowser() async {
    if (_signedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri.parse(_signedUrl!);
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open document link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Document Details'),
        backgroundColor: Colors.blue[100], // Light blue app bar
        elevation: 0,
      ),
      body: _isLoadingUrl
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Document info card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Document icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.description,
                              size: 64,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // File name
                          Text(
                            widget.document['file_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Document details
                          _buildInfoRow(
                            'Category',
                            _categoryLabel,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Size',
                            _formatFileSize(widget.document['file_size'] ?? 0),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Uploaded',
                            _formatDate(widget.document['created_at']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  if (_signedUrl != null) ...[
                    // View button
                    GlassButton(
                      label: 'View Document',
                      icon: Icons.visibility,
                      onPressed: _openInBrowser,
                    ),
                    const SizedBox(height: 12),
                    
                    // Download button
                    _isDownloading
                        ? const Center(child: CircularProgressIndicator())
                        : GlassButton(
                            label: 'Download',
                            icon: Icons.download,
                            onPressed: _downloadDocument,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                  ] else
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Unable to load document URL',
                                style: TextStyle(color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// Build an info row widget
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

}

