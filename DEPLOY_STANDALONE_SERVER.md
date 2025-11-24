# Deploy Standalone Classification Server (Option A)

This guide shows how to deploy the Python classification server separately and connect it to your Flutter app.

## Quick Start

### Step 1: Choose a Hosting Platform

**Recommended: Railway** (easiest, $5 free credit/month)
- ✅ Auto-detects Python
- ✅ Simple deployment
- ✅ Good free tier

**Alternative: Render** (free tier, may sleep)
- ✅ Free tier available
- ⚠️ May sleep after inactivity

**Alternative: Fly.io** (more control)
- ✅ Good free tier
- ⚠️ Requires CLI setup

### Step 2: Deploy to Railway (Recommended)

1. **Go to Railway**
   - Visit https://railway.app
   - Sign up/login with GitHub

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Select the `classify_document_server` folder

3. **Configure**
   - Railway auto-detects Python
   - Sets `PORT` automatically
   - Installs from `requirements.txt`

4. **Deploy**
   - Click "Deploy"
   - Wait 5-10 minutes (first deploy downloads model)
   - Copy the generated URL (e.g., `https://your-app.railway.app`)

### Step 3: Update Flutter App

Open `lib/services/document_classifier_service.dart` and add your server URL:

```dart
// At the top of the file, after the class definition
class DocumentClassifierService {
  // ... existing code ...
  
  // ADD THIS LINE with your Railway/Render URL:
  static String? customClassificationUrl = 'https://your-app.railway.app';
```

**Example:**
```dart
static String? customClassificationUrl = 'https://classify-doc-production.up.railway.app';
```

### Step 4: Test

1. Run your Flutter app
2. Upload an academic document → Should be accepted
3. Upload a personal photo → Should be rejected

## Alternative: Deploy to Render

1. **Go to Render**
   - Visit https://render.com
   - Sign up/login

2. **Create Web Service**
   - Click "New" → "Web Service"
   - Connect GitHub repository
   - Select the `classify_document_server` folder

3. **Configure**
   - **Name**: `classify-document`
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app --bind 0.0.0.0:$PORT`
   - **Plan**: Free

4. **Deploy**
   - Click "Create Web Service"
   - Wait for build
   - Copy URL (e.g., `https://classify-document.onrender.com`)

5. **Update Flutter**
   ```dart
   static String? customClassificationUrl = 'https://classify-document.onrender.com';
   ```

## Alternative: Deploy to Fly.io

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login**
   ```bash
   fly auth login
   ```

3. **Navigate to Server Directory**
   ```bash
   cd classify_document_server
   ```

4. **Create App**
   ```bash
   fly launch
   ```
   - Follow prompts
   - Choose region
   - Don't deploy yet

5. **Deploy**
   ```bash
   fly deploy
   ```

6. **Get URL**
   ```bash
   fly info
   ```
   Copy the hostname (e.g., `https://classify-doc.fly.dev`)

7. **Update Flutter**
   ```dart
   static String? customClassificationUrl = 'https://classify-doc.fly.dev';
   ```

## Testing the Server

### Test Health Endpoint
```bash
curl https://your-app.railway.app/health
```

Expected:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "dependencies_available": true
}
```

### Test Classification
```bash
curl -X POST https://your-app.railway.app/classify \
  -F "file=@test-marksheet.jpg"
```

Expected:
```json
{
  "is_academic": true,
  "score": 5,
  "text": "extracted text...",
  "reason": "Document classified as academic...",
  "matched_keywords": ["grade", "marks", ...]
}
```

## Configuration Options

### Use Supabase Edge Function (Default)
```dart
// Leave this as null or don't set it
static String? customClassificationUrl = null;
```

### Use Standalone Server
```dart
// Set to your deployed server URL
static String? customClassificationUrl = 'https://your-app.railway.app';
```

## Troubleshooting

### Server Not Responding
- Check server logs in Railway/Render dashboard
- Verify the URL is correct (no trailing slash)
- Test with curl first

### Model Download Fails
- Check server logs
- Verify internet connectivity
- First request takes 30-60 seconds

### Flutter Can't Connect
- Check CORS is enabled (already in `app.py`)
- Verify URL format (no trailing slash before `/classify`)
- Check network connectivity

### Timeout Errors
- Increase timeout in hosting platform
- First request always slower (model download)
- Subsequent requests should be 2-5 seconds

## Cost Comparison

| Platform | Free Tier | Paid Plans |
|----------|-----------|------------|
| Railway | $5 credit/month | $20+/month |
| Render | Free (sleeps) | $7+/month |
| Fly.io | Free (limited) | $1.94+/month |

## Files Structure

```
classify_document_server/
├── app.py                 # Flask server
├── requirements.txt       # Python dependencies
├── Procfile             # For Railway/Render
└── README.md            # Server documentation
```

## Next Steps

1. ✅ Deploy server to Railway/Render/Fly.io
2. ✅ Copy the server URL
3. ✅ Update `document_classifier_service.dart` with URL
4. ✅ Test with Flutter app
5. ✅ Monitor server logs

## Support

- Check server logs in hosting dashboard
- Test endpoints with curl
- Verify Flutter service URL is correct
- Check CORS settings if browser errors occur

