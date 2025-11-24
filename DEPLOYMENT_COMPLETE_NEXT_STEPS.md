# Deployment Complete - Next Steps

## ✅ Step 1: Get Your Railway URL

1. **Go to Railway Dashboard**
   - Open your project: https://railway.app
   - Click on your "Majorproject" service

2. **Get the URL**
   - Look for "Settings" → "Networking" or "Domains"
   - Copy the generated URL (e.g., `https://your-app.railway.app`)
   - Or create a custom domain if you prefer

3. **Test the Server**
   ```bash
   # Test health endpoint
   curl https://your-app.railway.app/health
   
   # Should return:
   # {"status": "healthy", "model_loaded": true, ...}
   ```

## ✅ Step 2: Update Flutter App

1. **Open Flutter Service File**
   - File: `lib/services/document_classifier_service.dart`
   - Find line ~30 (around `static String? customClassificationUrl`)

2. **Add Your Railway URL**
   ```dart
   // Set to your Railway server URL
   static String? customClassificationUrl = 'https://your-app.railway.app';
   ```

   **Example:**
   ```dart
   static String? customClassificationUrl = 'https://majorproject-production.up.railway.app';
   ```

3. **Save the file**

## ✅ Step 3: Test in Flutter App

1. **Run Your Flutter App**
   ```bash
   flutter run
   ```

2. **Test Upload**
   - Upload an academic document (marksheet, certificate, ID card)
   - Should be **accepted** ✅
   - Upload a personal photo (selfie, scenery)
   - Should be **rejected** ❌

3. **Check Classification**
   - Look for success/error messages
   - Verify documents are being classified correctly

## ✅ Step 4: Verify Everything Works

### Test Academic Document
- Upload a marksheet → Should show "Accepted"
- Upload a certificate → Should show "Accepted"
- Upload an ID card → Should show "Accepted"

### Test Non-Academic Image
- Upload a selfie → Should show "Rejected"
- Upload a photo → Should show "Rejected"
- Upload a meme → Should show "Rejected"

## 🎯 What's Happening

1. **User uploads image** → Flutter app
2. **Flutter sends to Railway** → `https://your-app.railway.app/classify`
3. **Railway runs Donut model** → Extracts text, checks keywords
4. **Returns result** → `is_academic: true/false`
5. **Flutter accepts/rejects** → Based on result

## 📊 Monitor Performance

### Railway Dashboard
- Check logs for classification requests
- Monitor response times
- Check for errors

### First Request
- Takes 30-60 seconds (model download)
- Model is cached after first load
- Subsequent requests: 2-5 seconds

## 🔧 Troubleshooting

### Flutter Can't Connect
- Verify Railway URL is correct (no trailing slash)
- Check CORS is enabled (already done in `app.py`)
- Test with curl first

### Classification Always Fails
- Check Railway logs for errors
- Verify model is loading (check `/health` endpoint)
- Test with curl to isolate Flutter vs server issues

### Wrong Results
- Check extracted text in Railway logs
- Adjust keywords in `app.py` if needed
- Verify image quality (blurry images may fail)

## ✨ You're Done!

Your document classification system is now:
- ✅ Deployed on Railway
- ✅ Connected to Flutter app
- ✅ Ready to classify documents

Just update the URL in `document_classifier_service.dart` and test!

