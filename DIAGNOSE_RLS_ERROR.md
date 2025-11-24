# Diagnose RLS Error - Step by Step

## Quick Diagnostic

The error "new row violates row-level security policy" can come from:
1. **Database RLS policies** (documents table)
2. **Storage RLS policies** (documents bucket)

Let's check which one is failing:

### Step 1: Check Database Policies

Run this in Supabase SQL Editor:

```sql
-- Check current RLS policies on documents table
SELECT 
    policyname, 
    cmd, 
    qual as "USING clause", 
    with_check as "WITH CHECK clause"
FROM pg_policies 
WHERE tablename = 'documents'
ORDER BY policyname;
```

**Expected Result**: Policies should have `USING (true)` or `WITH CHECK (true)`, NOT `auth.uid()`

If you see `auth.uid()` in the policies, run `fix_firebase_auth_rls.sql` again.

### Step 2: Check Storage Policies

1. Go to **Storage** → **documents** bucket → **Policies** tab
2. Check if any policies use `auth.uid()`

**If you see `auth.uid()` in storage policies**, that's the problem! Storage policies must be updated manually.

### Step 3: Check Column Types

Run this to verify columns are TEXT (not UUID):

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'documents' 
AND column_name = 'user_id';
```

**Expected Result**: `data_type` should be `text`, not `uuid`

If it's `uuid`, run `migrate_to_firebase_auth.sql` first.

## Most Likely Issue

Since you're using **Firebase Auth**, the storage policies are still checking `auth.uid()` which returns NULL. 

**Solution**: Update storage policies manually (see below).

