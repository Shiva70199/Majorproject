import 'package:flutter/foundation.dart';
import 'package:email_auth/email_auth.dart';
import '../config/email_config.dart';

/// Service class to handle OTP email verification
/// 
/// IMPORTANT: You must configure SMTP settings in lib/config/email_config.dart
/// See OTP_EMAIL_CONFIGURATION.md for setup instructions.
class OTPService {
  late EmailAuth _emailAuth;
  // ignore: prefer_final_fields
  bool _isConfigured = false;

  OTPService() {
    // Initialize EmailAuth
    _emailAuth = EmailAuth(
      sessionName: "SafeDocs Verification",
    );
    
    // Load SMTP configuration from EmailConfig
    if (EmailConfig.isConfigured) {
      final smtpConfig = EmailConfig.getSmtpConfig();
      
      if (smtpConfig != null && 
          smtpConfig['server'] != null && 
          smtpConfig['server'].toString().isNotEmpty &&
          smtpConfig['email'] != null && 
          smtpConfig['email'].toString().isNotEmpty) {
        try {
          // Remove spaces from password (Gmail App Passwords sometimes have spaces for readability)
          final password = (smtpConfig['password'] as String).replaceAll(' ', '');
          
          _emailAuth.config(
            {
              "server": smtpConfig['server'] as String,
              "serverPort": smtpConfig['serverPort'].toString(),
              "email": smtpConfig['email'] as String,
              "password": password, // Use password without spaces
            },
          );
          _isConfigured = true;
        } catch (e) {
          // Configuration failed - service will remain unconfigured
          _isConfigured = false;
          // Log error for debugging (use debugPrint for Flutter apps)
          debugPrint('OTP Service configuration error: $e');
        }
      }
    }
  }

  bool get isConfigured => _isConfigured;

  /// Send OTP to the specified email address
  /// Returns true if OTP was sent successfully
  Future<bool> sendOTP({
    required String email,
  }) async {
      if (!_isConfigured) {
      throw Exception(
        'OTP service is not configured. Please configure SMTP settings in lib/config/email_config.dart:\n'
        '1. Open lib/config/email_config.dart\n'
        '2. Uncomment and fill in your SMTP credentials\n'
        '3. Set isConfigured = true\n'
        'See OTP_EMAIL_CONFIGURATION.md for detailed instructions.',
      );
    }
    
    try {
      final result = await _emailAuth.sendOtp(
        recipientMail: email,
        otpLength: 6,
      );
      return result;
    } catch (e) {
      // Provide more detailed error message
      throw Exception(
        'Failed to send OTP: ${e.toString()}\n\n'
        'Common issues:\n'
        '1. Gmail App Password must have NO spaces (remove spaces from the 16-character password)\n'
        '2. Check that 2-Step Verification is enabled in your Google Account\n'
        '3. Verify the App Password was generated for "Mail"\n'
        '4. Check your internet connection',
      );
    }
  }

  /// Verify the OTP code entered by the user
  /// Returns true if OTP is valid
  Future<bool> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final result = _emailAuth.validateOtp(
        recipientMail: email,
        userOtp: otp,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

