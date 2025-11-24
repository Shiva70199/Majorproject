import 'package:firebase_auth/firebase_auth.dart';

/// Service class to handle all Firebase Authentication operations
/// This replaces Supabase Auth while keeping Supabase for storage/database
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get the current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Sign up a new user with email and password
  /// Returns the created user
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Send an email verification link
  /// Can be called after signup to send verification email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw Exception('No user is currently signed in');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email with OTP code (for custom OTP flow)
  /// This is a placeholder - actual OTP verification is handled by OTPService
  Future<void> verifyEmailWithOTP({
    required String email,
    required String otp,
  }) async {
    // This method can be used if Firebase Auth OTP is configured
    // For now, we use email_auth package for OTP
    throw UnimplementedError('Use OTPService for OTP verification');
  }

  /// Check if an email is already registered
  /// Returns true if email exists, false otherwise
  /// Note: This method attempts to sign in to check if email exists
  /// Firebase recommends not using email enumeration for security reasons
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Try to get sign-in methods for the email
      // This is a deprecated method but still works for now
      // Consider using a different approach in the future
      // ignore: deprecated_member_use
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      // If email doesn't exist, Firebase may throw an error
      // Return false to indicate email is not registered
      return false;
    }
  }

  /// Send a password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in an existing user with email and password
  /// Returns the user credential
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is currently logged in
  /// Returns true if there's an active session
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Check if the current user's email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Reload the current user (useful after email verification)
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      rethrow;
    }
  }

  /// Update the user's password
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No user is currently signed in');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

