# SafeDocs - Quick Reference Guide

## 🚀 Quick Start

### Run the App
```bash
flutter pub get
flutter run -d chrome  # or android, windows
```

### Configuration Checklist
- [ ] Firebase project created & configured
- [ ] Supabase project created & database set up
- [ ] Email config (`lib/config/email_config.dart`) - SMTP credentials
- [ ] Supabase keys in `lib/main.dart`
- [ ] Storage bucket `documents` created in Supabase
- [ ] Run `supabase_setup.sql` in Supabase SQL Editor
- [ ] Run `migration_add_role_column.sql` if role column missing

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Firebase/Supabase initialization |
| `lib/config/email_config.dart` | SMTP email configuration for OTP |
| `lib/models/document_category.dart` | Document categories & status enums |
| `lib/services/firebase_auth_service.dart` | Authentication |
| `lib/services/otp_service.dart` | OTP email sending/verification |
| `lib/services/ocr_service.dart` | Document validation via OCR |
| `lib/services/supa_service.dart` | Database & storage operations |
| `lib/screens/dashboard_screen.dart` | Main dashboard |
| `lib/screens/login_screen.dart` | User login |
| `lib/screens/register_screen.dart` | User registration |
| `lib/screens/upload_screen.dart` | File upload |
| `lib/screens/camera_scan_screen.dart` | Camera scanning |

---

## 🔑 Service Methods Quick Reference

### FirebaseAuthService
```dart
signUp(email, password)           // Create account
signIn(email, password)           // Login
signOut()                         // Logout
isEmailRegistered(email)          // Check email exists
sendPasswordResetEmail(email)     // Reset password
currentUserId                     // Get user ID
currentUserEmail                  // Get user email
```

### OTPService
```dart
sendOTP(email)                    // Send OTP code
verifyOTP(email, otp)             // Verify OTP
isConfigured                      // Check if SMTP configured
```

### OCRService
```dart
validateDocumentForCategory(...)  // Validate document
isValidImageFile(...)             // Check file format
```

### SupaService
```dart
createProfile(...)                // Create user profile
insertDocument(...)               // Save document
getDocumentsByCategory(...)       // Get documents
uploadFile(...)                   // Upload to storage
getSignedUrl(...)                 // Generate download URL
deleteDocument(...)               // Delete document
```

---

## 📊 Document Categories

| ID | Label | Keywords |
|----|-------|----------|
| `tenth_marksheet` | 10th Marksheet | 10th, SSC, secondary, matriculation |
| `twelfth_marksheet` | 12th Marksheet | 12th, HSC, higher secondary, PUC |
| `ug_certificate` | UG Certificate | degree, bachelor, graduation, certificate |
| `ug_sem_1` to `ug_sem_8` | UG Semester 1-8 | semester, marksheet, grade |
| `college_id_card` | College ID Card | id card, college, student id |
| `sports_certificate` | Sports Certificate | sports, participation, achievement |
| `achievement_certificate` | Achievement Certificate | achievement, award, certificate |

---

## 🔄 User Flows

### Registration
```
Register → Enter Details → OTP Sent → Verify OTP → Account Created → Dashboard
```

### Login
```
Login → Enter Credentials → Authenticated → Dashboard
```

### Upload Document
```
Dashboard → Category → Upload/Scan → OCR Validation → Upload → Saved
```

### View Document
```
Category Screen → Select Document → View Screen → Download/View
```

---

## 🗄️ Database Tables

### profiles
- `id` (TEXT, PK) - Firebase user ID
- `name`, `email`, `role`, `created_at`

### documents
- `id` (UUID, PK)
- `user_id`, `category`, `file_name`, `file_path`
- `file_size`, `uploader_email`, `status`, `created_at`

---

## 🛠️ Tech Stack Summary

| Category | Technology |
|----------|------------|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Supabase (PostgreSQL) |
| Storage | Supabase Storage |
| OCR | Google ML Kit |
| Email | SMTP (Gmail/Outlook) |
| Secure Storage | Flutter Secure Storage |

---

## ⚙️ Configuration Values

### Email Config
```dart
smtpServer: 'smtp.gmail.com'
smtpPort: 587
smtpEmail: 'your-email@gmail.com'
smtpPassword: '16-char-app-password'
isConfigured: true
```

### Supabase
```dart
supabaseUrl: 'https://xxx.supabase.co'
supabaseAnonKey: 'eyJhbGc...'
```

---

## 📝 Common Tasks

### Add New Document Category
1. Edit `lib/models/document_category.dart`
2. Add to `DocumentCategories.all` list
3. Define keywords for OCR matching
4. Update database schema (if needed)

### Change Storage Location
1. Edit `SupaService.uploadFile()`
2. Update storage path format
3. Update RLS policies in Supabase

### Modify OCR Validation
1. Edit `lib/services/ocr_service.dart`
2. Adjust `_checkAcademicContent()` logic
3. Update keyword lists in categories

---

## 🐛 Debug Tips

1. **Check Logs**: Look for error messages in console
2. **Firebase Console**: Check Authentication users
3. **Supabase Dashboard**: Check database tables and storage
4. **Network**: Verify internet connectivity
5. **Config**: Ensure all config files are properly set

---

## 📚 Related Documentation

- `PROJECT_DOCUMENTATION.md` - Complete documentation
- `SIMPLIFIED_SYSTEM_SUMMARY.md` - System overview
- `OTP_EMAIL_CONFIGURATION.md` - Email setup guide
- `SUPABASE_SETUP.md` - Database setup guide

