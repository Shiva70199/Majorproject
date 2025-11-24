# Classify Document Edge Function

This Supabase Edge Function uses the HuggingFace Donut-base Vision Transformer model to classify uploaded images as academic documents or non-academic content.

## Important Note: Python Runtime

**Supabase Edge Functions primarily use Deno (TypeScript/JavaScript) runtime.** 

If Python runtime is not available in your Supabase project, you have two options:

### Option 1: Use Deno Runtime (Recommended)

Convert this to a Deno Edge Function. See `index.ts` (if provided) or use the Deno version.

### Option 2: Deploy Python Separately

Deploy the Python function to a separate service (Railway, Render, Fly.io) and update the Flutter service to use that URL.

## Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Test locally (requires Supabase local setup)
supabase functions serve classifyDocument
```

## Deployment

```bash
# Deploy to Supabase
supabase functions deploy classifyDocument
```

## Environment Variables

The function automatically uses:
- `SUPABASE_URL` (from Supabase environment)
- `SUPABASE_ANON_KEY` (from Supabase environment)

No manual configuration needed.

## Model Information

- **Model**: `naver-clova-ix/donut-base`
- **Size**: ~1.5GB (downloaded on first use)
- **First Load**: 30-60 seconds
- **Subsequent Requests**: 2-5 seconds

## Request Format

### Multipart Form Data (Recommended)
```bash
curl -X POST https://your-project.supabase.co/functions/v1/classifyDocument \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -F "file=@document.jpg"
```

### JSON with Base64
```json
{
  "image": "base64_encoded_image_string"
}
```

## Response Format

```json
{
  "is_academic": true,
  "score": 5,
  "text": "extracted text from document...",
  "reason": "Document classified as academic (matched 5 keywords: grade, marks, university, college, student)",
  "matched_keywords": ["grade", "marks", "university", "college", "student"]
}
```

## Academic Keywords

The classifier looks for these keywords (≥2 matches = academic):

- grade, marks, certificate, university, college
- board, percentage, subject, credits, sgpa, cgpa
- register, usn, student, id card, exam
- semester, marksheet, degree, diploma, transcript
- academic, institute, education, result, score
- pass, fail, division, class, roll, admission

