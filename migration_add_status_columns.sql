-- ============================================
-- Migration: Add status and related columns to documents table
-- ============================================
-- Run this script in Supabase SQL Editor if you're getting:
-- "Could not find the 'status' column of 'documents' in the schema cache"
-- ============================================

-- Add status column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'status'
  ) THEN
    ALTER TABLE documents 
    ADD COLUMN status TEXT NOT NULL DEFAULT 'pending' 
    CHECK (status IN ('pending', 'verified', 'rejected'));
  END IF;
END $$;

-- Add status_reason column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'status_reason'
  ) THEN
    ALTER TABLE documents 
    ADD COLUMN status_reason TEXT;
  END IF;
END $$;

-- Add hod_id column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'hod_id'
  ) THEN
    ALTER TABLE documents 
    ADD COLUMN hod_id TEXT;
  END IF;
END $$;

-- Add verified_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'verified_at'
  ) THEN
    ALTER TABLE documents 
    ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- Add uploader_email column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'documents' AND column_name = 'uploader_email'
  ) THEN
    ALTER TABLE documents 
    ADD COLUMN uploader_email TEXT;
  END IF;
END $$;

-- Verify the columns were added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'documents'
ORDER BY ordinal_position;

