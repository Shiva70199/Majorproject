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
COPY classify_document_server/requirements-docker.txt requirements.txt

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
COPY classify_document_server/app.py .

# Expose port (Railway sets PORT env var)
EXPOSE $PORT

# Run with gunicorn
CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 180

