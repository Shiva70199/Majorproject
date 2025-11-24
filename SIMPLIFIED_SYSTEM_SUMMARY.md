# Simplified System - Student Only

## Overview
The system has been simplified to **student-only** functionality. All HOD verification features have been removed.

## What Remains

### ✅ Student Signup with OTP
- Student enters: name, email, password
- OTP code sent to student's email
- Student enters OTP code
- Account created with 'student' role
- Uses Firebase Authentication

### ✅ Student Login
- Students login with email and password
- No OTP required for login (only for signup)
- Auto-login feature works

### ✅ Document Upload
**Two Methods:**
1. **Scan with Camera** - Uses OCR to validate document
2. **Upload from Device** - Direct file upload

**What Happens:**
- Document is validated using OCR (checks if it matches selected category)
- Document is saved directly to `documents` table with 'verified' status
- No HOD review needed - documents are saved immediately
- Students can view and download their documents right away

### ✅ Document Management
- Students can view all their uploaded documents
- Students can download documents
- Students can delete documents

## What Was Removed

### ❌ HOD Verification System
- HOD dashboard removed
- HOD invite screen removed
- Document verification workflow removed
- Pending documents table usage removed (still exists in DB but not used)

### ❌ HOD Role
- No HOD role checking
- All users are students
- No role-based dashboards

## File Changes Summary

### Modified Files:
- `lib/screens/dashboard_screen.dart` - Removed HOD role checking, always shows student dashboard
- `lib/screens/register_screen.dart` - Removed HOD config, all users are students
- `lib/screens/otp_verification_screen.dart` - Removed role parameter, all users get 'student' role
- `lib/screens/upload_screen.dart` - Documents saved directly to `documents` table (verified status)
- `lib/screens/camera_scan_screen.dart` - Documents saved directly to `documents` table
- `lib/screens/category_screen.dart` - Shows only documents from `documents` table (no pending)
- `lib/screens/document_view_screen.dart` - Removed review panel, simplified for student view
- `lib/screens/login_screen.dart` - Removed HOD invite link
- `lib/services/supa_service.dart` - Documents inserted with 'verified' status

### Unused Files (Can be deleted later):
- `lib/screens/hod_dashboard_screen.dart` - No longer used
- `lib/screens/hod_invite_screen.dart` - No longer used
- `lib/services/hod_invite_service.dart` - No longer used
- `lib/config/hod_config.dart` - Can be kept for future use or removed

## Current Workflow

```
Student Signup:
  Enter name, email, password
    ↓
  OTP sent to email
    ↓
  Enter OTP code
    ↓
  Account created (student role)
    ↓
  Login to dashboard

Document Upload:
  Scan/Upload document
    ↓
  OCR validates document
    ↓
  Document saved to database (verified status)
    ↓
  Student can view/download immediately
```

## Database

Documents are saved directly to the `documents` table with:
- Status: `'verified'` (always)
- No pending status
- No HOD review needed

The `pending_documents` table still exists in the database but is not used by the app anymore.

