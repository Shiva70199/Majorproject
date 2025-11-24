# Railway Root Directory Configuration

## Problem
Railway can't find files because it's building from the root directory, but the Python server files are in `classify_document_server/`.

## Solution: Configure Railway Root Directory

### Option 1: Railway Dashboard (Easiest)

1. **Go to Railway Dashboard**
   - Open: https://railway.app
   - Select your project: `majorproject-production`

2. **Open Service Settings**
   - Click on your service
   - Go to **"Settings"** tab

3. **Set Root Directory**
   - Find **"Root Directory"** setting
   - Set it to: `classify_document_server`
   - Click **"Save"**

4. **Redeploy**
   - Railway will automatically redeploy
   - Or click **"Redeploy"** button

### Option 2: Railway CLI

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link to your project
railway link

# Set root directory
railway variables set SERVICE_ROOT_DIRECTORY=classify_document_server

# Deploy
railway up
```

### Option 3: Use railway.toml (Already Configured)

The `classify_document_server/railway.toml` file already has:
```toml
[build]
rootDirectory = "classify_document_server"
```

But Railway might need this setting in the **service settings** in the dashboard.

## After Configuration

Once Railway is configured to use `classify_document_server` as the root directory:

1. ✅ Dockerfile will be found at `classify_document_server/Dockerfile`
2. ✅ Files will be copied correctly (no `classify_document_server/` prefix needed)
3. ✅ Build should succeed

## Current Status

- ✅ `Dockerfile` in root directory (works if Railway uses root)
- ✅ `classify_document_server/Dockerfile` (works if Railway uses subdirectory)
- ✅ `classify_document_server/railway.toml` configured with rootDirectory
- ⚠️ **You need to set Root Directory in Railway Dashboard**

## Next Steps

1. **Set Root Directory in Railway Dashboard** (see Option 1 above)
2. **Redeploy** and check logs
3. Build should now succeed!

