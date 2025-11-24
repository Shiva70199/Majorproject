# Railway Deployment Fix

## Problem
Railway is trying to deploy from the root directory, but the Python server is in `classify_document_server/` folder.

## Solution: Configure Railway to Use Correct Directory

### Option 1: Set Root Directory in Railway (Recommended)

1. **In Railway Dashboard:**
   - Go to your service settings
   - Click on "Settings" tab
   - Find "Root Directory" setting
   - Set it to: `classify_document_server`
   - Save and redeploy

### Option 2: Move Files to Root (Alternative)

If Option 1 doesn't work, we can move the server files to the repository root.

## Quick Fix Steps

1. **In Railway Dashboard:**
   - Click on your service
   - Go to "Settings"
   - Scroll to "Root Directory"
   - Enter: `classify_document_server`
   - Click "Save"
   - Click "Redeploy"

2. **Or redeploy from GitHub:**
   - Railway will automatically detect the `classify_document_server` folder
   - Make sure the root directory is set correctly

## Verification

After setting root directory, Railway should:
- Detect Python automatically
- Install from `requirements.txt`
- Run `gunicorn app:app` on startup

