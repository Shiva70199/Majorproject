-- ============================================
-- SafeDocs Supabase Database Setup Script
-- ============================================
-- Run this entire script in Supabase SQL Editor
-- This will create all necessary tables and policies
--
-- IMPORTANT SECURITY NOTE:
-- This setup uses Firebase Auth (not Supabase Auth) with Supabase for storage/database.
-- Since we're using the anon key, Supabase RLS cannot verify Firebase user identities.
-- All security is enforced in the Flutter application code by:
--   1. Filtering queries by user_id (users only see their own data)
--   2. Validating user_id on inserts/updates
--   3. Checking user roles before allowing HOD operations
--
-- For production, consider:
--   - Using Supabase Auth instead of Firebase Auth, OR
--   - Setting up custom JWT validation with Firebase tokens, OR
--   - Using Supabase service role key for server-side operations only
-- ============================================

-- ============================================
-- STEP 1: Create profiles table
-- ============================================
-- Note: Using TEXT for user IDs since we're using Firebase Auth (not Supabase Auth)
-- Firebase user IDs are strings, not UUIDs
CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'hod')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable Row Level Security on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running this script)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Service role can manage profiles" ON profiles;

-- Create policy: Users can read their own profile
-- IMPORTANT: Since we're using Firebase Auth with Supabase anon key,
-- Supabase RLS cannot verify user identity. Security is handled in application code.
-- The app filters queries by user_id to ensure users only see their own data.
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (true); -- Application code enforces user_id filtering

-- Create policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (true); -- Application code ensures users only update their own profile

-- Create policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (true); -- Application code ensures correct user_id is set

-- ============================================
-- STEP 2: Create documents table
-- ============================================
-- Note: Using TEXT for user_id since we're using Firebase Auth
CREATE TABLE IF NOT EXISTS documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  category TEXT NOT NULL CHECK (
    category IN (
      'tenth_marksheet',
      'twelfth_marksheet',
      'ug_sem_1',
      'ug_sem_2',
      'ug_sem_3',
      'ug_sem_4',
      'ug_sem_5',
      'ug_sem_6',
      'ug_sem_7',
      'ug_sem_8',
      'ug_certificate',
      'college_id_card',
      'sports_certificate',
      'achievement_certificate'
    )
  ),
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  uploader_email TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  status_reason TEXT,
  hod_id TEXT,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Add missing columns if table already exists (migration support)
DO $$ 
BEGIN
  -- Add uploader_email if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'uploader_email'
  ) THEN
    ALTER TABLE documents ADD COLUMN uploader_email TEXT;
  END IF;

  -- Add status if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'status'
  ) THEN
    ALTER TABLE documents 
    ADD COLUMN status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'verified', 'rejected'));
  END IF;

  -- Add status_reason if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'status_reason'
  ) THEN
    ALTER TABLE documents ADD COLUMN status_reason TEXT;
  END IF;

  -- Add hod_id if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'hod_id'
  ) THEN
    ALTER TABLE documents ADD COLUMN hod_id TEXT;
  END IF;

  -- Add verified_at if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'verified_at'
  ) THEN
    ALTER TABLE documents ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- Create index for faster queries by user_id and category
CREATE INDEX IF NOT EXISTS idx_documents_user_category 
  ON documents(user_id, category);

-- Create index for faster queries by user_id only
CREATE INDEX IF NOT EXISTS idx_documents_user_id 
  ON documents(user_id);

-- Enable Row Level Security on documents
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running this script)
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
DROP POLICY IF EXISTS "HODs can view all documents" ON documents;
DROP POLICY IF EXISTS "Service role can manage documents" ON documents;

-- Create policy: Users can view their own documents
-- IMPORTANT: Security is enforced in application code via user_id filtering
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (true); -- Application code filters by user_id

-- Create policy: Users can insert their own documents
CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (true); -- Application code ensures correct user_id is set

-- Create policy: Users can delete their own documents
CREATE POLICY "Users can delete own documents"
  ON documents FOR DELETE
  USING (true); -- Application code ensures users only delete their own documents

-- ============================================
-- STEP 3: HOD notifications table
-- ============================================
-- Note: Using TEXT for user_id since we're using Firebase Auth
CREATE TABLE IF NOT EXISTS hod_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  user_id TEXT,
  category TEXT NOT NULL,
  message TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'resolved')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE hod_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Notifications readable by authenticated users" ON hod_notifications;
DROP POLICY IF EXISTS "Notifications insert allowed" ON hod_notifications;
DROP POLICY IF EXISTS "HODs can view notifications" ON hod_notifications;
DROP POLICY IF EXISTS "Service role can manage notifications" ON hod_notifications;

-- Allow authenticated users to read notifications
-- IMPORTANT: Security is enforced in application code
CREATE POLICY "Notifications readable by authenticated users"
  ON hod_notifications FOR SELECT
  USING (true); -- Application code handles access control

-- Allow authenticated users to insert notifications
CREATE POLICY "Notifications insert allowed"
  ON hod_notifications FOR INSERT
  WITH CHECK (true); -- Application code ensures proper access control

-- ============================================
-- VERIFICATION QUERIES (Optional - run these to verify setup)
-- ============================================

-- Check if tables exist
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_name IN ('profiles', 'documents');

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables 
-- WHERE schemaname = 'public' AND tablename IN ('profiles', 'documents');

-- Check policies
-- SELECT * FROM pg_policies WHERE tablename IN ('profiles', 'documents');

-- ============================================
-- END OF SETUP SCRIPT
-- ============================================

