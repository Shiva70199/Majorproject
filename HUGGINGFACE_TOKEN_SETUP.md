# Fix HuggingFace 403 Authentication Error

## Problem
Getting error: `403 - "This authentication method does not have sufficient permissions to call Inference Providers on behalf of user shiva7019"`

## Solution: Create/Update HuggingFace API Token

### Step 1: Create a New HuggingFace Token

1. **Go to HuggingFace Settings**:
   - Visit: https://huggingface.co/settings/tokens
   - Login with your account (shiva7019)

2. **Create New Token**:
   - Click "New token"
   - Name it: `safedocs-classification` (or any name you prefer)
   - **Select Role**: Choose **"Read"** access (this is enough for inference)
   - Click "Generate token"

3. **Copy the Token**:
   - ⚠️ **IMPORTANT**: Copy the token immediately - you won't be able to see it again!
   - It will look like: `hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 2: Add Token to Railway

1. **Go to Railway Dashboard**:
   - Visit: https://railway.app
   - Select your project: `majorproject-production`
   - Click on your service

2. **Add Environment Variable**:
   - Go to "Variables" tab
   - Click "New Variable"
   - **Name**: `HF_API_TOKEN`
   - **Value**: Paste your token (e.g., `hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
   - Click "Add"

3. **Redeploy** (if needed):
   - Railway will auto-redeploy when you add the variable
   - Or manually trigger a redeploy

### Step 3: Verify Token is Set

After deployment, check the health endpoint:
```bash
curl https://majorproject-production-a70b.up.railway.app/health
```

Should return:
```json
{
  "status": "healthy",
  "service": "HuggingFace Inference API wrapper",
  "model": "naver-clova-ix/donut-base",
  "api_token_set": true  // <-- Should be true
}
```

### Step 4: Test Classification

Try uploading a document again. The 403 error should be resolved.

## Troubleshooting

### Still Getting 403 Error?

1. **Check Token Permissions**:
   - Go to https://huggingface.co/settings/tokens
   - Make sure your token has **"Read"** access (not "Write" or "Admin")
   - If unsure, delete the old token and create a new one with "Read" access

2. **Verify Token in Railway**:
   - Railway Dashboard → Your Service → Variables
   - Check that `HF_API_TOKEN` is set correctly
   - Make sure there are no extra spaces or quotes

3. **Check Token Format**:
   - Token should start with `hf_`
   - Should be about 40-50 characters long
   - No spaces or line breaks

4. **Try Regenerating Token**:
   - Delete the old token
   - Create a new one
   - Update Railway variable with new token

### Alternative: Use Without Token (Limited)

If you don't want to use a token, the API will work but with:
- Lower rate limits (~30 requests/minute)
- May have more restrictions

To use without token:
- Remove `HF_API_TOKEN` from Railway variables
- The server will work but with limitations

## Why This Happens

The new `router.huggingface.co` endpoint requires proper authentication. The old `api-inference.huggingface.co` endpoint was more lenient, but it's been deprecated.

## Expected Behavior After Fix

- ✅ No more 403 errors
- ✅ Classification works properly
- ✅ Better rate limits (with token)
- ✅ More reliable service

## Next Steps

1. ✅ Create HuggingFace token with "Read" access
2. ✅ Add `HF_API_TOKEN` to Railway variables
3. ✅ Wait for Railway to redeploy
4. ✅ Test document upload
5. ✅ Should work now! 🎉

