import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_category.dart';
import '../services/firebase_auth_service.dart';
import '../services/ocr_service.dart';
import '../services/document_classifier_service.dart';
import '../services/supa_service.dart';

/// Upload screen for selecting and uploading documents
/// Uses file_picker to select PDF or image files
/// Uploads to Supabase Storage in private bucket
class UploadScreen extends StatefulWidget {
  final String categoryId;

  const UploadScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // Service instances
  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();
  final _ocrService = OCRService(); // Only for file type validation
  final _classifierService = DocumentClassifierService();
  
  // Selected file
  PlatformFile? _selectedFile;
  
  // Loading states
  bool _isUploading = false;
  bool _isScanning = false;

  DocumentCategoryDefinition get _category =>
      DocumentCategories.byId(widget.categoryId) ??
      DocumentCategoryDefinition(
        id: widget.categoryId,
        label: widget.categoryId,
        description: widget.categoryId,
        icon: Icons.description,
        keywords: const [],
        group: DocumentCategories.academicGroup,
      );

  /// Pick a file using file_picker
  Future<void> _pickFile() async {
    try {
      // Open file picker for PDF and image files
      // withData: true ensures bytes are loaded (required for web)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true, // Load file bytes (required for web)
      );

      if (result != null) {
        final file = result.files.single;
        // Since we use withData: true, bytes should always be available
        if (file.bytes != null) {
          setState(() {
            _selectedFile = file;
          });
        } else {
          throw Exception('File data not available. Please try selecting the file again.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload the selected file to Supabase Storage
  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isScanning = true);

    try {
      final userId = _firebaseAuth.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get file bytes
      if (_selectedFile!.bytes == null) {
        throw Exception('File data not available. Please select the file again.');
      }
      final fileBytes = _selectedFile!.bytes!;

      // Validate file type (JPEG/PNG only)
      if (!_ocrService.isValidImageFile(fileBytes, _selectedFile!.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid file type. Please upload only JPG or PNG images.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isScanning = false);
        return;
      }

      // Classify document using Donut-base model
      final classificationResult = await _classifierService.classifyDocument(
        fileBytes: fileBytes,
        fileName: _selectedFile!.name,
      );

      if (!classificationResult.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                classificationResult.reason.isNotEmpty
                    ? classificationResult.reason
                    : 'Only academic documents (marks cards, certificates, ID cards) are allowed.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isScanning = false);
        return;
      }

      setState(() {
        _isScanning = false;
        _isUploading = true;
      });

      // Determine content type
      final extension = _selectedFile!.extension?.toLowerCase() ?? 'pdf';
      final contentType = _getContentType(extension);

      // Upload file to Supabase Storage
      String filePath;
      try {
        filePath = await _supaService.uploadFile(
          userId: userId,
          category: widget.categoryId,
          fileName: _selectedFile!.name,
          fileBytes: fileBytes,
          contentType: contentType,
        );
      } catch (storageError) {
        throw Exception('Storage upload failed: $storageError. Please check storage bucket policies in Supabase Dashboard.');
      }

      // Insert document record directly into documents table (no verification needed)
      try {
        await _supaService.insertDocument(
          userId: userId,
          category: widget.categoryId,
          fileName: _selectedFile!.name,
          filePath: filePath,
          fileSize: fileBytes.length,
          uploaderEmail: _firebaseAuth.currentUserEmail,
        );
      } catch (dbError) {
        // If database insert fails, try to clean up the uploaded file from storage
        try {
          final supabase = Supabase.instance.client;
          await supabase.storage.from('documents').remove([filePath]);
        } catch (_) {
          // Ignore cleanup errors
        }
        throw Exception('Failed to save document: $dbError. Please check database connection.');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isScanning = false;
        });
      }
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text('Upload to ${_category.label}'),
        backgroundColor: Colors.blue[100], // Light blue app bar
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions card
            Card(
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a clear JPG or PNG image to upload',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // File picker button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Selected file info card
            if (_selectedFile != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: Colors.blue[700],
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${_formatFileSize(_selectedFile!.size)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),

            // Upload button
            _isUploading || _isScanning
                ? Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          _isScanning ? 'Classifying document...' : 'Uploading...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _selectedFile == null ? null : _uploadFile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upload File',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

