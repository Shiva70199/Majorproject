/// Email/SMTP configuration for OTP service
/// 
/// IMPORTANT: This file configures the SMTP server used to SEND OTP emails to students.
/// This is NOT the student's email - it's the email account the app uses to send emails.
/// 
/// HOW IT WORKS:
/// - Students enter their own email during signup
/// - OTP is sent to the student's email address they entered
/// - This SMTP configuration is just for the app to send emails (like a mail server)
/// 
/// FOR STUDENTS:
/// - Students enter: name, email (their own), password
/// - OTP is sent to their email address
/// - After entering OTP, account is created in database
/// 
/// FOR HOD:
/// - HOD emails are predefined in lib/config/hod_config.dart (whitelist)
/// - If email is in HOD whitelist, they get HOD role automatically
/// 
/// CONFIGURATION INSTRUCTIONS:
/// 1. Uncomment ONE of the configuration blocks below (Gmail, Outlook, or Custom)
/// 2. Fill in SMTP server credentials (this is for sending emails, not student authentication)
/// 3. Set isConfigured = true (line 45)
/// 
/// For Gmail SMTP:
/// - Use a Gmail account to send OTP emails (can be any Gmail account)
/// - Enable 2-Step Verification in Google Account
/// - Generate App Password: Google Account → Security → 2-Step Verification → App passwords
/// - Use the 16-character app password (NOT your regular Gmail password)
/// 
/// See OTP_EMAIL_CONFIGURATION.md for detailed setup instructions.
class EmailConfig {
  // ============================================
  // STEP 1: UNCOMMENT ONE OF THESE BLOCKS BELOW
  // ============================================
  
  // OPTION 1: Gmail SMTP (Recommended for Development)
  // Uncomment the 4 lines below and fill in your Gmail credentials
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const String smtpEmail = 'payday7019@gmail.com'; // Your Gmail address
  // ⚠️ IMPORTANT: This MUST be a Gmail App Password (16 characters), NOT your regular Gmail password!
  // Get it from: https://myaccount.google.com/apppasswords
  static const String smtpPassword = 'oabumtbwqguwspxi'; // App Password WITHOUT spaces (16 characters)
  
  // OPTION 2: Outlook SMTP
  // Uncomment these 4 lines and fill in your Outlook credentials
  // static const String smtpServer = 'smtp-mail.outlook.com';
  // static const int smtpPort = 587;
  // static const String smtpEmail = 'your-email@outlook.com';
  // static const String smtpPassword = 'your-password';
  
  // OPTION 3: Custom SMTP Server
  // Uncomment these 4 lines and fill in your custom SMTP credentials
  // static const String smtpServer = 'smtp.your-domain.com';
  // static const int smtpPort = 587; // or 465 for SSL
  // static const String smtpEmail = 'your-email@your-domain.com';
  // static const String smtpPassword = 'your-password';
  
  // ============================================
  // STEP 2: SET THIS TO TRUE AFTER FILLING IN YOUR CREDENTIALS
  // ============================================
  static const bool isConfigured = true; // CHANGE TO true AFTER CONFIGURING
  
  // ============================================
  // DO NOT MODIFY BELOW THIS LINE
  // ============================================
  
  /// Get SMTP server configuration
  static Map<String, dynamic>? getSmtpConfig() {
    if (!isConfigured) {
      return null;
    }
    
    return {
      'server': smtpServer,
      'serverPort': smtpPort,
      'email': smtpEmail,
      'password': smtpPassword,
    };
  }
}

