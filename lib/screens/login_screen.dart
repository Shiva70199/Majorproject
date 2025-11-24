import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/firebase_auth_service.dart';
import '../services/supa_service.dart';
import '../widgets/glass_button.dart';
import 'dashboard_screen.dart';
import 'password_reset_screen.dart';
import 'register_screen.dart';

/// Login screen for existing users
/// Authenticates via Firebase Auth
/// Saves credentials using flutter_secure_storage for auto-login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Service instances
  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();
  final _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle user login
  Future<void> _handleSignIn() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in user with Firebase Auth
      final userCredential = await _firebaseAuth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Ensure a profile exists for this user (first successful login)
      if (userCredential.user != null) {
        await _supaService.ensureProfileExists(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email,
        );
      }

      // Save credentials securely for auto-login
      await _secureStorage.write(
        key: 'user_email',
        value: _emailController.text.trim(),
      );
      await _secureStorage.write(
        key: 'user_password',
        value: _passwordController.text.trim(),
      );

      // Navigate to dashboard on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
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
      backgroundColor: Colors.grey[50], // Light background color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title
                Text(
                  'SafeDocs',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure Document Storage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 50),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Forgot password + Login
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        final email = _emailController.text.trim();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PasswordResetScreen(initialEmail: email),
                          ),
                        );
                      },
                      child: const Text('Forgot Password'),
                    ),
                    const Spacer(),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: 140,
                            child: GlassButton(
                              label: 'Login',
                              icon: Icons.login,
                              onPressed: _handleSignIn,
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),

                // Navigate to register
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: GlassButton(
                    label: 'Sign Up',
                    icon: Icons.person_add,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
