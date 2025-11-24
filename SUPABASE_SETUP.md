# Supabase Setup Guide for SafeDocs

This guide will walk you through setting up Supabase for your SafeDocs Flutter application step by step.

## Prerequisites
- A Supabase account (sign up at https://supabase.com if you don't have one)
- Your Flutter project ready (which we've already set up)

---

## Step 1: Create a Supabase Project

1. **Go to Supabase Dashboard**
   - Visit https://app.supabase.com
   - Sign in or create a new account

2. **Create New Project**
   - Click "New Project" button
   - Fill in the project details:
     - **Name**: SafeDocs (or any name you prefer)
     - **Database Password**: Create a strong password (save it securely!)
     - **Region**: Choose the region closest to your users
     - **Pricing Plan**: Select Free tier for development
   - Click "Create new project"
   - Wait 2-3 minutes for the project to be provisioned

---

## Step 2: Get Your API Keys

1. **Navigate to Project Settings**
   - In your project dashboard, click on the gear icon (⚙️) in the left sidebar
   - Select "API" from the settings menu

2. **Copy Your Credentials**
   - You'll see two important values:
     - **Project URL**: Copy this (looks like: `https://xxxxxxxxxxxxx.supabase.co`)
     - **anon/public key**: Copy this (a long JWT token)
   
3. **Add Keys to Your Flutter App**
   - Open `lib/main.dart` in your project
   - Find these lines (around line 12-13):
     ```dart
     const String supabaseUrl = 'YOUR_SUPABASE_URL';
     const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     ```
   - Replace `YOUR_SUPABASE_URL` with your Project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your anon/public key
   - Save the file

---

## Step 3: Set Up Database Tables

### 3.1 Create the `profiles` Table

1. **Open SQL Editor**
   - In Supabase dashboard, click "SQL Editor" in the left sidebar
   - Click "New query"

2. **Run This SQL to Create Profiles Table**
   ```sql
   -- Create profiles table
   CREATE TABLE IF NOT EXISTS profiles (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     name TEXT NOT NULL,
     email TEXT NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
   );

   -- Enable Row Level Security
   ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

   -- Create policy: Users can read their own profile
   CREATE POLICY "Users can view own profile"
     ON profiles FOR SELECT
     USING (auth.uid() = id);

   -- Create policy: Users can update their own profile
   CREATE POLICY "Users can update own profile"
     ON profiles FOR UPDATE
     USING (auth.uid() = id);

   -- Create policy: Users can insert their own profile
   CREATE POLICY "Users can insert own profile"
     ON profiles FOR INSERT
     WITH CHECK (auth.uid() = id);
   ```

3. **Click "Run"** to execute the SQL

### 3.2 Create the `documents` Table

1. **In the Same SQL Editor**, run this SQL:
   ```sql
   -- Create documents table
   CREATE TABLE IF NOT EXISTS documents (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     category TEXT NOT NULL CHECK (category IN ('10th', '12th', 'UG', 'PG', 'Other')),
     file_name TEXT NOT NULL,
     file_path TEXT NOT NULL,
     file_size INTEGER NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
   );

   -- Create index for faster queries
   CREATE INDEX IF NOT EXISTS idx_documents_user_category 
     ON documents(user_id, category);

   -- Enable Row Level Security
   ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

   -- Create policy: Users can view their own documents
   CREATE POLICY "Users can view own documents"
     ON documents FOR SELECT
     USING (auth.uid() = user_id);

   -- Create policy: Users can insert their own documents
   CREATE POLICY "Users can insert own documents"
     ON documents FOR INSERT
     WITH CHECK (auth.uid() = user_id);

   -- Create policy: Users can delete their own documents
   CREATE POLICY "Users can delete own documents"
     ON documents FOR DELETE
     USING (auth.uid() = user_id);
   ```

2. **Click "Run"** to execute the SQL

---

## Step 4: Set Up Storage Bucket

### 4.1 Create the Storage Bucket

1. **Navigate to Storage**
   - Click "Storage" in the left sidebar
   - Click "Create a new bucket"

2. **Configure the Bucket**
   - **Name**: `documents` (must match exactly)
   - **Public bucket**: **UNCHECKED** (keep it private)
   - **File size limit**: Set to 50MB or your preferred limit
   - **Allowed MIME types**: Leave empty (allows all types) or specify:
     - `application/pdf,image/jpeg,image/png,image/gif`
   - Click "Create bucket"

### 4.2 Set Up Storage Policies

1. **Go to Storage Policies**
   - Click on the `documents` bucket you just created
   - Click on "Policies" tab

2. **Create Upload Policy**
   - Click "New Policy"
   - Select "Create a policy from scratch"
   - **Policy name**: `Users can upload own documents`
   - **Allowed operation**: SELECT "INSERT"
   - **Policy definition**: 
     ```sql
     (bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])
     ```
   - Click "Review" then "Save policy"

3. **Create Read Policy**
   - Click "New Policy" again
   - Select "Create a policy from scratch"
   - **Policy name**: `Users can read own documents`
   - **Allowed operation**: SELECT "SELECT"
   - **Policy definition**:
     ```sql
     (bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])
     ```
   - Click "Review" then "Save policy"

4. **Create Delete Policy**
   - Click "New Policy" again
   - Select "Create a policy from scratch"
   - **Policy name**: `Users can delete own documents`
   - **Allowed operation**: SELECT "DELETE"
   - **Policy definition**:
     ```sql
     (bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])
     ```
   - Click "Review" then "Save policy"

**Note**: The policy `(storage.foldername(name))[1]` checks that the first folder in the path matches the user's ID, ensuring users can only access files in their own folder.

---

## Step 5: Configure Authentication Settings

1. **Navigate to Authentication Settings**
   - Click "Authentication" in the left sidebar
   - Click "Settings" (gear icon)

2. **Enable Email Authentication**
   - Under "Auth Providers", ensure "Email" is enabled
   - You can configure:
     - **Enable email confirmations**: Toggle ON for production, OFF for testing
     - **Secure email change**: Toggle ON
     - **Double confirm email changes**: Toggle ON

3. **Configure Email Templates (Optional)**
   - You can customize the confirmation and reset password emails
   - For development, you can disable email confirmation

---

## Step 6: Test Your Setup

### 6.1 Test Database Connection

1. **Run your Flutter app**
   ```bash
   flutter run
   ```

2. **Try to register a new user**
   - The app should create a user in Supabase Auth
   - Check the "Authentication" > "Users" section in Supabase dashboard
   - You should see the new user listed

3. **Check Profile Creation**
   - After registration, check the "Table Editor" > "profiles" table
   - You should see a new row with the user's profile information

### 6.2 Test File Upload

1. **Login to the app**
2. **Select a category** (e.g., "10th")
3. **Upload a test file**
4. **Check Storage**
   - Go to "Storage" > "documents" bucket in Supabase dashboard
   - You should see a folder structure: `documents/{user_id}/{category}/filename`
5. **Check Database**
   - Go to "Table Editor" > "documents" table
   - You should see a new document record

---

## Step 7: Verify Row Level Security (RLS)

RLS ensures users can only access their own data. To verify:

1. **Test with Different Users**
   - Register two different accounts
   - Upload documents with each account
   - Each user should only see their own documents

2. **Check Policies**
   - Go to "Authentication" > "Policies" in Supabase dashboard
   - Verify all policies are active (green checkmark)

---

## Troubleshooting

### Issue: "Invalid API key" error
- **Solution**: Double-check that you copied the correct anon key (not the service_role key)
- Make sure there are no extra spaces in the keys in `main.dart`

### Issue: "Table doesn't exist" error
- **Solution**: Make sure you ran the SQL scripts in Step 3
- Check the "Table Editor" to verify tables exist

### Issue: "Bucket not found" error
- **Solution**: Ensure the bucket is named exactly `documents` (lowercase)
- Check that the bucket exists in Storage section

### Issue: "Permission denied" when uploading
- **Solution**: Verify Storage policies are set up correctly (Step 4.2)
- Check that RLS is enabled on the bucket

### Issue: "Profile creation fails"
- **Solution**: Check that the `profiles` table has the correct RLS policies
- Verify the user ID matches between auth.users and profiles.id

### Issue: Auto-login not working
- **Solution**: Check that `flutter_secure_storage` is properly configured
- On Android, ensure minSdkVersion is 18+ in `android/app/build.gradle`
- On iOS, no additional setup needed

---

## Security Best Practices

1. **Never commit your keys to version control**
   - Consider using environment variables or a config file that's in `.gitignore`
   - The anon key is safe to use in client apps, but the service_role key should NEVER be exposed

2. **Enable RLS on all tables**
   - Always use Row Level Security policies
   - Test that users can't access other users' data

3. **Use signed URLs for private files**
   - The app already implements this for document viewing
   - Signed URLs expire after 1 hour (configurable)

4. **Set appropriate file size limits**
   - Configure limits in Storage bucket settings
   - Validate file sizes in your app before upload

---

## Next Steps

Once Supabase is set up:

1. ✅ Test user registration and login
2. ✅ Test document upload and viewing
3. ✅ Verify data isolation between users
4. ✅ Apply your Figma design to the UI
5. ✅ Test on both Android and iOS devices

---

## Additional Resources

- **Supabase Documentation**: https://supabase.com/docs
- **Flutter Supabase Package**: https://pub.dev/packages/supabase_flutter
- **Supabase Discord Community**: https://discord.supabase.com

---

## Quick Reference: File Structure

Your Supabase setup should have:

```
Supabase Project
├── Database
│   ├── profiles (table)
│   └── documents (table)
├── Storage
│   └── documents (bucket)
└── Authentication
    └── Email provider (enabled)
```

Your Flutter app structure:
```
lib/
├── main.dart (with Supabase keys)
├── services/
│   └── supa_service.dart
└── screens/
    ├── register_screen.dart
    ├── login_screen.dart
    ├── dashboard_screen.dart
    ├── category_screen.dart
    ├── upload_screen.dart
    └── document_view_screen.dart
```

---

**You're all set!** Your SafeDocs app is now connected to Supabase and ready to use. 🎉

