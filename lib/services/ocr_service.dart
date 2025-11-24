import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../models/document_category.dart';

// Platform-specific file operations - use stub for web
import 'dart:io' if (dart.library.html) 'io_stub.dart';

/// Result of document validation
class DocumentValidationResult {
  final bool isAcademic;
  final bool matchesCategory;
  final String extractedText;
  final String? failureReason;

  const DocumentValidationResult({
    required this.isAcademic,
    required this.matchesCategory,
    required this.extractedText,
    this.failureReason,
  });

  /// STRICT: Must be BOTH academic AND match the selected category
  bool get isValid {
    return isAcademic && matchesCategory;
  }
}

/// Face detection result (internal use only)
class FaceDetectionResult {
  final int faceCount;
  final bool hasFaces;

  const FaceDetectionResult({
    required this.faceCount,
    required this.hasFaces,
  });
}

/// Service class for STRICT academic document validation using ML Kit
/// Only accepts legitimate academic documents, rejects all random photos/selfies
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
    ),
  );

  /// Check if file is a valid image (JPEG or PNG only)
  bool isValidImageFile(Uint8List fileBytes, String? fileName) {
    if (fileBytes.length < 4) return false;

    // Check file signature (magic numbers)
    // JPEG: FF D8 FF
    if (fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (fileBytes[0] == 0x89 &&
        fileBytes[1] == 0x50 &&
        fileBytes[2] == 0x4E &&
        fileBytes[3] == 0x47) {
      return true;
    }

    // Also check file extension as fallback
    if (fileName != null) {
      final lowerName = fileName.toLowerCase();
      if (lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png')) {
        return true;
      }
    }

    return false;
  }

  /// Main validation method - STRICT validation
  Future<DocumentValidationResult> validateDocumentForCategory(
    Uint8List fileBytes,
    String fileName,
    String categoryId, {
    String? filePath,
  }) async {
    try {
      // Step 1: Check image file type
      if (!isValidImageFile(fileBytes, fileName)) {
        return const DocumentValidationResult(
          isAcademic: false,
          matchesCategory: false,
          extractedText: '',
          failureReason: 'Invalid file type. Only JPEG and PNG images are accepted.',
        );
      }

      // Step 2: Check image dimensions (reject too small images)
      final image = img.decodeImage(fileBytes);
      if (image == null) {
        return const DocumentValidationResult(
          isAcademic: false,
          matchesCategory: false,
          extractedText: '',
          failureReason: 'Unable to read image. Please upload a valid image file.',
        );
      }

      if (image.width < 400 || image.height < 400) {
        return const DocumentValidationResult(
          isAcademic: false,
          matchesCategory: false,
          extractedText: '',
          failureReason: 'Image too small. Please upload a higher resolution image (minimum 400x400 pixels).',
        );
      }

      // Step 3: Extract text using OCR
      final extractedText = await extractText(fileBytes, filePath: filePath);

      // Step 4: Detect faces
      final faceResult = await detectFaces(fileBytes, filePath: filePath);

      // Step 5: Apply strict rejection rules
      final rejectionReason = _applyRejectionRules(
        extractedText: extractedText,
        faceResult: faceResult,
        image: image,
        categoryId: categoryId,
      );

      if (rejectionReason != null) {
        return DocumentValidationResult(
          isAcademic: false,
          matchesCategory: false,
          extractedText: extractedText,
          failureReason: rejectionReason,
        );
      }

      // Step 6: Check if document looks academic
      final isAcademic = looksAcademic(extractedText);

      if (!isAcademic) {
        return DocumentValidationResult(
          isAcademic: false,
          matchesCategory: false,
          extractedText: extractedText,
          failureReason: 'Document rejected: This does not appear to be an academic document. Only academic documents (marksheets, certificates, ID cards) are accepted.',
        );
      }

      // Step 7: Check category match with STRICT rules
      final categoryMatches = matchesCategory(extractedText, categoryId);

      if (!categoryMatches) {
        final category = DocumentCategories.byId(categoryId);
        return DocumentValidationResult(
          isAcademic: true,
          matchesCategory: false,
          extractedText: extractedText,
          failureReason: 'Document rejected: This document does not match the selected category (${category?.label ?? categoryId}). Please upload the correct document type.',
        );
      }

      // All validations passed
      return DocumentValidationResult(
        isAcademic: isAcademic,
        matchesCategory: categoryMatches,
        extractedText: extractedText,
        failureReason: null,
      );
    } catch (e) {
      return DocumentValidationResult(
        isAcademic: false,
        matchesCategory: false,
        extractedText: '',
        failureReason: 'Error validating document: ${e.toString()}. Please try again.',
      );
    }
  }

  /// Extract text using OCR with multiple orientations
  Future<String> extractText(
    Uint8List imageBytes, {
    String? filePath,
  }) async {
    final List<String> results = [];

    try {
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return '';

      // Try all orientations (0°, 90°, 180°, 270°)
      final orientations = [0, 90, 180, 270];

      for (final rotation in orientations) {
        try {
          // Rotate image if needed
          img.Image orientedImage = originalImage;
          if (rotation != 0) {
            orientedImage = img.copyRotate(originalImage, angle: rotation);
          }

          // Preprocess for better OCR
          img.Image processed = img.grayscale(orientedImage);
          processed = img.adjustColor(
            processed,
            contrast: 1.4,
            brightness: 1.1,
          );

          // Resize if needed (ML Kit works best with 800-1600px width)
          if (processed.width < 800) {
            final scale = 800 / processed.width;
            processed = img.copyResize(
              processed,
              width: 800,
              height: (processed.height * scale).round(),
              interpolation: img.Interpolation.linear,
            );
          } else if (processed.width > 1600) {
            processed = img.copyResize(
              processed,
              width: 1600,
              interpolation: img.Interpolation.linear,
            );
          }

          // Use InputImage.fromBytes() for web, fromFilePath() for mobile
          InputImage inputImage;
          if (kIsWeb) {
            // For web: Convert processed image to RGBA bytes
            // ML Kit on web needs RGBA format, not JPEG bytes directly
            final rgbaBytes = Uint8List(processed.width * processed.height * 4);
            int idx = 0;
            for (var y = 0; y < processed.height; y++) {
              for (var x = 0; x < processed.width; x++) {
                final pixel = processed.getPixel(x, y);
                rgbaBytes[idx++] = pixel.r.toInt();
                rgbaBytes[idx++] = pixel.g.toInt();
                rgbaBytes[idx++] = pixel.b.toInt();
                rgbaBytes[idx++] = 255; // Alpha
              }
            }
            
            inputImage = InputImage.fromBytes(
              bytes: rgbaBytes,
              metadata: InputImageMetadata(
                size: Size(processed.width.toDouble(), processed.height.toDouble()),
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.bgra8888,
                bytesPerRow: processed.width * 4,
              ),
            );
          } else {
            // Mobile: Use file path for better performance
            if (!kIsWeb) {
              final processedBytes = img.encodeJpg(processed, quality: 95);
              // Split into two lines to avoid method chaining on Future
              final systemTempDir = Directory.systemTemp;
              final tempDir = await systemTempDir.createTemp('ocr_');
              final tempFile = File('${tempDir.path}/ocr_rot$rotation.jpg');
              await tempFile.writeAsBytes(processedBytes);
              
              inputImage = InputImage.fromFilePath(tempFile.path);
              
              // Cleanup temp file after processing (ignore errors)
              tempFile.delete().catchError((_) => tempFile);
              tempDir.delete(recursive: true).catchError((_) => tempDir);
            } else {
              // Fallback for web (shouldn't reach here due to outer if)
              continue;
            }
          }

          final recognizedText = await _textRecognizer.processImage(inputImage);

          if (recognizedText.text.trim().isNotEmpty) {
            results.add(recognizedText.text);
          }
        } catch (e) {
          // This orientation failed, try next
          continue;
        }
      }

      // Try original file path if available (mobile only)
      if (!kIsWeb && filePath != null && results.isEmpty) {
        try {
          final inputImage = InputImage.fromFilePath(filePath);
          final recognizedText = await _textRecognizer.processImage(inputImage);
          if (recognizedText.text.trim().isNotEmpty) {
            results.add(recognizedText.text);
          }
        } catch (e) {
          // Original file path failed
        }
      }

      // Return longest extracted text (most complete)
      if (results.isNotEmpty) {
        results.sort((a, b) => b.length.compareTo(a.length));
        return results.first;
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  /// Detect faces in image
  Future<FaceDetectionResult> detectFaces(
    Uint8List imageBytes, {
    String? filePath,
  }) async {
    try {
      InputImage inputImage;
      
      if (kIsWeb) {
        // Web: Decode image and convert to RGBA format
        final image = img.decodeImage(imageBytes);
        if (image == null) {
          return const FaceDetectionResult(faceCount: 0, hasFaces: false);
        }
        
        // Convert to RGBA bytes
        final rgbaBytes = Uint8List(image.width * image.height * 4);
        int idx = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            rgbaBytes[idx++] = pixel.r.toInt();
            rgbaBytes[idx++] = pixel.g.toInt();
            rgbaBytes[idx++] = pixel.b.toInt();
            rgbaBytes[idx++] = 255; // Alpha
          }
        }
        
        inputImage = InputImage.fromBytes(
          bytes: rgbaBytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.width * 4,
          ),
        );
      } else {
        // Mobile: Use file path for better performance
        if (!kIsWeb) {
          if (filePath != null) {
            inputImage = InputImage.fromFilePath(filePath);
          } else {
            final systemTempDir = Directory.systemTemp;
            final tempDir = await systemTempDir.createTemp('face_');
            final tempFile = File('${tempDir.path}/face_detection.jpg');
            await tempFile.writeAsBytes(imageBytes);
            
            inputImage = InputImage.fromFilePath(tempFile.path);
            
            // Cleanup temp files after processing (ignore errors)
            tempFile.delete().catchError((_) => tempFile);
            tempDir.delete(recursive: true).catchError((_) => tempDir);
          }
        } else {
          // Fallback for web (shouldn't reach here due to outer if)
          return const FaceDetectionResult(faceCount: 0, hasFaces: false);
        }
      }

      final faces = await _faceDetector.processImage(inputImage);
      
      return FaceDetectionResult(
        faceCount: faces.length,
        hasFaces: faces.isNotEmpty,
      );
    } catch (e) {
      // If face detection fails, assume no faces (be lenient for documents)
      return const FaceDetectionResult(
        faceCount: 0,
        hasFaces: false,
      );
    }
  }

  /// Apply STRICT rejection rules
  String? _applyRejectionRules({
    required String extractedText,
    required FaceDetectionResult faceResult,
    required img.Image image,
    required String categoryId,
  }) {
    // Rule 1: Reject empty OCR (unless ID card)
    final emptyOCRRule = rejectEmptyOCRRules(extractedText, categoryId);
    if (emptyOCRRule != null) return emptyOCRRule;

    // Rule 2: Reject selfies/group photos
    final selfieRule = rejectSelfieRules(
      extractedText: extractedText,
      faceResult: faceResult,
      image: image,
      categoryId: categoryId,
    );
    if (selfieRule != null) return selfieRule;

    // Rule 3: Reject non-academic documents
    final nonAcademicRule = rejectNonAcademicRules(extractedText, image);
    if (nonAcademicRule != null) return nonAcademicRule;

    return null; // All rules passed
  }

  /// Rule A: Reject empty OCR results (unless ID card with USN pattern)
  String? rejectEmptyOCRRules(String extractedText, String categoryId) {
    final textLength = extractedText.trim().length;

    // ID cards can have less text but must have USN pattern
    if (categoryId == 'college_id_card') {
      final hasUSNPattern = RegExp(r'\d{1,2}[A-Z]{2}\d{2}[A-Z]{2}\d{3}').hasMatch(extractedText) ||
                            extractedText.toLowerCase().contains('usn') ||
                            extractedText.toLowerCase().contains('id card') ||
                            extractedText.toLowerCase().contains('identity card');
      
      if (textLength < 20 && !hasUSNPattern) {
        return 'Document rejected: Unable to read document text. ID cards must contain readable text (name, USN, branch). Please ensure the image is clear and well-lit.';
      }
      // Allow ID cards with USN pattern even if text is short
      return null;
    }

    // All other documents must have at least 20 characters
    if (textLength < 20) {
      return 'Document rejected: Unable to read document text (extracted $textLength characters). Please ensure the image is clear, well-lit, correctly oriented, and contains readable text. Academic documents must have visible text.';
    }

    return null;
  }

  /// Rule B: Reject selfies and group photos
  String? rejectSelfieRules({
    required String extractedText,
    required FaceDetectionResult faceResult,
    required img.Image image,
    required String categoryId,
  }) {
    final aspectRatio = image.width / image.height;
    final textLength = extractedText.trim().length;

    // Rule B1: If face detected AND text < 40 characters → reject (selfie)
    if (faceResult.hasFaces && textLength < 40) {
      // Exception: ID cards can have faces but must have document text
      if (categoryId == 'college_id_card') {
        final hasDocumentText = extractedText.toLowerCase().contains('id card') ||
                                extractedText.toLowerCase().contains('identity card') ||
                                extractedText.toLowerCase().contains('institute') ||
                                extractedText.toLowerCase().contains('usn') ||
                                RegExp(r'\d{1,2}[A-Z]{2}\d{2}[A-Z]{2}\d{3}').hasMatch(extractedText);
        
        if (!hasDocumentText) {
          return 'Document rejected: This appears to be a selfie or personal photo, not an ID card. ID cards must contain visible document text (institute name, USN, branch).';
        }
        // ID card with face and document text - OK
        return null;
      }
      
      // Not an ID card - reject selfies
      return 'Document rejected: This appears to be a selfie or personal photo, not an academic document. Please upload only academic documents (marksheets, certificates, ID cards).';
    }

    // Rule B2: If more than one face detected → reject (group photo)
    if (faceResult.faceCount > 1) {
      return 'Document rejected: Multiple faces detected. Group photos are not accepted. Please upload only individual academic documents.';
    }

    // Rule B3: Reject very tall images with faces (full-body selfies)
    if (aspectRatio < 0.45 && faceResult.hasFaces) {
      return 'Document rejected: This appears to be a portrait photo or selfie, not an academic document. Please upload only academic documents (marksheets, certificates, ID cards).';
    }

    // Rule B4: Reject square images with faces (profile photos)
    final isSquare = aspectRatio >= 0.9 && aspectRatio <= 1.1;
    if (isSquare && faceResult.hasFaces && textLength < 30) {
      return 'Document rejected: This appears to be a profile photo, not an academic document. Please upload only academic documents (marksheets, certificates, ID cards).';
    }

    return null;
  }

  /// Rule C: Reject non-academic documents based on structure
  String? rejectNonAcademicRules(String extractedText, img.Image image) {
    final aspectRatio = image.width / image.height;

    // Rule C1: Reject if aspect ratio is not document-like (0.6-1.8)
    if (aspectRatio < 0.6 || aspectRatio > 1.8) {
      // Allow very portrait documents (ID cards can be 0.5-0.6)
      if (aspectRatio < 0.5 || aspectRatio > 2.0) {
        return 'Document rejected: Image dimensions do not match typical academic documents. Please upload a properly oriented document (not sideways or extremely stretched).';
      }
    }

    // Rule C2: Reject if no academic keywords at all
    final hasAcademicKeywords = extractedText.toLowerCase().contains('marksheet') ||
                                extractedText.toLowerCase().contains('grade card') ||
                                extractedText.toLowerCase().contains('certificate') ||
                                extractedText.toLowerCase().contains('university') ||
                                extractedText.toLowerCase().contains('college') ||
                                extractedText.toLowerCase().contains('institute') ||
                                extractedText.toLowerCase().contains('board') ||
                                extractedText.toLowerCase().contains('examination') ||
                                extractedText.toLowerCase().contains('semester') ||
                                extractedText.toLowerCase().contains('id card') ||
                                extractedText.toLowerCase().contains('identity card');

    if (!hasAcademicKeywords && extractedText.trim().length > 50) {
      return 'Document rejected: This does not appear to be an academic document. Please upload only academic documents (marksheets, certificates, ID cards).';
    }

    return null;
  }

  /// Check if document looks academic based on content
  bool looksAcademic(String extractedText) {
    if (extractedText.trim().isEmpty) return false;

    final lowerText = extractedText.toLowerCase();

    // Must have at least one strong academic indicator
    final academicIndicators = [
      'marksheet',
      'grade card',
      'certificate',
      'university',
      'college',
      'institute',
      'board',
      'examination',
      'semester',
      'id card',
      'identity card',
      'usn',
      'cgpa',
      'sgpa',
      'visvesvaraya',
      'sdm institute',
      'karnataka',
      'secondary education',
      'pre-university',
    ];

    int indicatorCount = 0;
    for (final indicator in academicIndicators) {
      if (lowerText.contains(indicator)) {
        indicatorCount++;
      }
    }

    // Require at least 2 academic indicators
    return indicatorCount >= 2;
  }

  /// Check if document matches category with STRICT keyword matching
  bool matchesCategory(String extractedText, String categoryId) {
    if (extractedText.trim().isEmpty) return false;

    final category = DocumentCategories.byId(categoryId);
    if (category == null) return false;

    final lowerText = extractedText.toLowerCase();

    // STRICT category-specific keyword matching
    switch (categoryId) {
      case 'tenth_marksheet':
        return lowerText.contains('sslc') ||
               lowerText.contains('kseeb') ||
               lowerText.contains('karnataka secondary education') ||
               lowerText.contains('secondary education examination board') ||
               lowerText.contains('10th') ||
               lowerText.contains('tenth');

      case 'twelfth_marksheet':
        return lowerText.contains('pre-university') ||
               lowerText.contains('pre university') ||
               lowerText.contains('department of pre-university education') ||
               lowerText.contains('puc') ||
               lowerText.contains('12th') ||
               lowerText.contains('twelfth');

      case 'ug_sem_1':
      case 'ug_sem_2':
      case 'ug_sem_3':
      case 'ug_sem_4':
      case 'ug_sem_5':
      case 'ug_sem_6':
      case 'ug_sem_7':
      case 'ug_sem_8':
        return lowerText.contains('vtu') ||
               lowerText.contains('visvesvaraya') ||
               lowerText.contains('grade card') ||
               lowerText.contains('sgpa') ||
               lowerText.contains('cgpa') ||
               lowerText.contains('technological university');

      case 'college_id_card':
        return lowerText.contains('identity card') ||
               lowerText.contains('id card') ||
               RegExp(r'\d{1,2}[A-Z]{2}\d{2}[A-Z]{2}\d{3}').hasMatch(extractedText) || // USN pattern
               lowerText.contains('usn') ||
               lowerText.contains('institute of technology') ||
               lowerText.contains('sdm institute');

      case 'ug_certificate':
        return lowerText.contains('certificate') ||
               lowerText.contains('awarded') ||
               lowerText.contains('this is to certify') ||
               lowerText.contains('degree') ||
               lowerText.contains('bachelor');

      case 'sports_certificate':
      case 'achievement_certificate':
        return lowerText.contains('certificate') ||
               lowerText.contains('awarded') ||
               lowerText.contains('this is to certify') ||
               lowerText.contains('achievement') ||
               lowerText.contains('sports');

      default:
        // For other categories, check category keywords
        for (final keyword in category.keywords) {
          if (lowerText.contains(keyword.toLowerCase())) {
            return true;
          }
        }
        return false;
    }
  }

  /// Cleanup resources
  void dispose() {
    _textRecognizer.close();
    _faceDetector.close();
  }
}
