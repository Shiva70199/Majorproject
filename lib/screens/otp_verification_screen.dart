import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/supa_service.dart';
import '../services/otp_service.dart';
import '../widgets/glass_button.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

/// OTP verification screen for new user signups
/// User enters the 6-digit OTP code sent to their email
class OTPVerificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const OTPVerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();
  final _otpService = OTPService();

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Verify OTP code
      final isValid = await _otpService.verifyOTP(
        email: widget.email,
        otp: _otpController.text.trim(),
      );

      if (!isValid) {
        throw Exception('Invalid OTP code. Please try again.');
      }

      // Check if email still exists (double-check before creating account)
      final emailExists = await _firebaseAuth.isEmailRegistered(widget.email);
      if (emailExists) {
        throw Exception('This email is already registered. Please sign in instead.');
      }

      // OTP verified, now create Firebase account
      final userCredential = await _firebaseAuth.signUp(
        email: widget.email,
        password: widget.password,
      );

      if (userCredential.user != null) {
        // Create profile in Supabase with student role (all users are students)
        try {
          await _supaService.createProfile(
            userId: userCredential.user!.uid,
            name: widget.name,
            email: widget.email,
            role: 'student',
          );
        } catch (profileError) {
          // If profile creation fails, try to delete the Firebase user
          try {
            await userCredential.user!.delete();
          } catch (_) {
            // Ignore deletion errors
          }
          rethrow;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account verified and created successfully!'),
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
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      String errorMessage = 'OTP verification failed';
      bool shouldNavigateToLogin = false;

      if (e.code == 'email-already-in-use') {
        errorMessage =
            'This email is already registered. Please sign in instead.';
        shouldNavigateToLogin = true;
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address. Please check and try again.';
      } else {
        errorMessage = 'Error: ${e.message ?? e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: shouldNavigateToLogin
                ? SnackBarAction(
                    label: 'Sign In',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Resend OTP code
  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      final otpSent = await _otpService.sendOTP(email: widget.email);
      
      if (otpSent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully! Please check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${e.toString()}'),
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
          child: Form(
            key: _formKey,
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
                    Icons.email_outlined,
                    size: 64,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Enter OTP Code',
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
                        Text(
                          'We\'ve sent a 6-digit OTP code to:',
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
                          'Please enter the OTP code from your email to verify your account.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // OTP input field
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    labelText: '6-digit OTP',
                    hintText: '000000',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the OTP from your email';
                    }
                    if (value.trim().length != 6) {
                      return 'OTP should be 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Verify button
                _isVerifying
                    ? const Center(child: CircularProgressIndicator())
                    : GlassButton(
                        label: 'Verify & Complete Sign-Up',
                        icon: Icons.check_circle,
                        onPressed: _handleVerifyOTP,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                const SizedBox(height: 16),

                // Resend OTP button
                _isResending
                    ? const Center(child: CircularProgressIndicator())
                    : TextButton(
                        onPressed: _isVerifying ? null : _resendOTP,
                        child: const Text('Resend OTP Code'),
                      ),
                const SizedBox(height: 16),

                // Back button
                TextButton(
                  onPressed: _isVerifying || _isResending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

