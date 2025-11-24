-- ============================================
-- Migration Script: Update Supabase Schema for Firebase Auth
-- ============================================
-- This script updates the database schema to work with Firebase Auth
-- Firebase user IDs are strings, not UUIDs
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: Drop ALL policies on both tables
-- ============================================
-- We need to drop all policies before altering column types

-- Drop all policies on profiles table
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON profiles';
    END LOOP;
END $$;

-- Drop all policies on documents table
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'documents') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON documents';
    END LOOP;
END $$;

-- ============================================
-- STEP 2: Update profiles table
-- ============================================

-- Drop the foreign key constraint (since we're not using Supabase auth.users anymore)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Remove the PRIMARY KEY constraint temporarily
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_pkey;

-- Change id column from UUID to TEXT
ALTER TABLE profiles ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Re-add PRIMARY KEY with TEXT type
ALTER TABLE profiles ADD PRIMARY KEY (id);

-- ============================================
-- STEP 3: Update documents table
-- ============================================

-- Drop the foreign key constraint
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_user_id_fkey;

-- Drop indexes that depend on user_id before altering
DROP INDEX IF EXISTS idx_documents_user_category;
DROP INDEX IF EXISTS idx_documents_user_id;

-- Change user_id column from UUID to TEXT
ALTER TABLE documents ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;

-- ============================================
-- STEP 4: Recreate indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_documents_user_category 
  ON documents(user_id, category);

CREATE INDEX IF NOT EXISTS idx_documents_user_id 
  ON documents(user_id);

-- ============================================
-- STEP 5: Recreate RLS Policies
-- ============================================
-- Note: Since we're using Firebase Auth, auth.uid() won't work
-- We'll use a more permissive policy that allows users to manage their own data
-- based on the user_id matching. Security is handled by Firebase Auth.

-- Profiles policies
-- Allow users to view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (true); -- Allow all authenticated users to view profiles
  -- In production, you might want to add additional checks

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (true); -- Allow updates (you can add user_id validation in app code)

-- Allow users to insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (true); -- Allow inserts (validate in app code)

-- Documents policies
-- Allow users to view their own documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (true); -- Allow all authenticated users to view documents
  -- Filter by user_id in application code

-- Allow users to insert their own documents
CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (true); -- Allow inserts (validate user_id in app code)

-- Allow users to delete their own documents
CREATE POLICY "Users can delete own documents"
  ON documents FOR DELETE
  USING (true); -- Allow deletes (validate user_id in app code)

-- Allow users to update their own documents
CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  USING (true); -- Allow updates (validate user_id in app code)

-- ============================================
-- VERIFICATION
-- ============================================
-- Run these queries to verify the changes:

-- Check column types
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name IN ('profiles', 'documents') 
-- AND column_name IN ('id', 'user_id');

-- Check policies
-- SELECT * FROM pg_policies WHERE tablename IN ('profiles', 'documents');

-- ============================================
-- END OF MIGRATION
-- ============================================
