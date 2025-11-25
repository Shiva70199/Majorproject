#!/bin/sh
# Startup script for Railway
# Reads PORT from environment and starts gunicorn

PORT=${PORT:-8080}
echo "Starting server on port $PORT"

exec gunicorn app:app \
  --bind 0.0.0.0:$PORT \
  --workers 1 \
  --timeout 120 \
  --access-logfile - \
  --error-logfile - \
  --preload \
  --log-level info

