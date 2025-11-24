# Camera Scan Implementation Guide

## Overview
The app now uses camera scanning instead of file picker for document upload. Documents are scanned using OCR to verify they are academic before upload.

## Features Implemented

### 1. Camera-Based Document Scanning ✅
- **Camera Integration**: Uses device camera to capture document images
- **Real-time Preview**: Shows live camera preview before capture
- **Image Capture**: Captures high-resolution images for scanning

### 2. File Type Validation ✅
- **Image Only**: Only accepts JPEG and PNG images
- **Rejects Videos**: Videos and other file types are rejected
- **Rejects PDFs**: PDF files are not supported (camera only captures images)
- **Magic Number Detection**: Uses file signature (magic numbers) to validate file types
  - JPEG: `FF D8 FF`
  - PNG: `89 50 4E 47`

### 3. OCR Document Classification ✅
- **Text Extraction**: Uses Google ML Kit to extract text from captured images
- **Academic Detection**: Analyzes text for academic keywords
- **Automatic Rejection**: Non-academic documents are rejected with error message
- **Keyword Matching**: Detects keywords like:
  - marksheet, certificate, degree, diploma
  - semester, academic, university, college
  - student, roll number, registration number
  - 10th, 12th, UG, PG, etc.

### 4. Upload Flow ✅
- **Scan First**: Document is scanned before upload
- **Validation**: File type and academic content are validated
- **Upload on Success**: Only academic documents are uploaded
- **Error Messages**: Clear error messages for rejected documents

## Implementation Details

### Files Created/Modified

1. **`lib/screens/camera_scan_screen.dart`** (NEW)
   - Camera preview and capture functionality
   - OCR scanning integration
   - Upload workflow

2. **`lib/services/ocr_service.dart`** (MODIFIED)
   - Added `isValidImageFile()` method for file type validation
   - Removed PDF support (camera only captures images)
   - Enhanced error handling

3. **`lib/screens/category_screen.dart`** (MODIFIED)
   - Changed upload button to camera scan button
   - Updated UI text to reflect camera scanning

4. **`pubspec.yaml`** (MODIFIED)
   - Added `camera: ^0.11.0+2` for camera functionality
   - Added `image_picker: ^1.1.2` (for future use)
   - Removed `pdf_text: ^1.0.0` (not needed for camera scanning)
   - Added `file: ^7.0.0` for file operations

5. **`android/app/src/main/AndroidManifest.xml`** (MODIFIED)
   - Added camera permissions
   - Added storage permissions (for saving captured images)

## Usage Flow

1. **User taps "Scan Document" button** in category screen
2. **Camera opens** showing live preview
3. **User captures document** by tapping "Capture Document" button
4. **Image is captured** and displayed
5. **User taps "Scan & Upload"** button
6. **File type validation** - checks if it's JPEG/PNG
7. **OCR scanning** - extracts text from image
8. **Academic classification** - analyzes text for academic keywords
9. **Upload or Reject**:
   - If academic: Document is uploaded to Supabase
   - If not academic: Error message shown, document rejected

## Error Messages

### File Type Errors
- **Invalid file type**: "Invalid file type. Please capture an image (JPEG or PNG). Videos and other file types are not supported."

### Academic Document Errors
- **Not academic**: "Document rejected: This does not appear to be an academic document. Please capture only academic documents (marksheets, certificates, ID cards)."

## Permissions Required

### Android
- `CAMERA` - Required for camera access
- `WRITE_EXTERNAL_STORAGE` - For saving captured images (Android 12 and below)
- `READ_EXTERNAL_STORAGE` - For reading captured images (Android 12 and below)

### iOS
- Camera permission (handled automatically by camera package)
- Photo library permission (if needed)

## Testing Checklist

- [ ] Install dependencies: `flutter pub get`
- [ ] Test camera opens on device
- [ ] Test image capture
- [ ] Test file type validation (try capturing video - should reject)
- [ ] Test academic document scanning (marksheet - should accept)
- [ ] Test non-academic document scanning (random image - should reject)
- [ ] Test upload flow for accepted documents
- [ ] Test error messages for rejected documents

## Troubleshooting

### Camera Not Opening
- Check camera permissions in device settings
- Verify `AndroidManifest.xml` has camera permissions
- Ensure device has a camera

### OCR Not Working
- Check Google ML Kit is properly configured
- Verify image is clear and readable
- Check if text is visible in captured image

### File Type Validation Failing
- Ensure captured image is JPEG or PNG
- Check file signature detection logic
- Verify image was captured correctly

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Test on physical device (camera doesn't work on emulator)
3. Fine-tune OCR keyword matching if needed
4. Add image quality checks (blur detection, brightness, etc.)
5. Consider adding document edge detection for better scanning

