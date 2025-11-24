# Document Classification Server

Standalone Python server for classifying academic documents using Donut-base model.

## Quick Deploy

### Railway

1. **Connect Repository**
   - Go to [Railway](https://railway.app)
   - Click "New Project" → "Deploy from GitHub repo"
   - Select this repository

2. **Configure**
   - Railway auto-detects Python
   - Sets `PORT` automatically
   - Installs from `requirements.txt`

3. **Deploy**
   - Click "Deploy"
   - Wait for build (first deploy takes 5-10 minutes for model download)
   - Copy the generated URL (e.g., `https://your-app.railway.app`)

### Render

1. **Create Web Service**
   - Go to [Render](https://render.com)
   - Click "New" → "Web Service"
   - Connect your GitHub repository

2. **Configure**
   - **Name**: `classify-document`
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app --bind 0.0.0.0:$PORT`
   - **Plan**: Free tier works (but may sleep after inactivity)

3. **Deploy**
   - Click "Create Web Service"
   - Wait for build
   - Copy the URL (e.g., `https://classify-document.onrender.com`)

### Fly.io

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login**
   ```bash
   fly auth login
   ```

3. **Create App**
   ```bash
   fly launch
   ```

4. **Deploy**
   ```bash
   fly deploy
   ```

## Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run server
python app.py

# Or with gunicorn
gunicorn app:app --bind 0.0.0.0:5000
```

Test:
```bash
curl -X POST http://localhost:5000/classify \
  -F "file=@test-image.jpg"
```

## API Endpoints

### POST /classify
Classify an image as academic or non-academic.

**Request (Multipart):**
```bash
curl -X POST https://your-app.railway.app/classify \
  -F "file=@document.jpg"
```

**Request (JSON with Base64):**
```bash
curl -X POST https://your-app.railway.app/classify \
  -H "Content-Type: application/json" \
  -d '{"image": "base64_encoded_image"}'
```

**Response:**
```json
{
  "is_academic": true,
  "score": 5,
  "text": "extracted text...",
  "reason": "Document classified as academic...",
  "matched_keywords": ["grade", "marks", ...]
}
```

### GET /health
Health check endpoint.

```bash
curl https://your-app.railway.app/health
```

## Update Flutter App

After deploying, update `lib/services/document_classifier_service.dart`:

```dart
// Replace the Supabase Edge Function URL with your server URL
final functionUrl = 'https://your-app.railway.app/classify';
```

Or make it configurable (see updated service file).

## Model Information

- **Model**: `naver-clova-ix/donut-base`
- **Size**: ~1.5GB (downloaded on first request)
- **First Request**: 30-60 seconds (model download)
- **Subsequent**: 2-5 seconds per classification

## Cost

- **Railway**: Free tier = $5 credit/month
- **Render**: Free tier (may sleep after inactivity)
- **Fly.io**: Free tier available
- **Model**: Free (HuggingFace public model)

## Troubleshooting

### Model Download Fails
- Check internet connectivity
- Verify HuggingFace is accessible
- Check logs for specific errors

### Timeout Errors
- Increase timeout in hosting platform settings
- First request always takes longer (model download)

### Memory Issues
- Model needs ~2-3GB RAM
- Upgrade hosting plan if needed

## Files

- `app.py` - Main Flask application
- `requirements.txt` - Python dependencies
- `Procfile` - For Railway/Render deployment
- `.env.example` - Environment variables template

