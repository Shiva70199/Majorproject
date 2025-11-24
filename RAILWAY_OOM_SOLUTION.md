# Railway OOM (Out of Memory) Issue - Solutions

## Problem
Railway free tier is killing workers with `SIGKILL` because the Donut model requires **~2-3GB RAM**, but Railway free tier only provides **~512MB-1GB RAM**.

## Error Pattern
```
[ERROR] Worker (pid:X) was sent SIGKILL! Perhaps out of memory?
```

## Solutions

### ✅ Solution 1: Upgrade Railway Plan (Recommended)
**Cost**: ~$5-10/month

1. Go to Railway Dashboard
2. Select your service
3. Click "Settings" → "Resource Limits"
4. Upgrade to a plan with **at least 2GB RAM**
5. Redeploy

**Pros**: 
- Works immediately
- No code changes needed
- Reliable

**Cons**: 
- Not free

---

### ✅ Solution 2: Use HuggingFace Inference API (FREE)
**Cost**: FREE (with rate limits)

The HuggingFace Inference API provides free access to models without hosting them yourself.

#### Implementation Steps:

1. **Get HuggingFace API Token**:
   - Go to https://huggingface.co/settings/tokens
   - Create a new token (read access is enough)

2. **Update Flutter Service**:
   ```dart
   // In lib/services/document_classifier_service.dart
   static const String customClassificationUrl = 
       'https://api-inference.huggingface.co/models/naver-clova-ix/donut-base';
   ```

3. **Update Request Format**:
   - HuggingFace API uses different format
   - Send base64 image in JSON body
   - Handle rate limiting (free tier has limits)

**Pros**: 
- FREE
- No memory issues
- No server to maintain

**Cons**: 
- Rate limits on free tier
- Slightly different API format
- Requires code changes

---

### ✅ Solution 3: Deploy to Render (FREE with More RAM)
**Cost**: FREE (may sleep after inactivity)

Render free tier provides more RAM than Railway.

1. Go to https://render.com
2. Create new "Web Service"
3. Connect GitHub repo
4. Set:
   - **Build Command**: `cd classify_document_server && pip install -r requirements.txt`
   - **Start Command**: `cd classify_document_server && gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 180`
   - **Root Directory**: `classify_document_server`

**Pros**: 
- FREE
- More RAM than Railway free tier
- Similar to Railway

**Cons**: 
- May sleep after 15 minutes of inactivity
- Slower cold starts

---

### ✅ Solution 4: Use Lighter OCR Model
**Cost**: FREE

Switch from Donut to a lighter OCR model that uses less memory:

- **Tesseract OCR**: ~100MB RAM
- **EasyOCR**: ~500MB RAM
- **PaddleOCR**: ~500MB RAM

**Pros**: 
- Works on Railway free tier
- FREE
- Faster inference

**Cons**: 
- Less accurate than Donut
- Requires code changes
- May not extract structured data as well

---

### ✅ Solution 5: Use ONNX Runtime (Memory Optimization)
**Cost**: FREE

Convert Donut model to ONNX format for lower memory usage:

1. Convert model to ONNX
2. Use ONNX Runtime instead of PyTorch
3. Reduces memory by ~30-40%

**Pros**: 
- May work on Railway free tier
- FREE
- Better performance

**Cons**: 
- Complex setup
- Requires model conversion
- May have compatibility issues

---

## Current Status

After the latest changes:
- ✅ Background pre-loading **disabled** (was causing OOM)
- ✅ Model loads **lazily on first request**
- ✅ Added **garbage collection** to free memory
- ✅ Added **memory warnings** in logs

**However**, Railway free tier still likely won't have enough RAM to load the model even on first request.

## Recommended Next Steps

1. **Try Solution 2 (HuggingFace Inference API)** - Easiest, FREE, no server needed
2. **Or Solution 3 (Render)** - FREE, more RAM
3. **Or Solution 1 (Upgrade Railway)** - If you want to stick with Railway

## Testing

After deploying any solution, test with:
```bash
curl https://your-server.com/health
```

Should return:
```json
{
  "dependencies_available": true,
  "model_loaded": true,
  "status": "healthy"
}
```

