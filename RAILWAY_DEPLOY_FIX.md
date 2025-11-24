# Railway Deployment Fix

## Problem
Railway failed with "Error creating build plan with Railpack" because it's detecting the Flutter project at the root instead of the Python server.

## Solution: Configure Railway to Use Python Folder

### Option 1: Set Root Directory in Railway (Recommended)

1. **Go to Railway Dashboard**
   - Open your project: https://railway.app/project/your-project-id

2. **Open Service Settings**
   - Click on your "Majorproject" service
   - Go to "Settings" tab

3. **Set Root Directory**
   - Find "Root Directory" setting
   - Set it to: `classify_document_server`
   - Save changes

4. **Redeploy**
   - Railway will automatically redeploy
   - Or click "Redeploy" button

### Option 2: Create New Service from Subfolder

1. **Delete Current Service** (if needed)
   - In Railway, delete the failed "Majorproject" service

2. **Create New Service**
   - Click "+ New" → "GitHub Repo"
   - Select your repository
   - **Important:** Before deploying, click "Settings"
   - Set "Root Directory" to: `classify_document_server`
   - Save and deploy

### Option 3: Use Railway CLI

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link to your project
railway link

# Set root directory
railway variables set RAILWAY_ROOT_DIR=classify_document_server

# Deploy
railway up
```

## Configuration Files Added

I've added these files to help Railway detect Python:

- `classify_document_server/railway.json` - Railway config
- `classify_document_server/runtime.txt` - Python version
- `classify_document_server/nixpacks.toml` - Build config
- `classify_document_server/Procfile` - Already exists

## After Fixing

1. **Commit the new config files:**
   ```bash
   git add classify_document_server/
   git commit -m "Add Railway configuration files"
   git push
   ```

2. **Redeploy in Railway**
   - Railway should now detect Python correctly
   - Build should succeed

3. **Check Logs**
   - First deployment takes 5-10 minutes (model download)
   - Monitor logs in Railway dashboard

## Expected Build Steps

After fixing, you should see:
1. ✅ Initialization
2. ✅ Build > Installing Python dependencies
3. ✅ Build > Installing pip packages
4. ✅ Deploy > Starting gunicorn
5. ✅ Post-deploy > Service running

## Troubleshooting

**Still failing?**
- Check Railway logs for specific error
- Verify `requirements.txt` is in `classify_document_server/`
- Ensure `app.py` exists in that folder
- Check Python version compatibility (3.9+)

**Model download timeout?**
- First request always takes longer
- Increase timeout in Railway settings if needed
