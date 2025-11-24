"""
Standalone Python Server for Document Classification
Deploy to Railway, Render, Fly.io, or any Python hosting service.

Uses HuggingFace Donut-base model to classify academic documents.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import os
from io import BytesIO
from typing import Dict, Any, Optional

try:
    from transformers import DonutProcessor, VisionEncoderDecoderModel
    from PIL import Image
    import torch
    DEPENDENCIES_AVAILABLE = True
except ImportError:
    DEPENDENCIES_AVAILABLE = False
    print("Warning: transformers, PIL, or torch not available")

app = Flask(__name__)
# Enable CORS for all routes with explicit configuration for Flutter Web
CORS(app, 
     resources={r"/*": {"origins": "*", "methods": ["GET", "POST", "OPTIONS"], "allow_headers": ["Content-Type", "Authorization"]}},
     supports_credentials=False)

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


def load_model():
    """Load Donut model and processor (lazy loading, cached globally)"""
    global _model, _processor
    
    if not DEPENDENCIES_AVAILABLE:
        raise ImportError("Required dependencies (transformers, PIL, torch) are not installed")
    
    if _model is None or _processor is None:
        print("Loading Donut-base model...")
        try:
            # Load processor and model from HuggingFace
            _processor = DonutProcessor.from_pretrained("naver-clova-ix/donut-base")
            _model = VisionEncoderDecoderModel.from_pretrained("naver-clova-ix/donut-base")
            
            # Set model to evaluation mode
            _model.eval()
            
            # Use CPU for inference
            _model.to("cpu")
            
            print("Donut-base model loaded successfully")
        except Exception as e:
            print(f"Error loading model: {str(e)}")
            raise
    
    return _model, _processor


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
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "model_loaded": _model is not None,
        "dependencies_available": DEPENDENCIES_AVAILABLE
    })


@app.route('/classify', methods=['POST', 'OPTIONS'])
def classify():
    """Main classification endpoint"""
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        return jsonify({"message": "OK"}), 200
    
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
        
        # Classify document
        result = classify_document(image_bytes)
        
        return jsonify(result), 200
        
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


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)

