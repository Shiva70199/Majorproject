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

app = Flask(__name__)
CORS(app, 
     resources={r"/*": {"origins": "*", "methods": ["GET", "POST", "OPTIONS"], "allow_headers": ["Content-Type", "Authorization"]}},
     supports_credentials=False)

# HuggingFace Inference API endpoint
HF_API_URL = "https://api-inference.huggingface.co/models/naver-clova-ix/donut-base"
HF_API_TOKEN = os.environ.get("HF_API_TOKEN", None)  # Optional, but recommended for higher rate limits

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
    This avoids loading the model locally, preventing OOM issues.
    """
    try:
        # Prepare headers
        headers = {"Content-Type": "application/json"}
        if HF_API_TOKEN:
            headers["Authorization"] = f"Bearer {HF_API_TOKEN}"
        
        # Encode image to base64
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # Prepare request payload
        payload = {
            "inputs": image_base64
        }
        
        # Call HuggingFace Inference API
        print("📤 Calling HuggingFace Inference API...")
        response = requests.post(
            HF_API_URL,
            headers=headers,
            json=payload,
            timeout=60  # 60 second timeout
        )
        
        if response.status_code == 200:
            # Parse response
            result = response.json()
            
            # Extract text from Donut output
            # HuggingFace API returns the generated text directly
            if isinstance(result, dict):
                extracted_text = result.get("generated_text", "").lower()
            elif isinstance(result, str):
                extracted_text = result.lower()
            else:
                extracted_text = str(result).lower()
            
            # Clean up the text
            extracted_text = extracted_text.replace("<s_cord-v2>", "").replace("</s>", "").strip()
            
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
        elif response.status_code == 503:
            # Model is loading (first request)
            return {
                "is_academic": False,
                "score": 0,
                "text": "",
                "reason": "HuggingFace model is loading. Please wait 30-60 seconds and try again.",
                "error": "Model loading"
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
        "model": "naver-clova-ix/donut-base",
        "api_token_set": HF_API_TOKEN is not None
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
        "model": "naver-clova-ix/donut-base",
        "endpoints": {
            "POST /classify": "Classify an image as academic or non-academic",
            "GET /health": "Health check",
            "GET /": "This info"
        },
        "note": "This uses HuggingFace Inference API - no local model loading required!"
    })


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print("=" * 50)
    print("🚀 Starting HuggingFace Inference API wrapper")
    print("✅ No local model loading - avoids OOM issues!")
    print(f"📡 Server starting on port {port}...")
    print("=" * 50)
    app.run(host='0.0.0.0', port=port, debug=False)

