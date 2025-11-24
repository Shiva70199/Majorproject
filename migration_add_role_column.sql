-- ============================================
-- Migration: Add role column to profiles table
-- ============================================
-- This script adds the 'role' column to the profiles table if it doesn't exist
-- Run this in Supabase SQL Editor
-- ============================================

-- Add role column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'role'
  ) THEN
    ALTER TABLE profiles 
    ADD COLUMN role TEXT NOT NULL DEFAULT 'student' 
    CHECK (role IN ('student', 'hod'));
    
    RAISE NOTICE 'Added role column to profiles table';
  ELSE
    RAISE NOTICE 'Role column already exists in profiles table';
  END IF;
END $$;

-- Verify the column was added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'role';

