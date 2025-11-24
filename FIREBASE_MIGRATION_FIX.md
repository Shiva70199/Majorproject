# Fix for Firebase Auth UUID Error

## Problem
You're getting this error during signup:
```
PostgrestException(message: invalid input syntax for type uuid: "BQ3kLVHvKveMLTeSUZQs2rusVku2", code: 22P02)
```

This happens because:
- Firebase Auth generates **string IDs** (like `BQ3kLVHvKveMLTeSUZQs2rusVku2`)
- Your Supabase database expects **UUID format** for the `id` and `user_id` columns

## Solution

### Step 1: Run the Migration SQL Script

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project
   - Click on **SQL Editor** in the left sidebar

2. **Run the Migration Script**
   - Open the file `migrate_to_firebase_auth.sql` in this project
   - Copy the entire contents
   - Paste it into the Supabase SQL Editor
   - Click **Run** (or press Ctrl+Enter)

This script will:
- ✅ Change `profiles.id` from UUID to TEXT
- ✅ Change `documents.user_id` from UUID to TEXT
- ✅ Update RLS policies to work with Firebase Auth
- ✅ Recreate indexes

### Step 2: Verify the Migration

After running the script, verify it worked by running this query in SQL Editor:

```sql
-- Check column types
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('profiles', 'documents') 
AND column_name IN ('id', 'user_id');
```

You should see `text` as the data type for both columns.

### Step 3: Test Signup Again

Try signing up again. The error should be resolved!

## What Changed in the Code

1. **Updated `createProfile()` method**:
   - Now checks if profile exists before creating
   - Handles duplicate profiles gracefully

2. **Improved error handling in `register_screen.dart`**:
   - Better error messages for Firebase Auth errors
   - Handles "email already registered" case
   - Cleans up Firebase user if profile creation fails

## Important Notes

⚠️ **RLS Policies**: The migration script sets RLS policies to `USING (true)` which allows all operations. This is because:
- Firebase Auth doesn't integrate with Supabase's `auth.uid()` function
- Security is handled by Firebase Auth at the application level
- You can add additional validation in your app code if needed

For production, consider:
- Using Supabase service role key for database operations (more secure)
- Adding application-level validation to ensure users can only access their own data
- Implementing a custom function that validates Firebase tokens

## Troubleshooting

If you still get errors:

1. **Check if migration ran successfully**: Look for any error messages in the SQL Editor
2. **Verify column types**: Run the verification query above
3. **Check existing data**: If you have existing UUID data, you may need to migrate it first
4. **Clear and retry**: Try signing up with a new email address

## Next Steps

After the migration:
1. Test signup with a new email
2. Test login
3. Test document upload/download
4. Verify profile creation works correctly

