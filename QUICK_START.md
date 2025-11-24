# Quick Start Guide - Camera Document Scanning

## Installation

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure OTP Email** (if not done already)
   - Open `lib/services/otp_service.dart`
   - Uncomment and configure SMTP settings
   - See `OTP_EMAIL_CONFIGURATION.md` for details

## Key Changes

### ✅ Camera-Based Scanning
- Documents are now scanned using device camera
- No file picker - direct camera capture
- Real-time preview before capture

### ✅ File Type Validation
- **Accepts**: JPEG and PNG images only
- **Rejects**: Videos, PDFs, and other file types
- Uses file signature (magic numbers) for validation

### ✅ Academic Document Detection
- OCR extracts text from captured images
- Analyzes text for academic keywords
- Only academic documents are uploaded
- Non-academic documents are rejected with clear error message

## How It Works

1. User taps **"Scan Document"** button in category screen
2. Camera opens with live preview
3. User captures document image
4. System validates file type (must be JPEG/PNG)
5. OCR scans the image for text
6. System checks if document is academic
7. If academic → Uploads to Supabase
8. If not academic → Shows rejection message

## Testing

### Test on Physical Device
- Camera doesn't work on emulator
- Use a real Android/iOS device

### Test Scenarios
1. ✅ Capture academic document (marksheet) → Should accept
2. ✅ Capture non-academic image → Should reject
3. ✅ Try to upload video → Should reject (camera only captures images)

## Error Messages

- **Invalid file type**: "Invalid file type. Please capture an image (JPEG or PNG). Videos and other file types are not supported."
- **Not academic**: "Document rejected: This does not appear to be an academic document. Please capture only academic documents (marksheets, certificates, ID cards)."

## Permissions

Android permissions are already added to `AndroidManifest.xml`:
- Camera permission
- Storage permissions (for Android 12 and below)

iOS permissions are handled automatically by the camera package.

## Troubleshooting

### Camera Not Opening
- Check device has camera
- Verify permissions are granted
- Restart app if needed

### OCR Not Working
- Ensure image is clear and readable
- Check if text is visible in document
- Verify Google ML Kit is properly configured

### Dependencies Not Installing
- Run `flutter clean`
- Run `flutter pub get` again
- Check Flutter version compatibility

