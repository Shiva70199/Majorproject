# Document Workflow Changes Summary

## Overview
The application has been updated to implement a new document verification workflow where documents are **not saved to the database until HOD verifies them**. Rejected documents are deleted and never saved.

## Key Changes

### 1. New Database Table: `pending_documents`
- Created a new table to store documents awaiting HOD verification
- Documents uploaded by students are stored here first (not in main `documents` table)
- Location: `migration_pending_documents.sql`

**To apply the migration:**
1. Go to Supabase Dashboard → SQL Editor
2. Run the SQL script in `migration_pending_documents.sql`

### 2. Student Signup & Authentication (Already Implemented)
- ✅ Students enter: name, email, password
- ✅ OTP sent to student's email
- ✅ After OTP verification, account created
- ✅ Uses Firebase Authentication

### 3. HOD Authentication
- **Predefined HOD emails**: Configure in `lib/config/hod_config.dart`
- **HOD invite service**: `lib/services/hod_invite_service.dart`
  - Can send password reset links to predefined HOD emails
  - HOD sets password themselves via Firebase password reset link
  - After setting password, HOD can login with email + password

**Note:** HOD invite UI needs to be added. You can manually:
1. Add HOD emails to `lib/config/hod_config.dart`
2. Use Firebase Console to send password reset emails to those addresses
3. Or implement a UI screen to trigger the invite service

### 4. Document Upload Flow (UPDATED)
**Before:** Documents were saved to `documents` table immediately with 'pending' status.

**Now:**
1. Student uploads document → File saved to Supabase Storage
2. Document metadata saved to `pending_documents` table (NOT `documents` table)
3. Document awaits HOD review
4. **Only after HOD verification** → Document moved to `documents` table with 'verified' status
5. **If HOD rejects** → Document deleted from storage and `pending_documents` table (never saved to `documents`)

**Files Updated:**
- `lib/screens/upload_screen.dart` - Uses `insertPendingDocument()` instead of `insertDocument()`
- `lib/screens/camera_scan_screen.dart` - Same change

### 5. HOD Dashboard (UPDATED)
- Shows **only pending documents** awaiting review
- HOD can view, inspect, verify, or reject documents
- **Verify**: Moves document from `pending_documents` to `documents` table
- **Reject**: Deletes document from storage and `pending_documents` (not saved)
- **File**: `lib/screens/hod_dashboard_screen.dart`

### 6. Student Dashboard (UPDATED)
- Shows **both** verified documents and pending documents
- **Verified documents** (from `documents` table):
  - Can be viewed
  - Can be downloaded
  - Can be deleted
  
- **Pending documents** (from `pending_documents` table):
  - Can be viewed (to see what was uploaded)
  - **Cannot** be downloaded (awaiting verification)
  - **Cannot** be deleted (awaiting HOD decision)
  - Shows "Pending Review" status

**Files Updated:**
- `lib/screens/category_screen.dart` - Loads both verified and pending documents
- `lib/screens/document_view_screen.dart` - Disables download for pending documents

### 7. Services Updated

#### `lib/services/supa_service.dart`
**New Methods:**
- `insertPendingDocument()` - Save document to pending_documents table
- `getPendingDocuments()` - Get all pending documents (for HOD)
- `getPendingDocumentsByUser()` - Get student's pending documents
- `verifyPendingDocument()` - Move verified document to documents table
- `rejectPendingDocument()` - Delete rejected document from storage and pending_documents

#### `lib/services/hod_invite_service.dart` (NEW)
- `inviteHod(email)` - Send password reset link to HOD email
- `inviteAllHods()` - Send invites to all predefined HOD emails

## Database Schema

### `pending_documents` Table (NEW)
```sql
- id (UUID, Primary Key)
- user_id (TEXT)
- category (TEXT)
- file_name (TEXT)
- file_path (TEXT) - Path in Supabase Storage
- file_size (INTEGER)
- uploader_email (TEXT)
- uploader_name (TEXT)
- status (TEXT) - 'pending' or 'rejected'
- status_reason (TEXT)
- rejected_at (TIMESTAMP)
- created_at (TIMESTAMP)
```

### `documents` Table (EXISTING - Modified Usage)
- Now **only** stores **verified** documents
- Status will always be 'verified' for documents in this table
- Documents with 'pending' status are in `pending_documents` table instead

## Workflow Diagram

```
Student Upload
    ↓
File Saved to Storage
    ↓
Metadata Saved to pending_documents Table
    ↓
HOD Reviews Document
    ↓
    ├─→ Verify → Move to documents Table (status: verified)
    │              ↓
    │         Student can view/download
    │
    └─→ Reject → Delete from Storage + pending_documents
                  (Never saved to documents table)
                  ↓
                  Student sees rejection (if applicable)
```

## Next Steps

1. **Run Database Migration:**
   - Execute `migration_pending_documents.sql` in Supabase SQL Editor

2. **Configure HOD Emails:**
   - Edit `lib/config/hod_config.dart`
   - Add authorized HOD email addresses to `allowedHodEmails` list

3. **HOD Invite (Optional):**
   - Create a UI screen for admins to invite HODs
   - Or manually send password reset emails via Firebase Console
   - Or implement automatic invite when adding emails to `hod_config.dart`

4. **Test the Flow:**
   - Student uploads document → Should appear in `pending_documents` only
   - HOD reviews → Verifies or rejects
   - Verified documents → Appear in `documents` table, student can download
   - Rejected documents → Deleted, never appear in `documents` table

## Files Created/Modified

### Created:
- `migration_pending_documents.sql` - Database migration script
- `lib/services/hod_invite_service.dart` - HOD invitation service
- `WORKFLOW_CHANGES_SUMMARY.md` - This file

### Modified:
- `lib/services/supa_service.dart` - Added pending document methods
- `lib/screens/upload_screen.dart` - Use pending_documents
- `lib/screens/camera_scan_screen.dart` - Use pending_documents
- `lib/screens/hod_dashboard_screen.dart` - Show only pending documents
- `lib/screens/category_screen.dart` - Show verified + pending documents
- `lib/screens/document_view_screen.dart` - Handle verification/rejection workflow

## Important Notes

1. **Student can see pending documents** but cannot download them until verified
2. **Rejected documents are permanently deleted** - they don't remain in any table
3. **Only verified documents** are stored in the main `documents` table
4. **HOD dashboard** only shows documents awaiting review (pending status)
5. **Documents table** now exclusively contains verified documents

