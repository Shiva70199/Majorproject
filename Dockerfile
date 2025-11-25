# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install only essential system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements first (for better caching)
COPY requirements-docker.txt requirements.txt

# Install Python dependencies with optimizations
# Use CPU-only PyTorch (much smaller than GPU version, ~500MB vs ~2GB)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge && \
    rm -rf /root/.cache/pip && \
    rm -rf /tmp/* && \
    find /usr/local/lib/python3.11 -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true

# Copy application code
COPY app.py .

# Expose port (Railway sets PORT env var, default to 8080)
EXPOSE 8080

# Run with gunicorn - use explicit port binding with fallback
# Railway sets PORT env var, but we need to ensure it's used correctly
# Add --preload to catch import errors early
CMD sh -c "gunicorn app:app --bind 0.0.0.0:${PORT:-8080} --workers 1 --timeout 120 --access-logfile - --error-logfile - --preload --log-level info"
