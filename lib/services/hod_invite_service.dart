import 'dart:math';
import '../config/hod_config.dart';
import 'firebase_auth_service.dart';

/// Service to handle HOD invitations via password reset links
/// Sends password reset emails to predefined HOD email addresses
class HodInviteService {
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  /// Check if email is in HOD whitelist
  bool isHodEmail(String email) {
    return HodConfig.isAuthorizedHod(email);
  }

  /// Send password reset link to a predefined HOD email
  /// This allows HOD to set their password themselves
  Future<bool> inviteHod(String email) async {
    try {
      // Verify email is in whitelist
      if (!isHodEmail(email)) {
        throw Exception('Email $email is not authorized for HOD role');
      }

      // Check if email is already registered
      final emailExists = await _firebaseAuth.isEmailRegistered(email);

      if (emailExists) {
        // If already registered, send password reset link
        await _firebaseAuth.sendPasswordResetEmail(email: email);
        return true;
      } else {
        // For new HOD accounts, create account with temporary password first
        // Then send password reset link so they can set their own password
        try {
          // Generate a secure temporary password
          final tempPassword = _generateTempPassword();
          
          // Create Firebase account with temporary password
          await _firebaseAuth.signUp(
            email: email,
            password: tempPassword,
          );
          
          // Now send password reset link so HOD can set their own password
          await _firebaseAuth.sendPasswordResetEmail(email: email);
          return true;
        } catch (e) {
          // If account creation fails, try to send reset anyway (in case account was created elsewhere)
          try {
            await _firebaseAuth.sendPasswordResetEmail(email: email);
            return true;
          } catch (_) {
            rethrow;
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send invitation emails to all predefined HOD emails
  Future<Map<String, bool>> inviteAllHods() async {
    final results = <String, bool>{};
    
    for (final email in HodConfig.allowedHodEmails) {
      try {
        final success = await inviteHod(email);
        results[email] = success;
      } catch (e) {
        results[email] = false;
      }
    }
    
    return results;
  }

  /// Generate a secure temporary password for new HOD accounts
  /// This password will be immediately replaced when HOD sets their own password
  String _generateTempPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

