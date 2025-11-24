# Docker Image Size Optimization

## Problem
Docker image was 7.9 GB (exceeds Railway's 4.0 GB limit).

## Solution Applied

### 1. Use CPU-Only PyTorch
- GPU PyTorch: ~2-3 GB
- CPU PyTorch: ~500 MB
- Saves ~2 GB

### 2. Optimize Dependencies
- Use `opencv-python-headless` (smaller than full opencv)
- Remove unnecessary packages
- Clean pip cache after installation

### 3. Multi-Stage Build (Alternative)
If still too large, we can use multi-stage builds to reduce further.

## Expected Size
- Base Python: ~150 MB
- CPU PyTorch: ~500 MB
- Transformers: ~200 MB
- Other deps: ~100 MB
- Model (downloaded at runtime): ~1.5 GB (not in image)
- **Total: ~1-1.5 GB** ✅

## Model Download
The Donut model (~1.5 GB) is downloaded at runtime, not included in the image. This keeps the image small.

## If Still Too Large

### Option 1: Use Model Caching
```dockerfile
# Cache model in image (increases size but faster startup)
RUN python -c "from transformers import DonutProcessor; DonutProcessor.from_pretrained('naver-clova-ix/donut-base')"
```

### Option 2: Multi-Stage Build
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements-docker.txt .
RUN pip install --user --no-cache-dir -r requirements-docker.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
CMD gunicorn app:app --bind 0.0.0.0:$PORT
```

### Option 3: Use Lighter Alternatives
- Consider using smaller models
- Use ONNX runtime instead of PyTorch
- Use TensorFlow Lite

## Current Optimization
The Dockerfile now:
1. Uses CPU-only PyTorch
2. Cleans pip cache
3. Removes build dependencies after install
4. Removes Python cache files
5. Downloads model at runtime (not in image)

This should reduce image size to ~1-1.5 GB, well under the 4 GB limit.

