import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_category.dart';

/// Service class to handle all Supabase operations
/// This handles database and storage only - authentication is handled by Firebase
class SupaService {
  // Get the Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a profile entry in the profiles table
  /// This should be called after successful signup
  /// Uses upsert to handle cases where profile might already exist
  Future<void> createProfile({
    required String userId,
    required String name,
    required String email,
    String role = 'student',
  }) async {
    try {
      // Check if profile already exists
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) {
        // Profile already exists, update it instead
        await _supabase.from('profiles').update({
          'name': name,
          'email': email,
          'role': role,
        }).eq('id', userId);
      } else {
        // Insert a new row in the profiles table
        await _supabase.from('profiles').insert({
          'id': userId, // Use Firebase user's ID as the primary key
          'name': name,
          'email': email,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Re-throw error to be handled by the caller
      rethrow;
    }
  }

  /// Ensure a profile row exists for the given Firebase user ID.
  /// If missing, it will create one using the best available information.
  Future<void> ensureProfileExists({
    required String userId,
    String? email,
    String role = 'student',
  }) async {
    try {
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        final inferredName = (email != null && email.isNotEmpty
            ? email.split('@').first
            : 'User');
        await createProfile(
          userId: userId,
          name: inferredName,
          email: email ?? '',
          role: role,
        );
      }
    } catch (_) {
      // If profile read fails due to RLS or transient errors, do not block login flow.
      // Create attempt below may still succeed if policies allow it.
      try {
        final inferredName = (email != null && email.isNotEmpty
            ? email.split('@').first
            : 'User');
        await createProfile(
          userId: userId,
          name: inferredName,
          email: email ?? '',
          role: role,
        );
      } catch (e) {
        // Give up silently; profile isn't critical for core auth.
      }
    }
  }

  /// Fetch the profile row for a user.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the user's role (defaults to student if missing).
  Future<String> getUserRole(String userId) async {
    final profile = await getProfile(userId);
    final role = profile?['role'] as String?;
    return role ?? 'student';
  }

  /// Fetch all documents for a specific user and category
  /// Returns a list of document records from the database
  Future<List<Map<String, dynamic>>> getDocumentsByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      // Query the documents table filtered by user_id and category
      final response = await _supabase
          .from('documents')
          .select()
          .eq('user_id', userId)
          .eq('category', category)
          .order('created_at', ascending: false); // Most recent first

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Re-throw error to be handled by the caller
      rethrow;
    }
  }

  /// Insert a new document record into the database
  /// This stores metadata about the uploaded file
  Future<Map<String, dynamic>> insertDocument({
    required String userId,
    required String category,
    required String fileName,
    required String filePath, // Path in Supabase Storage
    required int fileSize,
    required String? uploaderEmail,
  }) async {
    try {
      // Insert document metadata directly into the documents table
      // Status is set to 'verified' since there's no HOD verification needed
      final response = await _supabase.from('documents').insert({
        'user_id': userId,
        'category': category,
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'uploader_email': uploaderEmail,
        'status': DocumentStatus.verified.value, // Directly verified, no review needed
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      // Re-throw error to be handled by the caller
      rethrow;
    }
  }

  /// Upload a file to Supabase Storage
  /// Files are stored in: documents/{user_id}/{category}/filename
  /// Returns the file path in storage
  Future<String> uploadFile({
    required String userId,
    required String category,
    required String fileName,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    try {
      // Construct the storage path
      // IMPORTANT: Do NOT include the bucket name here. The path is relative to the bucket.
      // Using the userId as the first folder ensures storage RLS policies like
      // auth.uid()::text = storage.foldername(name)[1] will pass.
      final storagePath = '$userId/$category/$fileName';

      // Upload file to Supabase Storage private bucket
      await _supabase.storage
          .from('documents') // Bucket name
          .uploadBinary(
            storagePath,
            Uint8List.fromList(fileBytes),
            fileOptions: FileOptions(
              contentType: contentType ?? 'application/pdf',
              upsert: false, // Don't overwrite existing files
            ),
          );

      return storagePath;
    } catch (e) {
      // Re-throw error to be handled by the caller
      rethrow;
    }
  }

  /// Generate a signed URL for a file in Supabase Storage
  /// Signed URLs allow temporary access to private files
  /// Returns the signed URL string
  Future<String> getSignedUrl({
    required String filePath,
    int expiresIn = 3600, // Default: 1 hour expiry
  }) async {
    try {
      // Generate a signed URL for the file
      final response = await _supabase.storage
          .from('documents')
          .createSignedUrl(filePath, expiresIn);

      return response;
    } catch (e) {
      // Re-throw error to be handled by the caller
      rethrow;
    }
  }

  /// Delete a document from both storage and database
  Future<void> deleteDocument({
    required String userId,
    required String documentId,
    required String filePath,
  }) async {
    try {
      // Delete from storage first
      await _supabase.storage.from('documents').remove([filePath]);

      // Then delete the database record
      await _supabase
          .from('documents')
          .delete()
          .eq('id', documentId)
          .eq('user_id', userId);
    } catch (e) {
      // Re-throw error to be handled by the caller
      rethrow;
    }
  }

  /// Fetch documents for HOD review (optionally filtered by status).
  Future<List<Map<String, dynamic>>> getDocumentsForReview({
    String? status,
  }) async {
    try {
      var query = _supabase.from('documents').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the status of a document following HOD review.
  Future<void> updateDocumentStatus({
    required String documentId,
    required DocumentStatus status,
    required String hodId,
    String? reason,
  }) async {
    try {
      await _supabase
          .from('documents')
          .update({
            'status': status.value,
            'status_reason': reason,
            'hod_id': hodId,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Notify HODs about a new document upload.
  Future<void> createHodNotification({
    required String documentId,
    required String userId,
    required String category,
    String message = 'New document uploaded for review',
  }) async {
    try {
      await _supabase.from('hod_notifications').insert({
        'document_id': documentId,
        'user_id': userId,
        'category': category,
        'message': message,
        'status': DocumentStatus.pending.value,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Notifications should not block uploads.
    }
  }

  // ============================================
  // PENDING DOCUMENTS METHODS (NEW WORKFLOW)
  // ============================================

  /// Insert a pending document (awaiting HOD verification)
  /// Documents are saved here first, moved to documents table only after verification
  Future<Map<String, dynamic>> insertPendingDocument({
    required String userId,
    required String category,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String? uploaderEmail,
    String? uploaderName,
  }) async {
    try {
      final response = await _supabase.from('pending_documents').insert({
        'user_id': userId,
        'category': category,
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'uploader_email': uploaderEmail,
        'uploader_name': uploaderName,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all pending documents for HOD review
  Future<List<Map<String, dynamic>>> getPendingDocuments({
    String? status,
  }) async {
    try {
      var query = _supabase.from('pending_documents').select();
      if (status != null) {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get pending documents for a specific student
  Future<List<Map<String, dynamic>>> getPendingDocumentsByUser({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('pending_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify a pending document - moves it to documents table and deletes from pending
  Future<void> verifyPendingDocument({
    required String pendingDocumentId,
    required String hodId,
    String? reason,
  }) async {
    try {
      // Get the pending document
      final pendingDoc = await _supabase
          .from('pending_documents')
          .select()
          .eq('id', pendingDocumentId)
          .single();

      // Insert into documents table with verified status
      await _supabase.from('documents').insert({
        'user_id': pendingDoc['user_id'],
        'category': pendingDoc['category'],
        'file_name': pendingDoc['file_name'],
        'file_path': pendingDoc['file_path'],
        'file_size': pendingDoc['file_size'],
        'uploader_email': pendingDoc['uploader_email'],
        'status': DocumentStatus.verified.value,
        'status_reason': reason,
        'hod_id': hodId,
        'verified_at': DateTime.now().toIso8601String(),
        'created_at': pendingDoc['created_at'],
      });

      // Delete from pending_documents
      await _supabase
          .from('pending_documents')
          .delete()
          .eq('id', pendingDocumentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Reject a pending document - deletes it from storage and pending_documents
  Future<void> rejectPendingDocument({
    required String pendingDocumentId,
    String? reason,
  }) async {
    try {
      // Get the pending document to get file path
      final pendingDoc = await _supabase
          .from('pending_documents')
          .select('file_path')
          .eq('id', pendingDocumentId)
          .single();

      // Delete file from storage
      try {
        await _supabase.storage
            .from('documents')
            .remove([pendingDoc['file_path']]);
      } catch (_) {
        // Ignore storage deletion errors
      }

      // Update status to rejected (optional, for audit) then delete
      // Actually, just delete directly as per requirements
      await _supabase
          .from('pending_documents')
          .delete()
          .eq('id', pendingDocumentId);
    } catch (e) {
      rethrow;
    }
  }
}
