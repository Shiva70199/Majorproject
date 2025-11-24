# SafeDocs - Secure Academic Document Storage

A Flutter-based application for secure academic document management with OCR validation and cloud storage.

## Features

- ✅ **OTP-based Registration** - Secure student signup with email OTP verification
- ✅ **Document Upload** - Upload documents from device or scan with camera
- ✅ **OCR Validation** - Automatic document validation using Google ML Kit
- ✅ **Category Management** - Organize documents by 14 predefined categories
- ✅ **Cloud Storage** - Secure document storage with Supabase
- ✅ **Document Management** - View, download, and manage documents

## Documentation

📖 **Complete Documentation**: See [`PROJECT_DOCUMENTATION.md`](PROJECT_DOCUMENTATION.md) for:
- Architecture overview
- Technology stack
- API reference
- Database schema
- Setup instructions
- Workflows and flows

⚡ **Quick Reference**: See [`QUICK_REFERENCE.md`](QUICK_REFERENCE.md) for:
- Quick start guide
- Common tasks
- Service methods reference
- Configuration checklist

## Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**
   - Create Firebase project
   - Enable Email/Password authentication
   - Run `flutterfire configure`

3. **Configure Supabase**
   - Create Supabase project
   - Run `supabase_setup.sql` in SQL Editor
   - Create storage bucket: `documents`
   - Update Supabase keys in `lib/main.dart`

4. **Configure Email (OTP)**
   - Edit `lib/config/email_config.dart`
   - Set Gmail App Password for SMTP
   - Set `isConfigured = true`

5. **Run the App**
   ```bash
   flutter run -d chrome  # or android, windows
   ```

## Project Structure

```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic
└── widgets/         # Reusable widgets
```

## Technology Stack

- **Flutter** - Cross-platform framework
- **Firebase** - Authentication
- **Supabase** - Database & Storage
- **Google ML Kit** - OCR text recognition
- **SMTP** - Email OTP delivery

## Support

For detailed setup instructions and troubleshooting, see:
- [`PROJECT_DOCUMENTATION.md`](PROJECT_DOCUMENTATION.md) - Complete documentation
- [`QUICK_REFERENCE.md`](QUICK_REFERENCE.md) - Quick reference guide
- [`SIMPLIFIED_SYSTEM_SUMMARY.md`](SIMPLIFIED_SYSTEM_SUMMARY.md) - System overview
