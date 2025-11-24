# Supabase Quick Start Checklist

Use this checklist to quickly set up Supabase for SafeDocs:

## ✅ Setup Checklist

### 1. Create Supabase Project
- [ ] Sign up/login at https://app.supabase.com
- [ ] Click "New Project"
- [ ] Name: "SafeDocs"
- [ ] Set database password (save it!)
- [ ] Select region
- [ ] Wait for project to be ready (~2-3 minutes)

### 2. Get API Keys
- [ ] Go to Settings → API
- [ ] Copy "Project URL"
- [ ] Copy "anon public" key
- [ ] Open `lib/main.dart` in your Flutter project
- [ ] Replace `YOUR_SUPABASE_URL` with Project URL
- [ ] Replace `YOUR_SUPABASE_ANON_KEY` with anon key
- [ ] Save file

### 3. Create Database Tables
- [ ] Go to SQL Editor in Supabase
- [ ] Click "New query"
- [ ] Copy entire contents of `supabase_setup.sql` file
- [ ] Paste into SQL Editor
- [ ] Click "Run" (or press Ctrl+Enter)
- [ ] Verify success message

### 4. Create Storage Bucket
- [ ] Go to Storage in Supabase
- [ ] Click "Create a new bucket"
- [ ] Name: `documents` (exactly, lowercase)
- [ ] **Uncheck** "Public bucket" (keep it private)
- [ ] Set file size limit (e.g., 50MB)
- [ ] Click "Create bucket"

### 5. Set Storage Policies
- [ ] Click on `documents` bucket
- [ ] Go to "Policies" tab
- [ ] Create 3 policies:

**Policy 1: Upload (INSERT)**
- Name: `Users can upload own documents`
- Operation: INSERT
- Policy: `(bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])`

**Policy 2: Read (SELECT)**
- Name: `Users can read own documents`
- Operation: SELECT
- Policy: `(bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])`

**Policy 3: Delete (DELETE)**
- Name: `Users can delete own documents`
- Operation: DELETE
- Policy: `(bucket_id = 'documents'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])`

### 6. Configure Authentication
- [ ] Go to Authentication → Settings
- [ ] Ensure "Email" provider is enabled
- [ ] For testing: Disable "Enable email confirmations"
- [ ] For production: Enable "Enable email confirmations"

### 7. Test the Setup
- [ ] Run `flutter pub get` in terminal
- [ ] Run `flutter run` to start app
- [ ] Try registering a new account
- [ ] Check Supabase → Authentication → Users (should see new user)
- [ ] Check Supabase → Table Editor → profiles (should see profile)
- [ ] Login to app
- [ ] Upload a test document
- [ ] Check Supabase → Storage → documents (should see file)
- [ ] Check Supabase → Table Editor → documents (should see record)

## 🎯 Quick Reference

### Where to Find Things in Supabase Dashboard:

```
Left Sidebar:
├── 🏠 Home
├── 📊 Table Editor (view/edit data)
├── 🔍 SQL Editor (run SQL scripts)
├── 🔐 Authentication (users, policies)
├── 📦 Storage (buckets, files)
└── ⚙️ Settings (API keys, config)
```

### Important File Paths in Your Project:

```
lib/
└── main.dart (lines 12-13: Add your Supabase keys here)

supabase_setup.sql (Run this in SQL Editor)
```

## 🚨 Common Issues

| Issue | Solution |
|-------|----------|
| "Invalid API key" | Check you copied the anon key (not service_role) |
| "Table doesn't exist" | Run the `supabase_setup.sql` script |
| "Bucket not found" | Ensure bucket is named exactly `documents` |
| "Permission denied" | Check Storage policies are created |
| Auto-login fails | Check `flutter_secure_storage` is installed |

## 📝 Notes

- **anon key**: Safe to use in client apps (Flutter)
- **service_role key**: NEVER expose this in client apps (server-side only)
- **RLS (Row Level Security)**: Ensures users only see their own data
- **Storage policies**: Control who can upload/read/delete files

## ✨ You're Done!

Once all checkboxes are checked, your SafeDocs app is ready to use!

For detailed explanations, see `SUPABASE_SETUP.md`

