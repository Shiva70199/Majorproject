import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/supa_service.dart';
import '../services/otp_service.dart';
import '../config/hod_config.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class OTPScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String role;

  const OTPScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();
  final _otpService = OTPService();

  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
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

      // Auto-assign role based on email whitelist (HOD emails get HOD role automatically)
      final assignedRole = HodConfig.getRoleForEmail(widget.email);

      // OTP verified, now create Firebase account
      final userCredential = await _firebaseAuth.signUp(
        email: widget.email,
        password: widget.password,
      );

      if (userCredential.user != null) {
        // Create profile in Supabase with auto-assigned role
        try {
          await _supaService.createProfile(
            userId: userCredential.user!.uid,
            name: widget.name,
            email: widget.email,
            role: assignedRole, // Use auto-assigned role from whitelist
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the OTP sent to ${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '6-digit OTP',
                  prefixIcon: Icon(Icons.lock),
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
              _isVerifying
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleVerifyOtp,
                      child: const Text('Verify & Complete Sign-Up'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    _isVerifying ? null : () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
