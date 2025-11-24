-- ============================================
-- Fix RLS Policies for Documents Table
-- ============================================
-- Run this script in Supabase SQL Editor to fix RLS policy issues
-- ============================================

-- First, let's check if RLS is enabled (optional verification)
-- SELECT tablename, rowsecurity FROM pg_tables 
-- WHERE schemaname = 'public' AND tablename = 'documents';

-- Ensure RLS is enabled on documents table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to recreate them)
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
DROP POLICY IF EXISTS "Users can update own documents" ON documents;

-- Create policy: Users can view their own documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (auth.uid() = user_id);

-- Create policy: Users can insert their own documents
-- This is the critical one that was failing
CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create policy: Users can delete their own documents
CREATE POLICY "Users can delete own documents"
  ON documents FOR DELETE
  USING (auth.uid() = user_id);

-- Create policy: Users can update their own documents (optional, for future use)
CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- Fix Category Constraint
-- ============================================
-- Remove the restrictive CHECK constraint and allow any category text
-- This allows categories like 'Marks Cards', 'Transfer Certificate', etc.

-- Drop the old constraint if it exists
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_category_check;

-- Optionally, you can add a new, more flexible constraint or remove it entirely
-- For now, we'll remove it to allow any category string
-- If you want to keep some validation, uncomment and modify the line below:
-- ALTER TABLE documents ADD CONSTRAINT documents_category_check 
--   CHECK (category IS NOT NULL AND length(category) > 0);

-- ============================================
-- Verification Queries (Optional)
-- ============================================

-- Check if policies exist
-- SELECT policyname, cmd, qual, with_check 
-- FROM pg_policies 
-- WHERE tablename = 'documents';

-- Test the policies (replace 'your-user-id' with an actual user ID)
-- SELECT * FROM documents WHERE user_id = 'your-user-id';

-- ============================================
-- END OF FIX SCRIPT
-- ============================================

