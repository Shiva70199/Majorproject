import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/supa_service.dart';
import '../widgets/glass_button.dart';
import 'dashboard_screen.dart';

/// Email verification screen for new user signups
/// Waits for user to verify their email via Firebase email verification link
class EmailVerificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String role;

  const EmailVerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();

  bool _isChecking = false;
  bool _isResending = false;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  /// Check if email is verified
  Future<void> _checkEmailVerification() async {
    setState(() => _isChecking = true);

    try {
      // Reload user to get latest verification status
      await _firebaseAuth.reloadUser();

      final user = _firebaseAuth.currentUser;
      if (user != null && user.emailVerified) {
        setState(() => _emailVerified = true);
        await _completeSignup();
      }
    } catch (e) {
      // Ignore errors during check
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  /// Complete signup by creating profile in Supabase
  Future<void> _completeSignup() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      // Create profile in Supabase with auto-assigned role
      await _supaService.createProfile(
        userId: user.uid,
        name: widget.name,
        email: widget.email,
        role: widget.role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Account created successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Resend verification email
  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);

    try {
      await _firebaseAuth.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _emailVerified ? Icons.check_circle : Icons.email_outlined,
                  size: 64,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _emailVerified
                    ? 'Email Verified!'
                    : 'Check Your Email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
              ),
              const SizedBox(height: 16),

              // Message
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      if (!_emailVerified) ...[
                        Text(
                          'We\'ve sent a verification email to:',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.email,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please click the verification link in the email to complete your signup.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          'Your email has been verified!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              if (!_emailVerified) ...[
                // Check verification button
                _isChecking
                    ? const Center(child: CircularProgressIndicator())
                    : GlassButton(
                        label: 'I\'ve Verified My Email',
                        icon: Icons.check_circle,
                        onPressed: _checkEmailVerification,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                const SizedBox(height: 16),

                // Resend email button
                _isResending
                    ? const Center(child: CircularProgressIndicator())
                    : TextButton(
                        onPressed: _resendVerificationEmail,
                        child: const Text('Resend Verification Email'),
                      ),
                const SizedBox(height: 16),

                // Help text
                Text(
                  'Didn\'t receive the email? Check your spam folder or click "Resend" above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ] else ...[
                // Loading indicator while creating profile
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Setting up your account...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

