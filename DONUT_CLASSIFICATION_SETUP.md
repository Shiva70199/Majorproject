# Donut Document Classification Setup Guide

This guide explains how to set up the Donut-base document classification system for SafeDocs.

## Overview

The system uses HuggingFace's **naver-clova-ix/donut-base** Vision Transformer model to automatically classify uploaded images as academic documents or non-academic content. This replaces the previous OCR-based validation with a more accurate ML-based approach.

## Architecture

1. **Supabase Edge Function** (`supabase/functions/classifyDocument/`): Python function that runs Donut-base model
2. **Flutter Service** (`lib/services/document_classifier_service.dart`): Calls the Edge Function
3. **Upload Screens**: Updated to use classification instead of OCR

## Prerequisites

- Supabase project with Edge Functions enabled
- Python 3.9+ (for local testing)
- Supabase CLI installed

## Setup Instructions

### Step 1: Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Windows (using Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Or download from: https://github.com/supabase/cli/releases
```

### Step 2: Login to Supabase

```bash
supabase login
```

### Step 3: Link Your Project

```bash
supabase link --project-ref your-project-ref
```

### Step 4: Deploy the Edge Function

```bash
# Navigate to your project root
cd /path/to/safedocs

# Deploy the classifyDocument function
supabase functions deploy classifyDocument
```

### Step 5: Set Environment Variables

The Edge Function needs access to your Supabase URL and keys. These are automatically available in Supabase Edge Functions, but you can also set them explicitly:

```bash
supabase secrets set SUPABASE_URL=your-project-url
supabase secrets set SUPABASE_ANON_KEY=your-anon-key
```

**Note:** These are usually set automatically by Supabase, so you may not need to do this.

### Step 6: Install Dependencies

The Edge Function will automatically install dependencies from `requirements.txt` when deployed. For local testing:

```bash
cd supabase/functions/classifyDocument
pip install -r requirements.txt
```

### Step 7: Test the Function

You can test the function locally:

```bash
# Start local Supabase (optional, for local testing)
supabase start

# Test the function
supabase functions serve classifyDocument
```

Then test with curl:

```bash
curl -X POST http://localhost:54321/functions/v1/classifyDocument \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/test-image.jpg"
```

## Model Download

The Donut-base model will be automatically downloaded from HuggingFace on first use. This happens when the Edge Function is first invoked.

**Model Size:** ~1.5GB (downloaded once, cached)

**First Request:** May take 30-60 seconds while model downloads
**Subsequent Requests:** ~2-5 seconds per classification

## Flutter Integration

The Flutter app is already updated to use the classification service. The `DocumentClassifierService` automatically:

1. Sends image to the Edge Function
2. Receives classification result
3. Returns `DocumentClassificationResult` with:
   - `isAcademic`: Boolean indicating if document is academic
   - `score`: Number of academic keywords matched
   - `text`: Extracted text from document
   - `reason`: Human-readable reason for acceptance/rejection

## How It Works

1. **User uploads image** → Flutter app
2. **Flutter sends image** → Supabase Edge Function (`/classifyDocument`)
3. **Edge Function:**
   - Loads Donut-base model (cached after first load)
   - Converts image to RGB
   - Runs Donut inference to extract text
   - Checks extracted text for academic keywords
   - Returns classification result
4. **Flutter receives result:**
   - If `isAcademic == true` → Upload proceeds
   - If `isAcademic == false` → Upload rejected with reason

## Academic Keywords

The classifier looks for these keywords in the extracted text:

- grade, marks, certificate, university, college
- board, percentage, subject, credits, sgpa, cgpa
- register, usn, student, id card, exam
- semester, marksheet, degree, diploma, transcript
- academic, institute, education, result, score
- pass, fail, division, class, roll, admission

**Classification Rule:** Document is accepted if **≥ 2 keywords** are found.

## Troubleshooting

### Function Not Found (404)

- Ensure the function is deployed: `supabase functions deploy classifyDocument`
- Check function name matches exactly
- Verify you're using the correct project URL

### Model Loading Errors

- First request may timeout if model download takes too long
- Increase Edge Function timeout in Supabase Dashboard (Settings → Edge Functions)
- Check that HuggingFace is accessible from Supabase's servers

### Classification Always Returns False

- Check that images are clear and readable
- Verify academic keywords are present in the document
- Check Edge Function logs: `supabase functions logs classifyDocument`

### Dependencies Not Installing

- Ensure `requirements.txt` is in `supabase/functions/classifyDocument/`
- Check Python version (3.9+ required)
- Review Supabase Edge Functions logs for installation errors

## Performance

- **Model Load Time:** ~10-15 seconds (first request only, then cached)
- **Classification Time:** ~2-5 seconds per image
- **Model Size:** ~1.5GB (cached in Edge Function container)
- **Memory Usage:** ~2-3GB during inference

## Cost Considerations

- **HuggingFace Model:** Free (public model)
- **Supabase Edge Functions:** Free tier includes 500K invocations/month
- **Storage:** Model cached in function container (no additional storage cost)

## Alternative: Deploy Python Function Separately

If Supabase Edge Functions Python runtime is not available, you can deploy the function separately:

1. Deploy to a Python hosting service (Railway, Render, Fly.io)
2. Update `DocumentClassifierService` to use your custom URL
3. Ensure CORS is enabled for your Supabase project URL

## Files Created

- `supabase/functions/classifyDocument/index.py` - Main Edge Function
- `supabase/functions/classifyDocument/requirements.txt` - Python dependencies
- `lib/services/document_classifier_service.dart` - Flutter service
- `lib/screens/upload_screen.dart` - Updated to use classifier
- `lib/screens/camera_scan_screen.dart` - Updated to use classifier

## Next Steps

1. Deploy the Edge Function to Supabase
2. Test with a sample academic document
3. Test with a non-academic image (should be rejected)
4. Monitor Edge Function logs for any issues
5. Adjust academic keywords if needed (edit `ACADEMIC_KEYWORDS` in `index.py`)

## Support

For issues:
1. Check Supabase Edge Functions logs
2. Verify model is loading correctly
3. Test with curl to isolate Flutter vs. function issues
4. Review extracted text to see what Donut is detecting

