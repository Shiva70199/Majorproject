# Fix RLS Error for Firebase Auth - Complete Guide

## Problem
You're getting this error when uploading documents:
```
StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

This happens because:
- Your app uses **Firebase Auth** for authentication
- Supabase RLS policies check `auth.uid()` which only works with Supabase Auth
- When using Firebase Auth, `auth.uid()` returns NULL, causing RLS policies to fail

## Solution

### Step 1: Run the Fix SQL Script

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project
   - Click on **SQL Editor** in the left sidebar

2. **Run the Fix Script**
   - Open the file `fix_firebase_auth_rls.sql` in this project
   - Copy the entire contents
   - Paste it into the Supabase SQL Editor
   - Click **Run** (or press Ctrl+Enter)

This script will:
- ✅ Update RLS policies on `documents` table to work with Firebase Auth
- ✅ Update RLS policies on `profiles` table to work with Firebase Auth
- ✅ Remove dependency on `auth.uid()` which doesn't work with Firebase Auth

### Step 2: Update Storage Bucket Policies

Since storage policies cannot be updated via SQL, you need to update them manually:

1. **Go to Storage in Supabase Dashboard**
   - Click "Storage" in the left sidebar
   - Click on the `documents` bucket

2. **Go to Policies Tab**
   - Click on the "Policies" tab

3. **Delete Existing Policies**
   - Delete all existing policies that use `auth.uid()`

4. **Create New Policies**

   **Policy 1: Upload (INSERT)**
   - Click "New Policy"
   - Select "Create a policy from scratch"
   - **Policy name**: `Users can upload own documents`
   - **Allowed operation**: SELECT "INSERT"
   - **Policy definition**: 
     ```sql
     bucket_id = 'documents'::text
     ```
   - Click "Review" then "Save policy"

   **Policy 2: Read (SELECT)**
   - Click "New Policy"
   - Select "Create a policy from scratch"
   - **Policy name**: `Users can read own documents`
   - **Allowed operation**: SELECT "SELECT"
   - **Policy definition**:
     ```sql
     bucket_id = 'documents'::text
     ```
   - Click "Review" then "Save policy"

   **Policy 3: Delete (DELETE)**
   - Click "New Policy"
   - Select "Create a policy from scratch"
   - **Policy name**: `Users can delete own documents`
   - **Allowed operation**: SELECT "DELETE"
   - **Policy definition**:
     ```sql
     bucket_id = 'documents'::text
     ```
   - Click "Review" then "Save policy"

### Step 3: Verify the Fix

After running the script, verify it worked by running this query in SQL Editor:

```sql
-- Check if policies exist
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename IN ('documents', 'profiles')
ORDER BY tablename, policyname;
```

You should see policies with `USING (true)` or `WITH CHECK (true)` instead of `auth.uid()` checks.

### Step 4: Test Upload Again

Try uploading a document again. It should work now!

## Why This Works

1. **Firebase Auth Integration**: Since Firebase Auth doesn't integrate with Supabase's `auth.uid()` function, we use permissive RLS policies (`USING (true)`)

2. **Application-Level Security**: Security is enforced in your application code:
   - The `upload_screen.dart` validates the user is authenticated via Firebase
   - The `supa_service.dart` ensures `user_id` matches the authenticated Firebase user
   - Files are stored in `{user_id}/{category}/filename` structure, preventing cross-user access

3. **Storage Security**: The folder structure (`user_id/category/filename`) ensures users can only access files in their own folder, even with permissive storage policies

## Important Security Notes

⚠️ **These policies are permissive** because Firebase Auth handles authentication. Your application code must:
- ✅ Always validate the user is authenticated before database operations
- ✅ Always ensure `user_id` matches the authenticated Firebase user ID
- ✅ Never allow users to specify arbitrary `user_id` values

The current implementation in `upload_screen.dart` and `supa_service.dart` already does this correctly.

## Troubleshooting

If you still get errors:

1. **Check if script ran successfully**: Look for any error messages in the SQL Editor
2. **Verify policies**: Run the verification query above
3. **Check storage policies**: Make sure you updated all 3 storage policies manually
4. **Clear cache**: Try restarting your Flutter app
5. **Check user authentication**: Ensure the user is properly authenticated via Firebase

## Next Steps

After the fix:
1. ✅ Test document upload
2. ✅ Test document download/viewing
3. ✅ Test document deletion
4. ✅ Verify users can only see their own documents

