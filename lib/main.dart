import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

// You can find these in your Supabase project settings
const String supabaseUrl = 'https://ksvxoapdwlojujgnhmuy.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzdnhvYXBkd2xvanVqZ25obXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3OTU2NzcsImV4cCI6MjA3ODM3MTY3N30.O_uWL-ALShuLqKdbJn7omi_GeD6hYGAKl05OqyA-PTQ';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase for storage and database only
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeDocs',
      debugShowCheckedModeBanner: false,
      // Light theme with rounded corners
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Card theme with rounded corners
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        // Input decoration theme with rounded corners
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        // Button theme with rounded corners
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      // Define routes for navigation
      routes: {
        '/': (context) => const AuthCheckScreen(), // Start with auth check
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      // Default route
      initialRoute: '/',
    );
  }
}

/// Screen that checks if user is already logged in (auto-login)
/// If logged in, navigates to dashboard; otherwise, shows login screen
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  // Secure storage instance for auto-login
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Check authentication status when screen loads
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  /// This function implements auto-login functionality
  Future<void> _checkAuthStatus() async {
    try {
      // Get Firebase Auth instance
      final auth = FirebaseAuth.instance;
      
      // Check if there's an active Firebase session
      final user = auth.currentUser;
      
      if (user != null) {
        // User is already logged in, navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            ),
          );
        }
        return;
      }

      // No active session, try auto-login with saved credentials
      final savedEmail = await _secureStorage.read(key: 'user_email');
      final savedPassword = await _secureStorage.read(key: 'user_password');

      if (savedEmail != null && savedPassword != null) {
        // Attempt to sign in with saved credentials
        try {
          await auth.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );
          
          // Auto-login successful, navigate to dashboard
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              ),
            );
          }
          return;
        } catch (e) {
          // Auto-login failed, clear saved credentials
          await _secureStorage.delete(key: 'user_email');
          await _secureStorage.delete(key: 'user_password');
        }
      }

      // No saved credentials or auto-login failed, show login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      // Error occurred, show login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    } finally {
      // Auth check completed
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking auth status
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Icon(
              Icons.folder_special,
              size: 80,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'SafeDocs',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Checking authentication...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
