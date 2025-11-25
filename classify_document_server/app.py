"""
Alternative implementation using HuggingFace Inference API
This avoids OOM issues by using HuggingFace's hosted model instead of loading it locally.
FREE to use (with rate limits on free tier).
"""

import os
import json
import base64
from io import BytesIO
from typing import Dict, Any
import requests

from flask import Flask, request, jsonify
from flask_cors import CORS

# Use HuggingFace Hub's InferenceClient (handles endpoint routing automatically)
try:
    from huggingface_hub import InferenceClient
    HF_HUB_AVAILABLE = True
except ImportError:
    HF_HUB_AVAILABLE = False
    print("⚠️  Warning: huggingface_hub not available. Install with: pip install huggingface_hub")

app = Flask(__name__)
CORS(app, 
     resources={r"/*": {"origins": "*", "methods": ["GET", "POST", "OPTIONS"], "allow_headers": ["Content-Type", "Authorization"]}},
     supports_credentials=False)

# HuggingFace model name
# Using TrOCR (Text Recognition OCR) - available via Inference API and works well for printed documents
HF_MODEL_NAME = "microsoft/trocr-base-printed"
HF_API_TOKEN = os.environ.get("HF_API_TOKEN", None)  # Optional, but recommended for higher rate limits

# Initialize InferenceClient if available (handles endpoint routing automatically)
_inference_client = None
if HF_HUB_AVAILABLE:
    try:
        if HF_API_TOKEN:
            _inference_client = InferenceClient(model=HF_MODEL_NAME, token=HF_API_TOKEN)
            print("✅ HuggingFace InferenceClient initialized with token")
        else:
            _inference_client = InferenceClient(model=HF_MODEL_NAME)
            print("✅ HuggingFace InferenceClient initialized (no token)")
    except Exception as e:
        print(f"⚠️  Warning: Failed to initialize InferenceClient: {e}")
        _inference_client = None

# Academic keywords for classification
ACADEMIC_KEYWORDS = [
    "grade", "marks", "certificate", "university", "college",
    "board", "percentage", "subject", "credits", "sgpa",
    "cgpa", "register", "usn", "student", "id card", "exam",
    "semester", "marksheet", "degree", "diploma", "transcript",
    "academic", "institute", "education", "result", "score",
    "pass", "fail", "division", "class", "roll", "admission"
]


def classify_with_hf_api(image_bytes: bytes) -> Dict[str, Any]:
    """
    Classify document using HuggingFace Inference API.
    Uses InferenceClient if available, falls back to direct HTTP requests.
    """
    try:
        extracted_text = ""
        
        # Try using InferenceClient first (recommended - handles routing automatically)
        if _inference_client is not None:
            print("📤 Using HuggingFace InferenceClient...")
            try:
                # Try image-to-text (most common for document OCR)
                result = _inference_client.image_to_text(image=image_bytes)
                
                # Parse result
                if isinstance(result, list) and len(result) > 0:
                    # Result might be a list of dicts
                    result = result[0]
                
                if isinstance(result, dict):
                    extracted_text = result.get("generated_text", str(result)).lower()
                elif isinstance(result, str):
                    extracted_text = result.lower()
                else:
                    extracted_text = str(result).lower()
                    
                if extracted_text and len(extracted_text) > 10:
                    print(f"✅ InferenceClient extracted text: {extracted_text[:100]}...")
                else:
                    print(f"⚠️  InferenceClient returned empty/insufficient text, trying HTTP fallback")
                    extracted_text = ""
                
            except (StopIteration, ValueError, KeyError) as e:
                # Model not available via InferenceClient - this is expected for Donut
                print(f"⚠️  InferenceClient error (model may not be available): {e}")
                print("⚠️  Falling back to direct HTTP requests...")
                extracted_text = ""
            except Exception as e:
                print(f"⚠️  InferenceClient error: {e}, falling back to HTTP requests")
                import traceback
                traceback.print_exc()
                extracted_text = ""
        
        # Fallback to direct HTTP requests if InferenceClient not available or failed
        if not extracted_text:
            print("📤 Using direct HTTP request to HuggingFace API...")
            # Use router.huggingface.co (api-inference.huggingface.co is deprecated)
            # Router endpoint format: https://router.huggingface.co/{model_id}
            api_url = f"https://router.huggingface.co/{HF_MODEL_NAME}"
            
            # Prepare headers - router.huggingface.co requires token
            headers = {"Content-Type": "application/json"}
            if HF_API_TOKEN:
                headers["Authorization"] = f"Bearer {HF_API_TOKEN}"
            else:
                print("⚠️  Warning: No HF_API_TOKEN set. Router endpoint requires authentication!")
                return {
                    "is_academic": False,
                    "score": 0,
                    "text": "",
                    "reason": "HuggingFace API token (HF_API_TOKEN) is required for router.huggingface.co. Please add your token to Railway environment variables.",
                    "error": "Missing API token"
                }
            
            # Encode image to base64
            image_base64 = base64.b64encode(image_bytes).decode('utf-8')
            
            # Prepare request payload - Router endpoint expects base64 image in "inputs"
            payload = {
                "inputs": image_base64
            }
            
            print(f"📤 Calling {api_url}...")
            # Call HuggingFace Inference API
            response = requests.post(
                api_url,
                headers=headers,
                json=payload,
                timeout=60  # 60 second timeout
            )
            
            print(f"📥 Response status: {response.status_code}")
            print(f"📥 Response headers: {dict(response.headers)}")
            
            if response.status_code == 200:
                # Parse response
                try:
                    result = response.json()
                    print(f"📄 Response type: {type(result)}")
                    print(f"📄 Response preview: {str(result)[:200]}...")
                    
                    # Extract text from Donut output
                    # Donut returns generated text directly or in a dict
                    if isinstance(result, dict):
                        # Try different possible keys
                        extracted_text = (
                            result.get("generated_text", "") or
                            result.get("text", "") or
                            result.get("output", "") or
                            str(result.get("inputs", ""))
                        ).lower()
                        # If still empty, try to get the whole dict as string
                        if not extracted_text:
                            extracted_text = str(result).lower()
                    elif isinstance(result, str):
                        extracted_text = result.lower()
                    elif isinstance(result, list) and len(result) > 0:
                        # Result might be a list
                        first_item = result[0]
                        if isinstance(first_item, dict):
                            extracted_text = first_item.get("generated_text", str(first_item)).lower()
                        else:
                            extracted_text = str(first_item).lower()
                    else:
                        extracted_text = str(result).lower()
                    
                    print(f"✅ Extracted text length: {len(extracted_text)}")
                    if extracted_text:
                        print(f"✅ Extracted text preview: {extracted_text[:200]}...")
                        
                except json.JSONDecodeError as e:
                    print(f"❌ JSON decode error: {e}")
                    print(f"❌ Response text: {response.text[:500]}")
                    extracted_text = ""
            elif response.status_code == 503:
                # Model is loading (first request)
                return {
                    "is_academic": False,
                    "score": 0,
                    "text": "",
                    "reason": "HuggingFace model is loading. Please wait 30-60 seconds and try again.",
                    "error": "Model loading"
                }
            elif response.status_code == 410:
                # Deprecated endpoint
                error_text = response.text[:500]
                error_header = response.headers.get('X-Error-Message', '')
                return {
                    "is_academic": False,
                    "score": 0,
                    "text": "",
                    "reason": f"API endpoint deprecated (410): {error_header if error_header else error_text}. The endpoint is no longer supported.",
                    "error": "Deprecated endpoint"
                }
            elif response.status_code == 403:
                # Authentication/permission error
                error_text = response.text[:500]
                return {
                    "is_academic": False,
                    "score": 0,
                    "text": "",
                    "reason": f"Authentication error (403): Your HuggingFace token may not have sufficient permissions. Please check your token at https://huggingface.co/settings/tokens and ensure it has 'read' access. Error: {error_text}",
                    "error": "Authentication failed"
                }
            elif response.status_code == 404:
                # Model not found
                error_text = response.text[:500]
                return {
                    "is_academic": False,
                    "score": 0,
                    "text": "",
                    "reason": f"Model not found (404): The model '{HF_MODEL_NAME}' may not be available via Inference API. Error: {error_text}",
                    "error": "Model not found"
                }
            else:
                # Error response
                error_text = response.text[:200]
                return {
                    "is_academic": False,
                    "score": 0,
                    "text": "",
                    "reason": f"HuggingFace API error: {response.status_code} - {error_text}",
                    "error": f"API error: {response.status_code}"
                }
        
        # Clean up the text (remove any special tokens)
        if extracted_text:
            extracted_text = extracted_text.replace("<s_cord-v2>", "").replace("</s>", "").replace("<pad>", "").strip()
        
        # If we still don't have text, return error with more details
        if not extracted_text or len(extracted_text.strip()) < 5:
            error_details = []
            if _inference_client is None:
                error_details.append("InferenceClient not available")
            if not HF_API_TOKEN:
                error_details.append("No API token set")
            
            error_msg = "Failed to extract text from image."
            if error_details:
                error_msg += f" Issues: {', '.join(error_details)}."
            error_msg += " The model may not be available via Inference API, or the image format is not supported. Please check Railway logs for more details."
            
            return {
                "is_academic": False,
                "score": 0,
                "text": "",
                "reason": error_msg,
                "error": "No text extracted"
            }
        
        # Count academic keyword matches
        match_count = 0
        matched_keywords = []
        
        for keyword in ACADEMIC_KEYWORDS:
            if keyword.lower() in extracted_text:
                match_count += 1
                matched_keywords.append(keyword)
        
        is_academic = match_count >= 2
        
        if is_academic:
            reason = f"Document classified as academic (matched {match_count} keywords: {', '.join(matched_keywords[:5])})"
        else:
            reason = f"Only academic documents (marks cards, certificates, ID cards) are allowed. This image does not appear to be an academic document."
        
        return {
            "is_academic": is_academic,
            "score": match_count,
            "text": extracted_text[:500],
            "reason": reason,
            "matched_keywords": matched_keywords
        }
            
    except requests.exceptions.Timeout:
        return {
            "is_academic": False,
            "score": 0,
            "text": "",
            "reason": "Request timeout: HuggingFace API did not respond within 60 seconds.",
            "error": "Timeout"
        }
    except Exception as e:
        print(f"Classification error: {str(e)}")
        return {
            "is_academic": False,
            "score": 0,
            "text": "",
            "reason": f"Classification failed: {str(e)}",
            "error": str(e)
        }


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "HuggingFace Inference API wrapper",
        "model": HF_MODEL_NAME,
        "api_token_set": HF_API_TOKEN is not None,
        "inference_client_available": _inference_client is not None
    }), 200


@app.route('/classify', methods=['POST', 'OPTIONS'])
def classify():
    """Main classification endpoint"""
    if request.method == 'OPTIONS':
        response = jsonify({"message": "OK"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        return response, 200
    
    try:
        image_bytes = None
        
        if 'file' in request.files:
            file = request.files['file']
            image_bytes = file.read()
        elif request.is_json:
            data = request.get_json()
            if 'image' in data:
                image_data = data['image']
                if image_data.startswith("data:image"):
                    image_data = image_data.split(",")[1]
                image_bytes = base64.b64decode(image_data)
            elif 'file' in data:
                image_bytes = base64.b64decode(data['file'])
        elif request.data:
            try:
                image_bytes = base64.b64decode(request.data)
            except:
                image_bytes = request.data
        
        if image_bytes is None:
            return jsonify({
                "error": "No image data provided",
                "is_academic": False,
                "score": 0,
                "text": "",
                "reason": "No image data provided"
            }), 400
        
        if len(image_bytes) > 10 * 1024 * 1024:
            return jsonify({
                "error": "Image too large. Maximum size is 10MB.",
                "is_academic": False,
                "score": 0,
                "text": "",
                "reason": "Image too large"
            }), 400
        
        # Classify using HuggingFace API
        result = classify_with_hf_api(image_bytes)
        
        response = jsonify(result)
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        return response, 200
        
    except Exception as e:
        print(f"Handler error: {str(e)}")
        return jsonify({
            "error": "Internal server error",
            "message": str(e),
            "is_academic": False,
            "score": 0,
            "text": "",
            "reason": f"Server error: {str(e)}"
        }), 500


@app.route('/', methods=['GET'])
def index():
    """Root endpoint"""
    return jsonify({
        "service": "Document Classification API (HuggingFace Inference)",
        "model": HF_MODEL_NAME,
        "endpoints": {
            "POST /classify": "Classify an image as academic or non-academic",
            "GET /health": "Health check",
            "GET /": "This info"
        },
        "note": "This uses HuggingFace Inference API - no local model loading required!",
        "inference_client_available": _inference_client is not None
    })


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print("=" * 50)
    print("🚀 Starting HuggingFace Inference API wrapper")
    print("✅ No local model loading - avoids OOM issues!")
    print(f"📡 Server starting on port {port}...")
    print("=" * 50)
    app.run(host='0.0.0.0', port=port, debug=False)
