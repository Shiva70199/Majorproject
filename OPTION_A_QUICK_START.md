# Option A: Standalone Server - Quick Start

## 🚀 3-Step Setup

### Step 1: Deploy to Railway (2 minutes)

1. Go to https://railway.app
2. Click "New Project" → "Deploy from GitHub repo"
3. Select `classify_document_server` folder
4. Wait for deploy (5-10 min first time)
5. Copy the URL (e.g., `https://your-app.railway.app`)

### Step 2: Update Flutter (30 seconds)

Open `lib/services/document_classifier_service.dart` and add:

```dart
// Line ~30, add this:
static String? customClassificationUrl = 'https://your-app.railway.app';
```

Replace `your-app.railway.app` with your actual Railway URL.

### Step 3: Test (1 minute)

1. Run Flutter app: `flutter run`
2. Upload academic document → ✅ Accepted
3. Upload personal photo → ❌ Rejected

## ✅ Done!

Your classification server is now running separately and connected to your Flutter app.

## 📁 Files Created

- `classify_document_server/app.py` - Flask server
- `classify_document_server/requirements.txt` - Dependencies
- `classify_document_server/Procfile` - Railway config
- `DEPLOY_STANDALONE_SERVER.md` - Full deployment guide

## 🔧 Switch Back to Supabase

If you want to use Supabase Edge Function instead:

```dart
// Set to null or remove the line
static String? customClassificationUrl = null;
```

## 🆘 Troubleshooting

**Server not working?**
- Check Railway logs
- Test with: `curl https://your-app.railway.app/health`

**Flutter can't connect?**
- Verify URL has no trailing slash
- Check CORS is enabled (already done in `app.py`)

**Need help?**
- See `DEPLOY_STANDALONE_SERVER.md` for detailed guide
- Check Railway dashboard logs

