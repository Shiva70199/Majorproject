"""
Supabase Edge Function: Document Classification using Donut-base
Classifies uploaded images as academic documents or non-academic content.

This function uses the HuggingFace Donut-base Vision Transformer model
to extract text from images and classify them as academic documents.
"""

import os
import json
import base64
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
            
            # Use CPU for inference (Supabase Edge Functions run on CPU)
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
        Dictionary with classification results:
        {
            "is_academic": bool,
            "score": int,
            "text": str,
            "reason": str
        }
    """
    try:
        # Load model and processor
        model, processor = load_model()
        
        # Convert bytes to PIL Image
        image = Image.open(BytesIO(image_bytes))
        
        # Convert to RGB if needed (handles RGBA, L, etc.)
        if image.mode != "RGB":
            image = image.convert("RGB")
        
        # Prepare image for Donut
        pixel_values = processor(image, return_tensors="pt").pixel_values
        
        # Run inference
        with torch.no_grad():
            # Generate text from image using Donut
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
            "text": extracted_text[:500],  # Limit text length
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


def parse_request(req) -> Optional[bytes]:
    """Parse image from request (handles multipart, base64, or raw bytes)"""
    try:
        # Try to get files from multipart form
        if hasattr(req, 'files') and req.files:
            file_data = req.files.get('file')
            if file_data:
                if hasattr(file_data, 'read'):
                    return file_data.read()
                elif isinstance(file_data, bytes):
                    return file_data
                elif isinstance(file_data, str):
                    return base64.b64decode(file_data)
        
        # Try JSON body with base64 image
        if hasattr(req, 'json') and req.json:
            body = req.json
            if isinstance(body, dict):
                if "image" in body:
                    image_data = body["image"]
                    if image_data.startswith("data:image"):
                        image_data = image_data.split(",")[1]
                    return base64.b64decode(image_data)
                elif "file" in body:
                    return base64.b64decode(body["file"])
        
        # Try raw body (base64 or bytes)
        if hasattr(req, 'body') and req.body:
            if isinstance(req.body, str):
                try:
                    return base64.b64decode(req.body)
                except:
                    return req.body.encode('utf-8')
            elif isinstance(req.body, bytes):
                return req.body
        
        return None
    except Exception as e:
        print(f"Error parsing request: {str(e)}")
        return None


def create_response(status_code: int, body: Dict[str, Any], error: Optional[str] = None) -> Dict[str, Any]:
    """Create standardized response"""
    if error:
        body = {"error": error, **body}
    
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
        "body": json.dumps(body),
    }


def main(req):
    """Main handler for Supabase Edge Function"""
    try:
        # Handle CORS preflight
        if hasattr(req, 'method') and req.method == "OPTIONS":
            return create_response(200, {"message": "OK"})
        
        # Only accept POST requests
        if not hasattr(req, 'method') or req.method != "POST":
            return create_response(405, {}, "Method not allowed. Use POST.")
        
        # Parse image from request
        image_bytes = parse_request(req)
        
        if image_bytes is None:
            return create_response(400, {}, "No image data provided. Send image as multipart file, base64 in JSON, or raw base64.")
        
        # Validate image size (max 10MB)
        if len(image_bytes) > 10 * 1024 * 1024:
            return create_response(400, {}, "Image too large. Maximum size is 10MB.")
        
        # Classify document
        result = classify_document(image_bytes)
        
        # Return result
        return create_response(200, result)
        
    except Exception as e:
        print(f"Handler error: {str(e)}")
        return create_response(500, {
            "is_academic": False,
            "score": 0,
            "text": "",
            "reason": f"Server error: {str(e)}"
        }, "Internal server error")


# For Supabase Edge Functions Python runtime
if __name__ == "__main__":
    # This will be called by Supabase's Python runtime
    # The runtime will pass the request object
    pass
