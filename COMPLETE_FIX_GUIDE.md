# Complete Fix Guide for RLS Error with Firebase Auth

## The Problem

You're getting: `StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)`

This happens because you're using **Firebase Auth** but Supabase RLS policies check `auth.uid()` which doesn't work with Firebase Auth.

## Step-by-Step Fix

### ✅ Step 1: Verify Database Schema

First, make sure your database columns are TEXT (not UUID):

1. Go to Supabase Dashboard → SQL Editor
2. Run this query:
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'documents' 
   AND column_name = 'user_id';
   ```
3. **If `data_type` is `uuid`**, run `migrate_to_firebase_auth.sql` first
4. **If `data_type` is `text`**, proceed to Step 2

### ✅ Step 2: Fix Database RLS Policies

1. Go to Supabase Dashboard → SQL Editor
2. Open `fix_firebase_auth_rls.sql`
3. Copy the entire contents
4. Paste into SQL Editor
5. Click **Run**
6. Verify success (no errors)

### ✅ Step 3: Fix Storage Bucket Policies (CRITICAL - Manual Step)

**This is the most common cause of the error!** Storage policies cannot be updated via SQL.

1. Go to Supabase Dashboard → **Storage**
2. Click on **`documents`** bucket
3. Click on **Policies** tab
4. **Delete ALL existing policies** that use `auth.uid()`
5. Create **3 new policies**:

   **Policy 1: INSERT (Upload)**
   - Name: `Allow authenticated uploads`
   - Operation: **INSERT**
   - Policy: `bucket_id = 'documents'::text`

   **Policy 2: SELECT (Read)**
   - Name: `Allow authenticated reads`
   - Operation: **SELECT**
   - Policy: `bucket_id = 'documents'::text`

   **Policy 3: DELETE (Delete)**
   - Name: `Allow authenticated deletes`
   - Operation: **DELETE**
   - Policy: `bucket_id = 'documents'::text`

### ✅ Step 4: Verify Everything

Run these verification queries in SQL Editor:

```sql
-- Check database policies
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'documents';

-- Should show policies with USING (true) or WITH CHECK (true)
-- NOT auth.uid()
```

### ✅ Step 5: Test Upload

Try uploading a document again. The error should be resolved!

## Troubleshooting

### Still Getting Error?

1. **Check which step fails**:
   - The updated error message will tell you if it's "Storage upload failed" or "Database insert failed"
   - This helps identify which policies need fixing

2. **Verify storage policies**:
   - Go to Storage → documents → Policies
   - Make sure NO policies use `auth.uid()`
   - Make sure all 3 policies exist (INSERT, SELECT, DELETE)

3. **Verify database policies**:
   - Run the verification query above
   - Policies should show `USING (true)`, not `auth.uid()`

4. **Check column types**:
   - Make sure `user_id` is TEXT, not UUID
   - Run the query in Step 1

5. **Clear app cache**:
   - Restart your Flutter app
   - Try uploading again

## Why This Works

- **Database RLS**: Policies are permissive (`USING (true)`) because Firebase Auth handles authentication
- **Storage RLS**: Policies only check bucket name, not user ID
- **Security**: Your app code ensures:
  - Only authenticated Firebase users can upload
  - Files are stored in `{user_id}/{category}/filename` structure
  - Users can only access their own files

## Security Notes

⚠️ These policies are permissive, but security is maintained by:
- ✅ Firebase Auth ensures only authenticated users can use the app
- ✅ Application code validates `user_id` matches authenticated user
- ✅ File paths include `user_id` preventing cross-user access
- ✅ Users can only see files in their own folder structure

## Need More Help?

If you're still having issues:
1. Check the exact error message (it now tells you if it's storage or database)
2. Verify all steps above were completed
3. Check Supabase Dashboard for any error logs

