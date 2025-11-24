# Fix RLS Policy Error - Step by Step Guide

## Problem
You're getting this error when uploading documents:
```
StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

## Solution

### Step 1: Run the Fix SQL Script

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Go to **SQL Editor** (in the left sidebar)
4. Click **New Query**
5. Copy and paste the entire contents of `fix_rls_policies.sql` file
6. Click **Run** (or press Ctrl+Enter)

This script will:
- ✅ Recreate the RLS policies correctly
- ✅ Remove the restrictive category constraint
- ✅ Allow any category name (like "Marks Cards", "Transfer Certificate", etc.)

### Step 2: Verify the Fix

After running the script, you can verify it worked by running this query in the SQL Editor:

```sql
-- Check if policies exist
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'documents';
```

You should see 4 policies:
- Users can view own documents (SELECT)
- Users can insert own documents (INSERT) ← This is the critical one
- Users can delete own documents (DELETE)
- Users can update own documents (UPDATE)

### Step 3: Test Upload Again

Try uploading a document again. It should work now!

## What Was Wrong?

1. **RLS Policy Issue**: The INSERT policy might not have been created correctly, or the user_id wasn't matching `auth.uid()`
2. **Category Constraint**: The database only allowed specific categories ('10th', '12th', etc.) but your app uses different names ('Marks Cards', 'Transfer Certificate', etc.)

Both issues are now fixed!

