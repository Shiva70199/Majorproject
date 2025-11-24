# Debugging Document Classification Errors

## 🔍 How to Debug the Error

The classification service now has **detailed debug logging** that will help identify the exact issue. Follow these steps:

### Step 1: Check Debug Console Output

When you upload a document, you should see detailed logs in your Flutter debug console (terminal where you ran `flutter run`). Look for these emoji markers:

- 🔍 **Classification URL** - Shows which server is being used
- 📤 **Sending request** - Confirms request is being sent
- 📥 **Received response** - Shows HTTP status code
- ✅ **Success** - Classification completed successfully
- ❌ **Error** - Something went wrong (check the message)

### Step 2: Common Error Types and Solutions

#### Error 1: "Failed to fetch" or "ClientException"
**Possible causes:**
- Server is down or unreachable
- Network connectivity issue
- CORS issue (especially on Flutter Web)

**Solution:**
1. Check if server is running: Visit `https://majorproject-production-a70b.up.railway.app/health` in your browser
2. Check your internet connection
3. For Flutter Web: Check browser console for CORS errors

#### Error 2: "Request timeout"
**Possible causes:**
- Server is overloaded
- Model loading is taking too long (first request)
- Network is slow

**Solution:**
1. Wait a bit and try again (first request loads the model, which takes time)
2. Check Railway logs to see if server is processing requests

#### Error 3: "Cannot connect to classification server"
**Possible causes:**
- Server URL is incorrect
- Server is down
- Firewall blocking connection

**Solution:**
1. Verify server URL in `lib/services/document_classifier_service.dart` (line 36)
2. Test server health: `https://majorproject-production-a70b.up.railway.app/health`
3. Check Railway dashboard to ensure service is running

#### Error 4: "Invalid response from server"
**Possible causes:**
- Server returned non-JSON response
- Server error occurred

**Solution:**
1. Check Railway logs for server errors
2. Verify server is returning proper JSON format
3. Check debug console for actual response body

#### Error 5: "Classification failed: HTTP 500"
**Possible causes:**
- Server-side error (model loading failed, processing error)
- Out of memory on server

**Solution:**
1. Check Railway logs for detailed error messages
2. Restart the Railway service
3. Check if model is loading properly (first request takes longer)

### Step 3: Check Railway Server Logs

1. Go to Railway dashboard: https://railway.app
2. Select your project: `majorproject-production`
3. Click on the service
4. Go to "Logs" tab
5. Look for errors when you upload a document

**What to look for:**
- `Loading Donut-base model...` - Model is loading (first request only)
- `Classification error: ...` - Server-side processing error
- `Handler error: ...` - Request handling error

### Step 4: Test Server Manually

You can test the server directly using curl or Postman:

```bash
# Test health endpoint
curl https://majorproject-production-a70b.up.railway.app/health

# Test classification (replace with actual base64 image)
curl -X POST https://majorproject-production-a70b.up.railway.app/classify \
  -H "Content-Type: application/json" \
  -d '{"image": "base64_encoded_image_here"}'
```

### Step 5: Verify Flutter App Configuration

1. **Check the URL being used:**
   - Open `lib/services/document_classifier_service.dart`
   - Line 36: `static const String customClassificationUrl = 'https://majorproject-production-a70b.up.railway.app';`
   - Make sure this matches your Railway URL

2. **Restart Flutter app completely:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
   (Hot reload might not pick up static constant changes)

3. **Check platform:**
   - For **Flutter Web**: Uses base64 encoding
   - For **Mobile/Desktop**: Uses multipart form data

### Step 6: Enable Verbose Logging

The debug logging is already enabled when running in debug mode (`kDebugMode`). Make sure you're running:
```bash
flutter run
```
Not in release mode, as debug logging is disabled in release builds.

## 📋 What Information to Provide

If you're still getting errors, please provide:

1. **Exact error message** from the Flutter app (the red snackbar message)
2. **Debug console output** (all lines with 🔍, 📤, 📥, ✅, ❌ emojis)
3. **Railway logs** (any errors from the server)
4. **Platform** you're testing on (Windows, Web, Android, iOS)
5. **Network status** (are you on WiFi, mobile data, VPN?)

## 🚀 Quick Fixes to Try

1. **Restart Flutter app completely:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Restart Railway service:**
   - Go to Railway dashboard
   - Restart the service

3. **Check server health:**
   - Visit: `https://majorproject-production-a70b.up.railway.app/health`
   - Should return: `{"status":"healthy","model_loaded":true/false,"dependencies_available":true}`

4. **Clear Flutter cache:**
   ```bash
   flutter clean
   ```

5. **Verify internet connection:**
   - Try accessing the health endpoint in browser
   - Check if other network requests work

## 🔧 Common Issues and Fixes

### Issue: "Still using Supabase URL"
**Fix:** The code has a check that throws an error if Supabase URL is detected. This means the Railway URL constant might not be set correctly. Check line 36 in `document_classifier_service.dart`.

### Issue: CORS errors on Flutter Web
**Fix:** The server should have CORS enabled. Check `classify_document_server/app.py` - it should have `CORS(app)` configured.

### Issue: Model not loading
**Fix:** First request to the server takes longer (30-60 seconds) as it downloads and loads the Donut model. Subsequent requests are faster.

### Issue: Timeout errors
**Fix:** Increase timeout in `document_classifier_service.dart` if your network is slow, or check if Railway service is running properly.

## 📞 Next Steps

After following these steps, if you still have issues:

1. Share the **exact error message** you see
2. Share the **debug console output** (with emojis)
3. Share any **Railway log errors**
4. Let me know which **platform** you're testing on

This will help identify the exact problem!

