-- ============================================
-- Migration: Create pending_documents table
-- ============================================
-- This table stores documents awaiting HOD verification
-- Documents are only moved to the main 'documents' table after HOD verification
-- If rejected, documents are deleted from storage and this table

CREATE TABLE IF NOT EXISTS pending_documents (
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
  uploader_name TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'rejected')),
  status_reason TEXT,
  rejected_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_pending_documents_status 
  ON pending_documents(status);

CREATE INDEX IF NOT EXISTS idx_pending_documents_user_id 
  ON pending_documents(user_id);

-- Enable Row Level Security
ALTER TABLE pending_documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own pending documents" ON pending_documents;
DROP POLICY IF EXISTS "Users can insert own pending documents" ON pending_documents;
DROP POLICY IF EXISTS "Users can delete own pending documents" ON pending_documents;
DROP POLICY IF EXISTS "HODs can view all pending documents" ON pending_documents;

-- Create policies
CREATE POLICY "Users can view own pending documents"
  ON pending_documents FOR SELECT
  USING (true); -- Application code filters by user_id

CREATE POLICY "Users can insert own pending documents"
  ON pending_documents FOR INSERT
  WITH CHECK (true); -- Application code ensures correct user_id

CREATE POLICY "Users can delete own pending documents"
  ON pending_documents FOR DELETE
  USING (true); -- Application code ensures users only delete their own

CREATE POLICY "HODs can view all pending documents"
  ON pending_documents FOR SELECT
  USING (true); -- Application code checks HOD role

