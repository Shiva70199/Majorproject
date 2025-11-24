# Fix Classification Error

## Problem
Getting error: `Classification error: ClientException: Failed to fetch, uri: https://ksvxoapdwlojujgnhmuy.supabase.co/functions/v1/classifyDocument`

This means the app is still trying to use Supabase Edge Function instead of Railway server.

## Solution

### Step 1: Verify Railway URL is Set

The Railway URL should already be set in `lib/services/document_classifier_service.dart` line 35:

```dart
static String? customClassificationUrl = 'https://majorproject-production-a70b.up.railway.app';
```

### Step 2: Restart Flutter App (Full Restart)

**Important:** You need a FULL RESTART, not just hot reload:

1. **Stop the app completely**
   - Press `q` in terminal to quit
   - Or close the app completely

2. **Clean build cache**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Restart the app**
   ```bash
   flutter run
   ```

### Step 3: Verify Railway Server is Working

Test the server directly:
```bash
# Health check
curl https://majorproject-production-a70b.up.railway.app/health

# Should return: {"status": "healthy", ...}
```

### Step 4: Check the Code

Make sure `lib/services/document_classifier_service.dart` has:

```dart
static String? customClassificationUrl = 'https://majorproject-production-a70b.up.railway.app';
```

NOT:
```dart
static String? customClassificationUrl = null;  // ❌ Wrong
```

## Why This Happens

- Hot reload doesn't always pick up static variable changes
- Build cache might have old code
- App needs full restart to use new URL

## After Fixing

1. ✅ Railway URL is set
2. ✅ App is fully restarted (not hot reload)
3. ✅ Test upload → Should work now

## Expected Behavior

- Upload document → Flutter sends to Railway
- Railway classifies → Returns result
- Flutter accepts/rejects → Based on classification

If still getting Supabase URL error, the app definitely needs a full restart!

