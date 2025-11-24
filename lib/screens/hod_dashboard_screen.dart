import 'package:flutter/material.dart';

import '../models/document_category.dart';
import '../services/firebase_auth_service.dart';
import '../services/supa_service.dart';
import 'document_view_screen.dart';

class HodDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HodDashboardScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  final _supaService = SupaService();
  final _firebaseAuthService = FirebaseAuthService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      // Load only pending documents awaiting HOD verification
      final docs = await _supaService.getPendingDocuments(
        status: 'pending',
      );
      if (mounted) {
        setState(() {
          _documents = docs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load documents: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('HOD Verification'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review pending documents. Verified documents will be saved; rejected documents will be removed.',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No pending documents to review.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDocuments,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final document = _documents[index];
                            return _buildDocumentCard(document);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final category = DocumentCategories.byId(document['category'] as String?)?.label ??
        (document['category']?.toString() ?? 'Unknown');
    final uploaderEmail = document['uploader_email']?.toString() ?? 'Unknown';
    final uploaderName = document['uploader_name']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          document['file_name'] ?? 'Document',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Category: $category'),
            if (uploaderName != null && uploaderName.isNotEmpty)
              Text('Student: $uploaderName ($uploaderEmail)')
            else
              Text('Uploaded by: $uploaderEmail'),
            Text('Uploaded: ${_formatDate(document['created_at'])}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Pending Review',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () async {
            final reviewerId = _firebaseAuthService.currentUserId;
            if (reviewerId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentViewScreen(
                  document: document,
                  isReviewer: true,
                  reviewerId: reviewerId,
                  onStatusChanged: (newStatus) {
                    // Document will be removed from pending list after verification/rejection
                  },
                ),
              ),
            );
            if (result == true) {
              _loadDocuments();
            }
          },
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

}

