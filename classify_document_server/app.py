"""
Standalone Python Server for Document Classification
Deploy to Railway, Render, Fly.io, or any Python hosting service.

Uses HuggingFace Donut-base model to classify academic documents.
"""

import os
import sys

# Create Flask app first (before any heavy imports)
from flask import Flask, request, jsonify
app = Flask(__name__)

# Add a minimal health endpoint immediately (before CORS and other imports)
@app.route('/health', methods=['GET'])
def health_check_minimal():
    """Minimal health check - works even if other imports fail"""
    try:
        return jsonify({
            "status": "ok",
            "message": "Server is running",
            "port": os.environ.get('PORT', 'not set')
        }), 200
    except Exception as e:
        # Even if jsonify fails, return plain text
        return f"OK - {str(e)}", 200

# Now import other dependencies (wrap in try-except to prevent startup failures)
try:
    from flask_cors import CORS
    # Enable CORS for all routes with explicit configuration for Flutter Web
    # NOTE: Don't recreate app - use the one created above with health endpoint
    CORS(app, 
         resources={r"/*": {"origins": "*", "methods": ["GET", "POST", "OPTIONS"], "allow_headers": ["Content-Type", "Authorization"]}},
         supports_credentials=False)
    print("✅ CORS enabled")
except ImportError as e:
    print(f"⚠️  Warning: flask-cors not available: {e}")
    # Add manual CORS headers if CORS library fails
    @app.after_request
    def add_cors_headers(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        return response
    print("✅ Manual CORS headers enabled")

import base64
import time
from io import BytesIO
from typing import Dict, Any, Optional
import gc

try:
    from transformers import DonutProcessor, VisionEncoderDecoderModel
    from PIL import Image
    import torch
    DEPENDENCIES_AVAILABLE = True
    print("✅ ML dependencies loaded")
except ImportError as e:
    DEPENDENCIES_AVAILABLE = False
    print(f"⚠️  Warning: transformers, PIL, or torch not available: {e}")

# Academic keywords for classification
ACADEMIC_KEYWORDS = [
    "grade", "marks", "certificate", "university", "college",
    "board", "percentage", "subject", "credits", "sgpa",
    "cgpa", "register", "usn", "student", "id card", "exam",
    "semester", "marksheet", "degree", "diploma", "transcript",
    "academic", "institute", "education", "result", "score",
    "pass", "fail", "division", "class", "roll", "admission"
]

# Global model and processor (loaded once, reused across requests)
_model = None
_processor = None
_model_loading = False
_model_load_error = None


def load_model():
    """Load Donut model and processor (lazy loading, cached globally)"""
    global _model, _processor, _model_loading, _model_load_error
    
    if not DEPENDENCIES_AVAILABLE:
        raise ImportError("Required dependencies (transformers, PIL, torch) are not installed")
    
    # If model is already loaded, return it
    if _model is not None and _processor is not None:
        return _model, _processor
    
    # If model is currently loading, wait for it
    if _model_loading:
        print("⏳ Model is currently loading, waiting...")
        max_wait = 120  # Wait up to 2 minutes
        waited = 0
        while _model_loading and waited < max_wait:
            time.sleep(2)
            waited += 2
            if _model is not None and _processor is not None:
                return _model, _processor
        
        if _model_load_error:
            raise Exception(f"Model loading failed: {_model_load_error}")
        if _model is None or _processor is None:
            raise Exception("Model loading timeout")
    
    # Start loading the model
    _model_loading = True
    _model_load_error = None
    
    print("=" * 50)
    print("Loading Donut-base model from HuggingFace...")
    print("⚠️  WARNING: This requires ~2-3GB RAM. Railway free tier may not have enough.")
    print("This may take 30-60 seconds...")
    print("=" * 50)
    
    # Force garbage collection before loading to free up memory
    gc.collect()
    
    try:
        # Load processor first (smaller, less memory)
        print("📦 Loading processor...")
        _processor = DonutProcessor.from_pretrained("naver-clova-ix/donut-base")
        gc.collect()  # Free memory after processor load
        
        # Load model (this is the memory-intensive part)
        print("📦 Loading model (this may cause OOM on Railway free tier)...")
        _model = VisionEncoderDecoderModel.from_pretrained("naver-clova-ix/donut-base")
        
        # Set model to evaluation mode
        _model.eval()
        
        # Use CPU for inference
        _model.to("cpu")
        
        # Force garbage collection after loading
        gc.collect()
        
        print("=" * 50)
        print("✅ Donut-base model loaded successfully!")
        print("=" * 50)
        _model_loading = False
    except Exception as e:
        _model_loading = False
        _model_load_error = str(e)
        print(f"❌ Error loading model: {str(e)}")
        if "out of memory" in str(e).lower() or "oom" in str(e).lower():
            print("💡 SOLUTION: Railway free tier doesn't have enough RAM (needs ~2-3GB).")
            print("   Options:")
            print("   1. Upgrade Railway plan (not free)")
            print("   2. Use HuggingFace Inference API (free tier available)")
            print("   3. Deploy to Render/Fly.io with more RAM")
        gc.collect()  # Clean up on error
        raise
    
    return _model, _processor


# Background pre-loading disabled to prevent OOM on Railway free tier
# Model will be loaded lazily on first request instead


def classify_document(image_bytes: bytes) -> Dict[str, Any]:
    """
    Classify document using Donut-base model.
    
    Args:
        image_bytes: Raw image bytes (JPEG/PNG)
    
    Returns:
        Dictionary with classification results
    """
    try:
        # Load model and processor
        model, processor = load_model()
        
        # Convert bytes to PIL Image
        image = Image.open(BytesIO(image_bytes))
        
        # Convert to RGB if needed
        if image.mode != "RGB":
            image = image.convert("RGB")
        
        # Prepare image for Donut
        pixel_values = processor(image, return_tensors="pt").pixel_values
        
        # Run inference
        with torch.no_grad():
            decoder_input_ids = processor.tokenizer(
                "<s_cord-v2>",
                add_special_tokens=False,
                return_tensors="pt"
            ).input_ids
            
            outputs = model.generate(
                pixel_values,
                decoder_input_ids=decoder_input_ids,
                max_length=model.decoder.config.max_position_embeddings,
                early_stopping=True,
                pad_token_id=processor.tokenizer.pad_token_id,
                eos_token_id=processor.tokenizer.eos_token_id,
                use_cache=True,
                num_beams=1,
                bad_words_ids=[[processor.tokenizer.unk_token_id]],
            )
            
            # Decode generated text
            sequence = processor.batch_decode(outputs)[0]
            sequence = sequence.replace(processor.tokenizer.eos_token, "").replace(processor.tokenizer.pad_token, "")
            sequence = sequence.replace("<s_cord-v2>", "").replace("</s>", "").strip()
            
            extracted_text = sequence.lower()
        
        # Count academic keyword matches
        match_count = 0
        matched_keywords = []
        
        for keyword in ACADEMIC_KEYWORDS:
            if keyword.lower() in extracted_text:
                match_count += 1
                matched_keywords.append(keyword)
        
        # Classification: >= 2 matches = academic document
        is_academic = match_count >= 2
        
        # Generate reason
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
def health_check_detailed():
    """Detailed health check endpoint - returns model status"""
    try:
        model_loaded = _model is not None and _processor is not None
        return jsonify({
            "status": "healthy" if DEPENDENCIES_AVAILABLE else "unhealthy",
            "model_loaded": model_loaded,
            "model_loading": _model_loading,
            "model_load_error": _model_load_error,
            "dependencies_available": DEPENDENCIES_AVAILABLE
        }), 200
    except Exception as e:
        # Always return 200 even on error, so Railway doesn't kill the container
        return jsonify({
            "status": "error",
            "error": str(e),
            "dependencies_available": DEPENDENCIES_AVAILABLE if 'DEPENDENCIES_AVAILABLE' in globals() else False
        }), 200


@app.route('/classify', methods=['POST', 'OPTIONS'])
def classify():
    """Main classification endpoint"""
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({"message": "OK"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        response.headers.add('Access-Control-Max-Age', '3600')
        return response, 200
    
    try:
        # Get image from request
        image_bytes = None
        
        # Try multipart form data
        if 'file' in request.files:
            file = request.files['file']
            image_bytes = file.read()
        
        # Try JSON with base64 image
        elif request.is_json:
            data = request.get_json()
            if 'image' in data:
                image_data = data['image']
                if image_data.startswith("data:image"):
                    image_data = image_data.split(",")[1]
                image_bytes = base64.b64decode(image_data)
            elif 'file' in data:
                image_bytes = base64.b64decode(data['file'])
        
        # Try raw base64 in body
        elif request.data:
            try:
                image_bytes = base64.b64decode(request.data)
            except:
                image_bytes = request.data
        
        if image_bytes is None:
            return jsonify({
                "error": "No image data provided. Send image as multipart file, base64 in JSON, or raw base64.",
                "is_academic": False,
                "score": 0,
                "text": "",
                "reason": "No image data provided"
            }), 400
        
        # Validate image size (max 10MB)
        if len(image_bytes) > 10 * 1024 * 1024:
            return jsonify({
                "error": "Image too large. Maximum size is 10MB.",
                "is_academic": False,
                "score": 0,
                "text": "",
                "reason": "Image too large"
            }), 400
        
        # Check if model needs to be loaded (first request)
        model_needs_loading = _model is None and not _model_loading
        if model_needs_loading:
            print("⚠️  Model not loaded yet. Loading now (this may take 30-60s)...")
            print("⚠️  WARNING: This requires ~2-3GB RAM. Railway free tier may fail with OOM.")
        elif _model_loading:
            print("⏳ Model is currently loading, waiting...")
        
        # Classify document
        result = classify_document(image_bytes)
        
        # Create response with explicit CORS headers for Flutter Web
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
    """Root endpoint with API info"""
    return jsonify({
        "service": "Document Classification API",
        "model": "naver-clova-ix/donut-base",
        "endpoints": {
            "POST /classify": "Classify an image as academic or non-academic",
            "GET /health": "Health check",
            "GET /": "This info"
        },
        "usage": {
            "multipart": "POST /classify with 'file' field",
            "json": "POST /classify with JSON body: {\"image\": \"base64_string\"}",
            "base64": "POST /classify with raw base64 in body"
        }
    })


# Background pre-loading disabled to prevent OOM on Railway free tier
# Model will be loaded lazily on first request
# Note: When using gunicorn, this code runs when the module is imported
try:
    print("=" * 50)
    print("🚀 Document Classification Server module loaded")
    print(f"📡 PORT env var: {os.environ.get('PORT', 'NOT SET')}")
    print("⚠️  Model will load on first request (may take 30-60s)")
    print("⚠️  Railway free tier may not have enough RAM (needs ~2-3GB)")
    print("=" * 50)
except Exception as e:
    print(f"Error during module initialization: {e}")
    import traceback
    traceback.print_exc()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"📡 Server starting on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=False)

