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

# Install Python dependencies (lightweight - no PyTorch needed!)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge && \
    rm -rf /root/.cache/pip && \
    rm -rf /tmp/* && \
    find /usr/local/lib/python3.11 -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true

# Copy application code
COPY app.py .
COPY start.sh .

# Make startup script executable
RUN chmod +x start.sh

# Expose port (Railway sets PORT env var, default to 8080)
EXPOSE 8080

# Use startup script that properly handles PORT variable
CMD ["./start.sh"]
