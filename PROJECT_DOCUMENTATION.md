# SafeDocs - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Models](#models)
6. [Services](#services)
7. [Screens & UI Components](#screens--ui-components)
8. [Authentication Flow](#authentication-flow)
9. [Document Upload & Processing Flow](#document-upload--processing-flow)
10. [Database Schema](#database-schema)
11. [Configuration](#configuration)
12. [Setup Instructions](#setup-instructions)
13. [API Reference](#api-reference)
14. [Workflows](#workflows)

---

## Project Overview

**SafeDocs** is a Flutter-based mobile/web application for secure academic document storage and management. It enables students to upload, scan, store, and manage their academic documents (marksheets, certificates, ID cards) with OCR-based validation and category verification.

### Key Features
- ✅ **OTP-based Student Registration** - Secure signup with email OTP verification
- ✅ **Email/Password Authentication** - Firebase Authentication integration
- ✅ **Document Scanning** - Camera-based document capture with edge detection
- ✅ **OCR Validation** - Google ML Kit text recognition for document validation
- ✅ **Category-based Organization** - 14 predefined document categories
- ✅ **Secure Cloud Storage** - Supabase Storage for document files
- ✅ **Document Management** - View, download, and delete documents
- ✅ **Auto-login** - Secure credential storage for seamless access

---

## Architecture

### Architecture Pattern
SafeDocs follows a **Service-Oriented Architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Screens, Widgets) - UI Components                     │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  - FirebaseAuthService  - Authentication                │
│  - OTPService          - Email OTP                      │
│  - OCRService          - Document Validation            │
│  - SupaService         - Database & Storage             │
│  - EdgeDetectionService - Document Edge Detection       │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  External Services                       │
│  - Firebase Authentication                              │
│  - Supabase (Database + Storage)                        │
│  - SMTP Server (Email)                                  │
│  - Google ML Kit (OCR)                                  │
└─────────────────────────────────────────────────────────┘
```

### Design Principles
- **Separation of Concerns**: Business logic in services, UI in screens
- **Single Responsibility**: Each service handles one domain
- **Dependency Injection**: Services are instantiated where needed
- **Stateless Services**: Services don't maintain application state
- **Error Handling**: Comprehensive error handling at service boundaries

---

## Technology Stack

### Frontend Framework
- **Flutter** (`^3.2.0`) - Cross-platform UI framework
- **Dart** - Programming language

### Authentication
- **Firebase Authentication** (`firebase_core: ^3.6.0`, `firebase_auth: ^5.3.1`)
  - Email/Password authentication
  - Email verification
  - Password reset functionality

### Backend Services
- **Supabase** (`supabase_flutter: ^2.5.6`)
  - PostgreSQL database (via Supabase)
  - Object storage for documents
  - Row Level Security (RLS) policies

### OCR & Image Processing
- **Google ML Kit Text Recognition** (`google_mlkit_text_recognition: ^0.13.0`)
  - OCR for document text extraction
- **Image Processing** (`image: ^4.1.7`)
  - Image manipulation and processing
  - Grayscale conversion, edge detection

### Email Services
- **Email Auth** (`email_auth: ^2.0.0`)
  - SMTP-based OTP email sending
  - OTP verification

### File & Document Handling
- **File Picker** (`file_picker: ^8.0.5`) - File selection from device
- **Camera** (`camera: ^0.11.0+2`) - Camera access for scanning
- **Image Picker** (`image_picker: ^1.1.2`) - Image selection from gallery
- **Open File** (`open_file: ^3.3.2`) - Open files on device
- **Path Provider** (`path_provider: ^2.1.3`) - File system paths
- **HTTP** (`http: ^1.2.1`) - HTTP requests for file downloads

### Security
- **Flutter Secure Storage** (`flutter_secure_storage: ^9.0.0`)
  - Encrypted local storage for credentials
  - Auto-login functionality

### Utilities
- **URL Launcher** (`url_launcher: ^6.3.0`) - Open URLs/browser
- **Share Plus** (`share_plus: ^12.0.1`) - Share documents
- **Intl** (`intl: ^0.19.0`) - Internationalization support

---

## Project Structure

```
lib/
├── config/                          # Configuration files
│   ├── email_config.dart           # SMTP email configuration
│   └── hod_config.dart             # HOD email whitelist (legacy)
│
├── models/                          # Data models
│   └── document_category.dart      # Document category definitions & enums
│
├── screens/                         # UI screens
│   ├── dashboard_screen.dart       # Main dashboard (category grid)
│   ├── login_screen.dart           # User login
│   ├── register_screen.dart        # User registration
│   ├── otp_verification_screen.dart # OTP code verification
│   ├── category_screen.dart        # Documents by category
│   ├── upload_screen.dart          # File upload from device
│   ├── camera_scan_screen.dart     # Camera-based document scanning
│   ├── document_view_screen.dart   # Document preview & download
│   ├── ug_marks_screen.dart        # UG semester marksheets
│   └── password_reset_screen.dart  # Password reset flow
│
├── services/                        # Business logic services
│   ├── firebase_auth_service.dart  # Firebase authentication
│   ├── otp_service.dart            # OTP email sending/verification
│   ├── ocr_service.dart            # OCR & document validation
│   ├── supa_service.dart           # Supabase database & storage
│   └── edge_detection_service.dart # Document edge detection
│
├── widgets/                         # Reusable UI widgets
│   └── glass_button.dart           # Glassmorphism button widget
│
├── main.dart                        # App entry point
└── firebase_options.dart            # Firebase configuration
```

---

## Models

### DocumentCategoryDefinition
**Location**: `lib/models/document_category.dart`

Represents a document category with metadata.

```dart
class DocumentCategoryDefinition {
  final String id;              // Unique identifier (e.g., 'tenth_marksheet')
  final String label;           // Display name (e.g., '10th Marksheet')
  final String description;     // Category description
  final IconData icon;          // UI icon
  final List<String> keywords;  // OCR keywords for validation
  final String group;           // Category group (Academic/Certificates)
}
```

### DocumentStatus Enum
**Location**: `lib/models/document_category.dart`

Represents document verification status.

```dart
enum DocumentStatus {
  pending,    // Awaiting verification (not used in current simplified flow)
  verified,   // Verified and saved
  rejected    // Rejected (not used in current simplified flow)
}
```

### Document Categories (14 Total)
1. **10th Marksheet** (`tenth_marksheet`)
2. **12th Marksheet** (`twelfth_marksheet`)
3. **UG Certificate** (`ug_certificate`)
4. **UG Sem 1-8 Marksheets** (`ug_sem_1` through `ug_sem_8`)
5. **College ID Card** (`college_id_card`)
6. **Sports Certificate** (`sports_certificate`)
7. **Achievement Certificate** (`achievement_certificate`)

---

## Services

### 1. FirebaseAuthService
**Location**: `lib/services/firebase_auth_service.dart`

Handles all Firebase Authentication operations.

**Key Methods:**
- `signUp(email, password)` - Create new user account
- `signIn(email, password)` - Authenticate existing user
- `signOut()` - Sign out current user
- `sendEmailVerification()` - Send email verification link
- `sendPasswordResetEmail(email)` - Send password reset email
- `isEmailRegistered(email)` - Check if email is already registered
- `isLoggedIn()` - Check authentication status
- `currentUser` - Get current authenticated user
- `currentUserId` - Get current user ID
- `currentUserEmail` - Get current user email

### 2. OTPService
**Location**: `lib/services/otp_service.dart`

Handles OTP generation and verification via email.

**Key Methods:**
- `sendOTP(email)` - Send 6-digit OTP to email
- `verifyOTP(email, otp)` - Verify OTP code
- `isConfigured` - Check if SMTP is configured

**Configuration:**
- Uses `EmailConfig` for SMTP settings
- Requires Gmail App Password or custom SMTP

### 3. OCRService
**Location**: `lib/services/ocr_service.dart`

Handles document validation using OCR and image analysis.

**Key Methods:**
- `validateDocumentForCategory(fileBytes, fileName, categoryId)` - Main validation method
- `isValidImageFile(fileBytes, fileName)` - Validate file format (JPEG/PNG only)
- `_extractTextFromImage(fileBytes)` - Extract text using Google ML Kit
- `_analyzeImageCharacteristics(fileBytes)` - Analyze image for personal photos
- `_checkAcademicContent(text, categoryId)` - Validate academic document content
- `_checkNonAcademicContent(text)` - Detect non-academic content

**Validation Logic:**
1. **File Type Validation**: Only JPEG/PNG images accepted
2. **OCR Text Extraction**: Extract text using Google ML Kit
3. **Academic Content Check**: Verify document contains academic terms
4. **Category Matching**: Ensure extracted keywords match selected category
5. **Non-academic Detection**: Reject personal photos and non-documents

**Accepted Document Types:**
- 10th & 12th Marksheets
- UG Certificates & Marksheets (Sem 1-8)
- College ID Cards
- Sports Certificates
- Achievement Certificates

**Rejected Content:**
- Personal photos
- Random images
- Non-academic documents

### 4. SupaService
**Location**: `lib/services/supa_service.dart`

Handles all Supabase database and storage operations.

**Key Methods:**

**Profile Management:**
- `createProfile(userId, name, email, role)` - Create user profile
- `getProfile(userId)` - Get user profile
- `getUserRole(userId)` - Get user's role
- `ensureProfileExists(userId, email, role)` - Ensure profile exists

**Document Management:**
- `insertDocument(userId, category, fileName, filePath, fileSize, uploaderEmail)` - Save document metadata
- `getDocumentsByCategory(userId, category)` - Get documents for category
- `deleteDocument(userId, documentId, filePath)` - Delete document
- `getSignedUrl(filePath, expiresIn)` - Generate temporary download URL

**Storage Operations:**
- `uploadFile(userId, category, fileName, fileBytes, contentType)` - Upload file to Supabase Storage
- Files stored at: `{userId}/{category}/{fileName}`

**Pending Documents (Legacy - Not Used):**
- `insertPendingDocument()` - Legacy method
- `getPendingDocuments()` - Legacy method
- `verifyPendingDocument()` - Legacy method
- `rejectPendingDocument()` - Legacy method

### 5. EdgeDetectionService
**Location**: `lib/services/edge_detection_service.dart`

Detects document edges in camera-captured images.

**Key Methods:**
- `detectDocumentEdges(imageBytes)` - Detect document corners
- Returns 4 corner points as `List<Offset>?`

**Algorithm:**
1. **Image Preprocessing**: Resize, grayscale, Gaussian blur
2. **Canny Edge Detection**: Detect edges using Sobel operator
3. **Contour Finding**: Find connected edge contours
4. **Rectangle Detection**: Find largest rectangular contour
5. **Corner Ordering**: Order corners (top-left, top-right, bottom-right, bottom-left)

---

## Screens & UI Components

### 1. AuthCheckScreen
**Location**: `lib/main.dart`

Initial screen that checks authentication status.

**Functionality:**
- Checks Firebase Auth session
- Attempts auto-login with stored credentials
- Routes to Dashboard (if logged in) or Login (if not)

### 2. LoginScreen
**Location**: `lib/screens/login_screen.dart`

User login interface.

**Features:**
- Email and password input
- "Forgot Password" link
- "Sign Up" navigation
- Secure credential storage for auto-login

### 3. RegisterScreen
**Location**: `lib/screens/register_screen.dart`

New user registration.

**Features:**
- Name, email, password inputs
- Email existence check
- OTP service validation
- Navigates to OTP verification screen

### 4. OTPVerificationScreen
**Location**: `lib/screens/otp_verification_screen.dart`

OTP code verification interface.

**Features:**
- 6-digit OTP input field
- OTP verification
- Firebase account creation
- Supabase profile creation
- Resend OTP option

### 5. DashboardScreen
**Location**: `lib/screens/dashboard_screen.dart`

Main application dashboard.

**Features:**
- Welcome card with user email
- Category grid layout
- Navigation to category screens
- Logout functionality

**Category Groups:**
- Academic Documents (10th, 12th, UG Certificate)
- Certificates & ID (College ID, Sports, Achievement)
- UG Marksheets (Semester management)

### 6. CategoryScreen
**Location**: `lib/screens/category_screen.dart`

Displays documents for a specific category.

**Features:**
- Document list with status chips
- Document cards with metadata
- View/Delete actions
- Upload/Scan floating action button
- Empty state handling

### 7. UploadScreen
**Location**: `lib/screens/upload_screen.dart`

File upload from device.

**Features:**
- File picker integration
- File preview
- OCR validation before upload
- Upload progress indicator
- Error handling

### 8. CameraScanScreen
**Location**: `lib/screens/camera_scan_screen.dart`

Camera-based document scanning.

**Features:**
- Camera preview
- Edge detection and corner overlay
- Manual corner adjustment
- Document cropping
- OCR validation
- Image capture and upload

### 9. DocumentViewScreen
**Location**: `lib/screens/document_view_screen.dart`

Document preview and download.

**Features:**
- Document metadata display
- Signed URL generation
- View in browser
- Download to device
- Document information card

### 10. UGMarksScreen
**Location**: `lib/screens/ug_marks_screen.dart`

UG semester marksheets management.

**Features:**
- Grid layout for 8 semesters
- Individual semester document upload
- Semester-wise document listing

### Custom Widgets

#### GlassButton
**Location**: `lib/widgets/glass_button.dart`

Glassmorphism-styled button widget.

**Usage:**
```dart
GlassButton(
  label: 'Sign Up',
  icon: Icons.person_add,
  onPressed: () => {},
  padding: EdgeInsets.all(16),
)
```

---

## Authentication Flow

### Student Registration Flow

```
1. User opens app
   ↓
2. Navigates to Register Screen
   ↓
3. Enters: Name, Email, Password
   ↓
4. System checks if email exists (Firebase)
   ↓
5. OTP sent to email (via SMTP)
   ↓
6. User enters 6-digit OTP code
   ↓
7. System verifies OTP
   ↓
8. Firebase account created
   ↓
9. Supabase profile created (role: 'student')
   ↓
10. User auto-logged in → Dashboard
```

### Student Login Flow

```
1. User opens app
   ↓
2. AuthCheckScreen checks authentication
   ↓
3a. If logged in → Dashboard
   ↓
3b. If not logged in:
   - Check secure storage for saved credentials
   - Attempt auto-login
   - If successful → Dashboard
   - If failed → Login Screen
   ↓
4. User enters email & password
   ↓
5. Firebase authenticates
   ↓
6. Credentials saved to secure storage
   ↓
7. Navigate to Dashboard
```

---

## Document Upload & Processing Flow

### Upload from Device Flow

```
1. User selects category
   ↓
2. Clicks "Upload from Device"
   ↓
3. File picker opens (PDF/Image)
   ↓
4. User selects file
   ↓
5. System validates file format
   ↓
6. OCR Service validates document:
   - Extract text using ML Kit
   - Check academic content
   - Match category keywords
   - Reject non-academic content
   ↓
7. If valid:
   - Upload file to Supabase Storage
   - Save metadata to documents table
   - Status: 'verified'
   - Show success message
   ↓
8. If invalid:
   - Show rejection reason
   - File not uploaded
```

### Camera Scan Flow

```
1. User selects category
   ↓
2. Clicks "Scan with Camera"
   ↓
3. Camera preview opens
   ↓
4. Edge Detection Service detects document edges
   ↓
5. User adjusts corners if needed
   ↓
6. User captures image
   ↓
7. Image cropped to document boundaries
   ↓
8. OCR Service validates document:
   - Extract text using ML Kit
   - Check academic content
   - Match category keywords
   - Reject non-academic photos
   ↓
9. If valid:
   - Upload to Supabase Storage
   - Save metadata to documents table
   - Status: 'verified'
   - Show success message
   ↓
10. If invalid:
   - Show rejection reason
   - Image not uploaded
```

### OCR Validation Process

**Step 1: Text Extraction**
- Google ML Kit extracts text from image
- If OCR fails (empty text) → Document rejected

**Step 2: Academic Content Check**
- Searches for academic terms (marksheet, certificate, university, etc.)
- Requires minimum 2 academic terms + numbers/dates
- Rejects personal photos and random images

**Step 3: Category Matching**
- Checks extracted text against category keywords
- Must match selected category keywords
- Example: "10th" or "SSC" for 10th marksheet

**Step 4: Non-academic Detection**
- Detects personal photo indicators
- Rejects non-document content
- Ensures only academic documents accepted

---

## Database Schema

### Profiles Table

Stores user profile information.

```sql
CREATE TABLE profiles (
  id TEXT PRIMARY KEY,              -- Firebase user ID
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Indexes:**
- Primary key on `id`

**RLS Policies:**
- Users can view own profile
- Users can update own profile
- Users can insert own profile

### Documents Table

Stores document metadata.

```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,            -- Firebase user ID
  category TEXT NOT NULL,           -- Document category ID
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,          -- Storage path
  file_size INTEGER NOT NULL,
  uploader_email TEXT,
  status TEXT NOT NULL DEFAULT 'verified',
  status_reason TEXT,
  hod_id TEXT,                      -- Legacy field
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Indexes:**
- Index on `user_id`
- Index on `category`
- Index on `status`

**RLS Policies:**
- Users can view own documents
- Users can insert own documents
- Users can delete own documents

**Storage Structure:**
```
documents/
  └── {user_id}/
      └── {category}/
          └── {file_name}
```

### Pending Documents Table (Legacy - Not Used)

Was used for HOD verification workflow (currently not used in simplified system).

---

## Configuration

### Email Configuration
**Location**: `lib/config/email_config.dart`

SMTP settings for OTP email sending.

```dart
class EmailConfig {
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const String smtpEmail = 'your-email@gmail.com';
  static const String smtpPassword = 'your-app-password';
  static const bool isConfigured = true;
}
```

**Setup:**
1. Use Gmail App Password (16 characters, no spaces)
2. Enable 2-Step Verification in Google Account
3. Generate App Password from: https://myaccount.google.com/apppasswords

### Firebase Configuration
**Location**: `lib/firebase_options.dart`

Auto-generated Firebase configuration for multiple platforms.

**Contains:**
- API keys
- Project IDs
- Storage buckets
- Auth domains

### Supabase Configuration
**Location**: `lib/main.dart`

```dart
const String supabaseUrl = 'https://ksvxoapdwlojujgnhmuy.supabase.co';
const String supabaseAnonKey = 'eyJhbGc...';
```

**Setup:**
1. Create Supabase project
2. Get URL and anon key from Project Settings → API
3. Update values in `main.dart`

---

## Setup Instructions

### Prerequisites
1. Flutter SDK (>=3.2.0)
2. Firebase project
3. Supabase project
4. Gmail account (for OTP emails)

### Step 1: Clone & Install Dependencies

```bash
cd safedocs
flutter pub get
```

### Step 2: Configure Firebase

1. Create Firebase project at https://console.firebase.google.com
2. Enable Email/Password authentication
3. Run FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
4. `firebase_options.dart` will be auto-generated

### Step 3: Configure Supabase

1. Create Supabase project at https://app.supabase.com
2. Run SQL script: `supabase_setup.sql`
3. Create storage bucket: `documents` (private)
4. Set storage policies (see `SUPABASE_SETUP.md`)
5. Update Supabase URL and key in `lib/main.dart`

### Step 4: Configure Email (OTP)

1. Open `lib/config/email_config.dart`
2. Set Gmail credentials:
   - Enable 2-Step Verification
   - Generate App Password
   - Set `smtpEmail` and `smtpPassword`
   - Set `isConfigured = true`

### Step 5: Run Database Migrations

1. Run `migration_add_role_column.sql` (if role column missing)
2. Verify tables exist: `profiles`, `documents`

### Step 6: Run the App

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# Windows
flutter run -d windows
```

---

## API Reference

### FirebaseAuthService API

```dart
// Sign up
Future<UserCredential> signUp({
  required String email,
  required String password,
});

// Sign in
Future<UserCredential> signIn({
  required String email,
  required String password,
});

// Sign out
Future<void> signOut();

// Check email registration
Future<bool> isEmailRegistered(String email);

// Send password reset
Future<void> sendPasswordResetEmail({required String email});

// Get current user
User? get currentUser;
String? get currentUserId;
String? get currentUserEmail;
```

### OTPService API

```dart
// Send OTP
Future<bool> sendOTP({required String email});

// Verify OTP
Future<bool> verifyOTP({
  required String email,
  required String otp,
});

// Check configuration
bool get isConfigured;
```

### OCRService API

```dart
// Validate document
Future<DocumentValidationResult> validateDocumentForCategory({
  required Uint8List fileBytes,
  required String? fileName,
  required String categoryId,
});

// Check file format
bool isValidImageFile(Uint8List fileBytes, String? fileName);
```

### SupaService API

```dart
// Profile operations
Future<void> createProfile({
  required String userId,
  required String name,
  required String email,
  String role = 'student',
});
Future<Map<String, dynamic>?> getProfile(String userId);
Future<String> getUserRole(String userId);

// Document operations
Future<Map<String, dynamic>> insertDocument({
  required String userId,
  required String category,
  required String fileName,
  required String filePath,
  required int fileSize,
  required String? uploaderEmail,
});
Future<List<Map<String, dynamic>>> getDocumentsByCategory({
  required String userId,
  required String category,
});
Future<void> deleteDocument({
  required String userId,
  required String documentId,
  required String filePath,
});

// Storage operations
Future<String> uploadFile({
  required String userId,
  required String category,
  required String fileName,
  required List<int> fileBytes,
  String? contentType,
});
Future<String> getSignedUrl({
  required String filePath,
  int expiresIn = 3600,
});
```

---

## Workflows

### Complete User Journey

```
1. App Launch
   └─> AuthCheckScreen
       ├─> Logged in? → Dashboard
       └─> Not logged in → Login Screen

2. Registration
   └─> Register Screen
       ├─> Enter details
       ├─> OTP sent to email
       └─> OTP Verification Screen
           ├─> Enter OTP
           └─> Account created → Dashboard

3. Login
   └─> Login Screen
       ├─> Enter credentials
       └─> Authenticated → Dashboard

4. Document Upload
   └─> Dashboard
       ├─> Select category
       └─> Category Screen
           ├─> Upload from Device OR
           └─> Scan with Camera
               ├─> File/Image selected
               ├─> OCR validation
               ├─> Upload to storage
               └─> Saved to database

5. Document Management
   └─> Category Screen
       ├─> View documents
       ├─> View document details
       ├─> Download document
       └─> Delete document
```

### Data Flow

```
User Input
   ↓
UI Screen
   ↓
Service Layer
   ↓
External API (Firebase/Supabase)
   ↓
Response
   ↓
Service Layer
   ↓
UI Update
```

---

## Security Considerations

### Authentication
- ✅ Firebase Authentication (secure, Google-managed)
- ✅ Email OTP verification for signup
- ✅ Secure credential storage (Flutter Secure Storage)
- ✅ Password requirements enforced

### Data Protection
- ✅ Supabase Row Level Security (RLS) policies
- ✅ Private storage bucket
- ✅ Signed URLs for temporary access (1-hour expiry)
- ✅ User-specific file paths (`{userId}/{category}/{fileName}`)

### Input Validation
- ✅ OCR-based document validation
- ✅ File type validation (JPEG/PNG only)
- ✅ Academic content verification
- ✅ Category keyword matching

---

## Error Handling

### Authentication Errors
- Email already registered
- Invalid credentials
- OTP verification failed
- Network errors

### Document Errors
- Invalid file format
- OCR failure
- Non-academic document rejected
- Category mismatch
- Storage upload failure
- Database insert failure

### Error Display
- SnackBar notifications (success/error)
- User-friendly error messages
- Loading indicators during operations
- Retry mechanisms where appropriate

---

## Future Enhancements (Not Implemented)

- 🔲 PDF support for document upload
- 🔲 Batch document upload
- 🔲 Document sharing between users
- 🔲 Cloud sync across devices
- 🔲 Document search functionality
- 🔲 Advanced OCR with document structure recognition
- 🔲 Document expiry/reminder notifications
- 🔲 Export documents as PDF
- 🔲 Document templates

---

## Troubleshooting

### Common Issues

**1. OTP Not Received**
- Check spam folder
- Verify SMTP configuration
- Ensure Gmail App Password is correct (no spaces)

**2. Document Upload Fails**
- Check Supabase storage bucket exists
- Verify storage policies are set
- Check file size limits
- Ensure file format is JPEG/PNG

**3. OCR Validation Fails**
- Ensure document is clear and well-lit
- Check document contains readable text
- Verify document matches selected category
- Ensure document is academic (marksheet/certificate)

**4. Authentication Errors**
- Verify Firebase project configuration
- Check Firebase Authentication is enabled
- Ensure email format is valid
- Check network connectivity

---

## Version History

- **v1.0.0** - Initial release
  - Student registration with OTP
  - Document upload (scan & device)
  - OCR validation
  - Secure storage
  - Document management

---

## License

This project is private and proprietary.

---

## Support

For issues and questions:
1. Check documentation files in project root
2. Review error messages in app
3. Check Firebase/Supabase console logs
4. Verify configuration files are correct

---

**Last Updated**: December 2024
**Project**: SafeDocs - Secure Academic Document Storage
**Platform**: Flutter (Web, Android, Windows)

