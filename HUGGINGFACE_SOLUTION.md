# Solution: Use HuggingFace Inference API (FREE, No OOM Issues)

## Problem
Railway free tier doesn't have enough RAM (~512MB-1GB) to load the Donut model (~2-3GB RAM needed). Workers are being killed with `SIGKILL` due to Out-Of-Memory (OOM) errors.

## Solution: HuggingFace Inference API

Instead of hosting the model yourself, use HuggingFace's free Inference API. This:
- ✅ **FREE** (with rate limits)
- ✅ **No OOM issues** (model runs on HuggingFace servers)
- ✅ **No server maintenance** (HuggingFace handles it)
- ✅ **Easy to implement** (just change the API endpoint)

## Implementation Steps

### Step 1: Get HuggingFace API Token (Optional but Recommended)

1. Go to https://huggingface.co/settings/tokens
2. Create a new token (read access is enough)
3. Copy the token

**Note**: You can use the API without a token, but you'll have lower rate limits.

### Step 2: Update Railway Environment Variables

1. Go to Railway Dashboard → Your Service → Variables
2. Add:
   - `HF_API_TOKEN` = `your_huggingface_token_here` (optional, but recommended)

### Step 3: Replace app.py with HuggingFace Version

**Option A: Use the new file (Recommended)**

1. Rename current `app.py` to `app_local.py` (backup)
2. Rename `app_hf_inference.py` to `app.py`
3. Commit and push

**Option B: Manual Update**

Update `classify_document_server/app.py` to use HuggingFace API instead of loading the model locally.

### Step 4: Update requirements-docker.txt

Remove heavy ML dependencies (they're not needed anymore):

```txt
# Web framework
Flask>=3.0.0
flask-cors>=4.0.0

# HTTP client for HuggingFace API
requests>=2.31.0

# Server
gunicorn>=21.2.0
```

**Note**: You can remove:
- `transformers` (not needed)
- `torch` (not needed)
- `Pillow` (optional, but keep if you want image processing)
- `numpy` (not needed)
- `sentencepiece` (not needed)
- `protobuf` (not needed)
- `opencv-python-headless` (not needed)

This will make the Docker image much smaller (~200MB instead of ~1.5GB)!

### Step 5: Update Dockerfile

Since we don't need PyTorch anymore, the Dockerfile can be much simpler:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install only essential dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements
COPY requirements-docker.txt requirements.txt

# Install Python dependencies (much lighter now!)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Copy application code
COPY app.py .
COPY start.sh .

# Make startup script executable
RUN chmod +x start.sh

EXPOSE 8080

CMD ["./start.sh"]
```

### Step 6: Deploy

1. Commit changes:
   ```bash
   git add -A
   git commit -m "Switch to HuggingFace Inference API to avoid OOM"
   git push
   ```

2. Railway will auto-deploy

3. Test:
   ```bash
   curl https://your-railway-url.railway.app/health
   ```

## Expected Results

- ✅ **No OOM errors** - Model runs on HuggingFace servers
- ✅ **Faster deployment** - Smaller Docker image (~200MB vs ~1.5GB)
- ✅ **Faster startup** - No model loading needed
- ✅ **FREE** - HuggingFace free tier is generous

## Rate Limits

**Free tier (no token)**:
- ~30 requests/minute
- Model may need to "wake up" on first request (30-60s wait)

**Free tier (with token)**:
- Higher rate limits
- Better reliability

**Paid tier** (if needed later):
- Unlimited requests
- Faster response times

## Testing

After deployment, test with:

```bash
# Health check
curl https://your-railway-url.railway.app/health

# Should return:
# {
#   "status": "healthy",
#   "service": "HuggingFace Inference API wrapper",
#   "model": "naver-clova-ix/donut-base",
#   "api_token_set": true/false
# }
```

## Troubleshooting

### Error: "Model is loading"
- First request to HuggingFace API may take 30-60 seconds
- This is normal - the model needs to "wake up"
- Subsequent requests are faster

### Error: "Rate limit exceeded"
- You've hit the free tier rate limit
- Wait a minute and try again
- Or get a HuggingFace token for higher limits

### Error: "Invalid API response"
- HuggingFace API format may have changed
- Check the response format in `app_hf_inference.py`
- Update the parsing logic if needed

## Comparison

| Feature | Local Model (Current) | HuggingFace API |
|---------|----------------------|-----------------|
| RAM Required | ~2-3GB | ~100MB |
| Docker Image | ~1.5GB | ~200MB |
| Startup Time | 30-60s (model load) | <5s |
| Cost | Free (if hosting works) | Free |
| Rate Limits | None | Yes (free tier) |
| Reliability | OOM issues on Railway | High |

## Next Steps

1. ✅ Get HuggingFace token (optional)
2. ✅ Replace `app.py` with `app_hf_inference.py`
3. ✅ Update `requirements-docker.txt` (remove heavy deps)
4. ✅ Update `Dockerfile` (simplify)
5. ✅ Deploy to Railway
6. ✅ Test classification

This solution should work perfectly on Railway free tier! 🎉

