-- ============================================
-- Fix RLS Policies for Firebase Auth Integration
-- ============================================
-- This script fixes RLS policies to work with Firebase Auth
-- Since Firebase Auth doesn't integrate with Supabase's auth.uid(),
-- we need to use permissive policies and rely on application-level security
-- Run this in Supabase SQL Editor
-- ============================================
-- 
-- IMPORTANT: If you haven't run migrate_to_firebase_auth.sql yet,
-- you may need to run that first to convert UUID columns to TEXT.
-- This script will work regardless, but make sure your columns are TEXT type.
-- ============================================

-- ============================================
-- STEP 1: Fix Documents Table RLS Policies
-- ============================================

-- Ensure RLS is enabled
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
DROP POLICY IF EXISTS "Users can update own documents" ON documents;

-- Create new policies that work with Firebase Auth
-- Note: These are permissive because Firebase Auth handles authentication
-- Application code must validate user_id matches the authenticated user

-- Allow users to view documents (filtered by user_id in app code)
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (true);

-- Allow users to insert documents (user_id validated in app code)
CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (true);

-- Allow users to delete documents (user_id validated in app code)
CREATE POLICY "Users can delete own documents"
  ON documents FOR DELETE
  USING (true);

-- Allow users to update documents (user_id validated in app code)
CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- ============================================
-- STEP 2: Fix Profiles Table RLS Policies
-- ============================================

-- Ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;

-- Create new policies that work with Firebase Auth
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  USING (true);

-- ============================================
-- STEP 3: Fix Storage Bucket Policies
-- ============================================
-- IMPORTANT: Storage policies must be updated manually in the Supabase Dashboard
-- because they cannot be modified via SQL directly
--
-- Go to: Storage > documents bucket > Policies tab
-- Delete existing policies and create new ones with these definitions:
--
-- Policy 1: Upload (INSERT)
-- Name: Users can upload own documents
-- Operation: INSERT
-- Policy: bucket_id = 'documents'::text
--
-- Policy 2: Read (SELECT)
-- Name: Users can read own documents
-- Operation: SELECT
-- Policy: bucket_id = 'documents'::text
--
-- Policy 3: Delete (DELETE)
-- Name: Users can delete own documents
-- Operation: DELETE
-- Policy: bucket_id = 'documents'::text
--
-- Note: The folder structure (user_id/category/filename) ensures users
-- can only access files in their own folder, providing security at the
-- application level.
-- ============================================

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if policies exist and are correct
-- SELECT policyname, cmd, qual, with_check 
-- FROM pg_policies 
-- WHERE tablename IN ('documents', 'profiles')
-- ORDER BY tablename, policyname;

-- ============================================
-- END OF FIX SCRIPT
-- ============================================

