/// Configuration for Head of Department (HOD) access
/// Only emails in this whitelist can have HOD role
class HodConfig {
  /// List of allowed HOD email addresses (case-insensitive)
  /// Add authorized HOD emails here
  static const List<String> allowedHodEmails = [
    // Example HOD emails - replace with actual authorized emails
       'payday7019@gmail.com',
    // 'head.department@university.edu',
    // Add more authorized HOD emails here
  ];

  /// Check if an email is authorized to have HOD role
  static bool isAuthorizedHod(String email) {
    if (email.isEmpty) return false;
    
    final lowerEmail = email.toLowerCase().trim();
    
    // Check if email is in whitelist
    for (final allowedEmail in allowedHodEmails) {
      if (allowedEmail.toLowerCase().trim() == lowerEmail) {
        return true;
      }
    }
    
    return false;
  }

  /// Get the role for a given email
  /// Returns 'hod' if email is in whitelist, 'student' otherwise
  static String getRoleForEmail(String email) {
    return isAuthorizedHod(email) ? 'hod' : 'student';
  }
}

