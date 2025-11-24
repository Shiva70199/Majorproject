import 'package:flutter/material.dart';
import '../models/document_category.dart';
import '../services/firebase_auth_service.dart';
import '../services/supa_service.dart';
import 'camera_scan_screen.dart';
import 'document_view_screen.dart';
import 'upload_screen.dart';

/// Category screen showing all documents for a specific category
/// Displays a list of documents with a floating upload button
class CategoryScreen extends StatefulWidget {
  final String categoryId;

  const CategoryScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // Service instances
  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();
  
  // List to store documents
  List<Map<String, dynamic>> _documents = [];
  
  // Loading state
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    // Load documents when screen opens
    _loadDocuments();
  }

  /// Load documents for this category
  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final userId = _firebaseAuth.currentUserId;
      if (userId != null) {
        // Load documents directly from documents table
        final documents = await _supaService.getDocumentsByCategory(
          userId: userId,
          category: widget.categoryId,
        );
        
        setState(() {
          _documents = documents;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle document deletion
  Future<void> _deleteDocument(Map<String, dynamic> document) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete ${document['file_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userId = _firebaseAuth.currentUserId;
        if (userId != null) {
          // Delete document from storage and database
          await _supaService.deleteDocument(
            userId: userId,
            documentId: document['id'].toString(),
            filePath: document['file_path'],
          );
          // Reload documents list
          _loadDocuments();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting document: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text('${_category.label} Documents'),
        backgroundColor: Colors.blue[100], // Light blue app bar
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the action button to scan or upload',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final document = _documents[index];
                      return _buildDocumentCard(document);
                    },
                  ),
                ),
      // Floating action button for scan/upload choices
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptions,
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Document',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Build a document card widget
  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description,
            color: Colors.blue[700],
            size: 28,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document['file_name'] ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            _buildStatusChip(document['status'] as String?),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((document['status_reason'] as String?)?.isNotEmpty ?? false) ...[
              Text(
                'Reason: ${document['status_reason']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 4),
            Text(
              'Size: ${_formatFileSize(document['file_size'] ?? 0)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (document['created_at'] != null)
              Text(
                'Uploaded: ${_formatDate(document['created_at'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'view') {
              // Navigate to document view screen
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DocumentViewScreen(
                    document: document,
                  ),
                ),
              );
              if (result == true) {
                _loadDocuments();
              }
            } else if (value == 'delete') {
              _deleteDocument(document);
            }
          },
        ),
        onTap: () async {
          // Navigate to document view screen on tap
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentViewScreen(
                document: document,
              ),
            ),
          );
          if (result == true) {
            _loadDocuments();
          }
        },
      ),
    );
  }

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format date string
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusChip(String? statusValue) {
    final status = parseDocumentStatus(statusValue);
    Color? bgColor;
    Color? textColor;
    switch (status) {
      case DocumentStatus.pending:
        bgColor = Colors.orange[100];
        textColor = Colors.orange[900];
        break;
      case DocumentStatus.verified:
        bgColor = Colors.green[100];
        textColor = Colors.green[900];
        break;
      case DocumentStatus.rejected:
        bgColor = Colors.red[100];
        textColor = Colors.red[900];
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }


  Future<void> _showUploadOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Scan with Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CameraScanScreen(
                        categoryId: widget.categoryId,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadDocuments();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload from Device'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UploadScreen(
                        categoryId: widget.categoryId,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadDocuments();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

