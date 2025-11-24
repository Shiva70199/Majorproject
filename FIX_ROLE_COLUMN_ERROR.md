# Fix: Missing 'role' Column Error

## Error Message
```
Error creating profile: PostgrestException(message: Could not find the 'role' column of 'profiles' in the schema cache)
```

## Solution

The `profiles` table in your Supabase database is missing the `role` column. Follow these steps to add it:

### Step 1: Run the Migration Script

1. Go to your **Supabase Dashboard**
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `migration_add_role_column.sql`
5. Click **Run** to execute the script

### Step 2: Verify the Column Was Added

After running the script, you should see a message confirming the column was added. You can also verify by:

1. In Supabase Dashboard, go to **Table Editor**
2. Select the `profiles` table
3. You should now see a `role` column with values like 'student' or 'hod'

## What the Migration Does

The script:
- Adds a `role` column to the `profiles` table
- Sets default value to 'student'
- Ensures only 'student' or 'hod' values are allowed
- Won't fail if the column already exists (safe to run multiple times)

## Alternative: Manual Fix

If you prefer to add the column manually in the Supabase Dashboard:

1. Go to **Table Editor** → Select `profiles` table
2. Click **Add Column**
3. Column name: `role`
4. Type: `text`
5. Default value: `'student'`
6. Add a check constraint: `role IN ('student', 'hod')`
7. Click **Save**

## After Running the Migration

Once the `role` column is added:
1. Restart your Flutter app
2. Try signing up again
3. The error should be resolved

The profile will be created successfully with the role automatically assigned based on the email (student or hod).

