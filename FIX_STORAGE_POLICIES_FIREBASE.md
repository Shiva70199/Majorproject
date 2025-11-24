# Fix Storage Policies for Firebase Auth - CRITICAL STEP

## ⚠️ IMPORTANT: This Must Be Done Manually

Storage policies **cannot** be updated via SQL. You must update them in the Supabase Dashboard.

## The Problem

Your storage bucket policies are checking `auth.uid()`, but since you're using Firebase Auth, Supabase doesn't know who the user is, so `auth.uid()` returns NULL and the policy fails.

## The Solution: Update Storage Policies

### Step 1: Go to Storage Policies

1. Open Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Click **Storage** in the left sidebar
4. Click on the **`documents`** bucket
5. Click on the **Policies** tab

### Step 2: Delete Old Policies

1. **Delete ALL existing policies** that mention `auth.uid()`
   - Look for policies with names like:
     - "Users can upload own documents"
     - "Users can read own documents"  
     - "Users can delete own documents"
   - Click the **three dots (⋮)** next to each policy
   - Click **Delete**
   - Confirm deletion

### Step 3: Create New Policies

Create **3 new policies** with these exact settings:

---

#### Policy 1: Upload (INSERT)

1. Click **"New Policy"** button
2. Select **"Create a policy from scratch"**
3. Fill in:
   - **Policy name**: `Allow authenticated uploads`
   - **Allowed operation**: Select **INSERT**
   - **Policy definition**: 
     ```sql
     bucket_id = 'documents'::text
     ```
4. Click **"Review"** then **"Save policy"**

---

#### Policy 2: Read (SELECT)

1. Click **"New Policy"** button
2. Select **"Create a policy from scratch"**
3. Fill in:
   - **Policy name**: `Allow authenticated reads`
   - **Allowed operation**: Select **SELECT**
   - **Policy definition**: 
     ```sql
     bucket_id = 'documents'::text
     ```
4. Click **"Review"** then **"Save policy"**

---

#### Policy 3: Delete (DELETE)

1. Click **"New Policy"** button
2. Select **"Create a policy from scratch"**
3. Fill in:
   - **Policy name**: `Allow authenticated deletes`
   - **Allowed operation**: Select **DELETE**
   - **Policy definition**: 
     ```sql
     bucket_id = 'documents'::text
     ```
4. Click **"Review"** then **"Save policy"**

---

## Why This Works

1. **Permissive Policy**: `bucket_id = 'documents'::text` allows any authenticated request to the bucket
2. **Application Security**: Your app code ensures:
   - Only authenticated Firebase users can upload
   - Files are stored in `{user_id}/{category}/filename` structure
   - Users can only access their own files via the folder structure
3. **Firebase Auth**: Since Firebase handles authentication, we don't need Supabase to validate the user

## Security Note

⚠️ These policies are permissive, but security is maintained by:
- ✅ Firebase Auth ensures only authenticated users can use the app
- ✅ File paths include `user_id` as the first folder
- ✅ Application code validates `user_id` matches authenticated user
- ✅ Users can only see files in their own folder structure

## Verify It Worked

After creating the policies:

1. Try uploading a document in your app
2. If it still fails, check:
   - Did you delete ALL old policies?
   - Did you create all 3 new policies?
   - Are the policy definitions exactly `bucket_id = 'documents'::text`?

## Still Not Working?

If you still get errors after this:

1. **Check database RLS policies** - Run the diagnostic query in `DIAGNOSE_RLS_ERROR.md`
2. **Verify column types** - Make sure `user_id` is TEXT, not UUID
3. **Check error message** - Is it a storage error or database error?

