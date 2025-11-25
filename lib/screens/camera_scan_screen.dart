import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/document_category.dart';
import '../services/firebase_auth_service.dart';
import '../services/ocr_service.dart';
import '../services/document_classifier.dart';
import '../services/supa_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Camera screen for scanning documents
/// Captures image, scans with OCR, and uploads if academic
class CameraScanScreen extends StatefulWidget {
  final String categoryId;

  const CameraScanScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isUploading = false;
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes;
  String? _scanResult;

  // Grid overlay state
  Offset _gridTopLeft = const Offset(50, 100);
  Offset _gridTopRight = const Offset(350, 100);
  Offset _gridBottomLeft = const Offset(50, 600);
  Offset _gridBottomRight = const Offset(350, 600);
  Offset? _draggingCorner;
  bool _isGridAligned = false;

  final _firebaseAuth = FirebaseAuthService();
  final _supaService = SupaService();
  final _ocrService = OCRService(); // Only for file type validation
  final _classifier = DocumentClassifier();

  DocumentCategoryDefinition get _category =>
      DocumentCategories.byId(widget.categoryId) ??
      DocumentCategoryDefinition(
        id: widget.categoryId,
        label: widget.categoryId,
        description: widget.categoryId,
        icon: Icons.description,
        keywords: const [],
        group: DocumentCategories.academicGroup,
      );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No camera available on this device'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Use back camera (usually better for document scanning)
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _initializeGrid();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// Capture image from camera
  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();
      setState(() {
        _capturedImage = image;
        _capturedImageBytes = imageBytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scan and upload document
  Future<void> _scanAndUpload() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isScanning = true);

    try {
      final userId = _firebaseAuth.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use already-loaded image bytes (more efficient and works on web)
      final imageBytes = _capturedImageBytes ?? await _capturedImage!.readAsBytes();

      // Validate file type - reject videos and non-images
      if (!_ocrService.isValidImageFile(imageBytes, _capturedImage!.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid file type. Please capture an image (JPEG or PNG). Videos and other file types are not supported.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isScanning = false);
        return;
      }

      // Classify document using TFLite model (offline)
      final classificationResult = await _classifier.classify(imageBytes);

      if (!classificationResult.isAcademic) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only academic documents are allowed. (Confidence: ${(classificationResult.confidence * 100).toStringAsFixed(1)}%)',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _isScanning = false;
          _scanResult = 'Rejected: Not an academic document';
        });
        return;
      }

      setState(() {
        _isScanning = false;
        _isUploading = true;
        _scanResult = 'Accepted: Academic document detected';
      });

      // Determine content type
      final extension = _capturedImage!.path.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);

      // Upload file to Supabase Storage
      String filePath;
      try {
        filePath = await _supaService.uploadFile(
          userId: userId,
          category: widget.categoryId,
          fileName: _capturedImage!.name,
          fileBytes: imageBytes,
          contentType: contentType,
        );
      } catch (storageError) {
        throw Exception(
            'Storage upload failed: $storageError. Please check storage bucket policies in Supabase Dashboard.');
      }

      // Insert document record directly into documents table (no verification needed)
      try {
        await _supaService.insertDocument(
          userId: userId,
          category: widget.categoryId,
          fileName: _capturedImage!.name,
          filePath: filePath,
          fileSize: imageBytes.length,
          uploaderEmail: _firebaseAuth.currentUserEmail,
        );
      } catch (dbError) {
        // If database insert fails, try to clean up the uploaded file from storage
        try {
          final supabase = Supabase.instance.client;
          await supabase.storage.from('documents').remove([filePath]);
        } catch (_) {
          // Ignore cleanup errors
        }
        throw Exception(
            'Failed to save document: $dbError. Please check database connection.');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document scanned and uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isScanning = false;
        });
      }
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  /// Retake photo
  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _scanResult = null;
    });
  }

  /// Build image widget that works on both web and mobile
  Widget _buildImageWidget() {
    if (_capturedImageBytes == null) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      // Use Image.memory for web
      return Image.memory(
        _capturedImageBytes!,
        fit: BoxFit.contain,
      );
    } else {
      // Use Image.file for mobile/desktop
      return Image.file(
        File(_capturedImage!.path),
        fit: BoxFit.contain,
      );
    }
  }

  /// Initialize grid position based on screen size
  void _initializeGrid() {
    // Grid will be initialized in build method using MediaQuery
  }

  /// Handle pan start for grid corner dragging
  void _onPanStart(DragStartDetails details) {
    final touchPoint = details.localPosition;
    const cornerRadius = 30.0;

    // Check which corner is being dragged
    if ((touchPoint - _gridTopLeft).distance < cornerRadius) {
      _draggingCorner = _gridTopLeft;
    } else if ((touchPoint - _gridTopRight).distance < cornerRadius) {
      _draggingCorner = _gridTopRight;
    } else if ((touchPoint - _gridBottomLeft).distance < cornerRadius) {
      _draggingCorner = _gridBottomLeft;
    } else if ((touchPoint - _gridBottomRight).distance < cornerRadius) {
      _draggingCorner = _gridBottomRight;
    }
  }

  /// Handle pan update for grid corner dragging
  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggingCorner == null) return;

    final delta = details.delta;
    final newPosition = _draggingCorner! + delta;

    // Constrain to screen bounds
    final screenSize = MediaQuery.of(context).size;
    final constrainedX = newPosition.dx.clamp(0.0, screenSize.width);
    final constrainedY = newPosition.dy.clamp(0.0, screenSize.height);

    setState(() {
      if (_draggingCorner == _gridTopLeft) {
        _gridTopLeft = Offset(constrainedX, constrainedY);
      } else if (_draggingCorner == _gridTopRight) {
        _gridTopRight = Offset(constrainedX, constrainedY);
      } else if (_draggingCorner == _gridBottomLeft) {
        _gridBottomLeft = Offset(constrainedX, constrainedY);
      } else if (_draggingCorner == _gridBottomRight) {
        _gridBottomRight = Offset(constrainedX, constrainedY);
      }
      _checkGridAlignment();
    });
  }

  /// Handle pan end for grid corner dragging
  void _onPanEnd(DragEndDetails details) {
    _draggingCorner = null;
  }

  /// Check if grid is properly aligned (roughly rectangular)
  void _checkGridAlignment() {
    // Calculate angles at each corner
    final topLeftAngle = _calculateAngle(_gridTopRight, _gridTopLeft, _gridBottomLeft);
    final topRightAngle = _calculateAngle(_gridTopLeft, _gridTopRight, _gridBottomRight);
    final bottomLeftAngle = _calculateAngle(_gridTopLeft, _gridBottomLeft, _gridBottomRight);
    final bottomRightAngle = _calculateAngle(_gridTopRight, _gridBottomRight, _gridBottomLeft);

    // Check if angles are close to 90 degrees (within 15 degrees)
    const tolerance = 0.26; // ~15 degrees in radians
    final isAligned = (topLeftAngle - 1.57).abs() < tolerance &&
        (topRightAngle - 1.57).abs() < tolerance &&
        (bottomLeftAngle - 1.57).abs() < tolerance &&
        (bottomRightAngle - 1.57).abs() < tolerance;

    if (_isGridAligned != isAligned) {
      setState(() {
        _isGridAligned = isAligned;
      });
    }
  }

  /// Calculate angle between three points
  double _calculateAngle(Offset p1, Offset p2, Offset p3) {
    final v1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);

    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    final mag2 = math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);

    if (mag1 == 0 || mag2 == 0) return 0;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle);
  }

  /// Build interactive grid overlay
  Widget _buildGridOverlay() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: InteractiveGridPainter(
          topLeft: _gridTopLeft,
          topRight: _gridTopRight,
          bottomLeft: _gridBottomLeft,
          bottomRight: _gridBottomRight,
          isAligned: _isGridAligned,
        ),
        child: Container(),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize grid on first build if not already set
    if (_gridTopLeft == const Offset(50, 100)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final size = MediaQuery.of(context).size;
          const margin = 40.0;
          final width = size.width - (margin * 2);
          final height = width * 1.414; // A4 aspect ratio (sqrt(2))
          
          setState(() {
            _gridTopLeft = Offset(margin, (size.height - height) / 2);
            _gridTopRight = Offset(margin + width, (size.height - height) / 2);
            _gridBottomLeft = Offset(margin, (size.height - height) / 2 + height);
            _gridBottomRight = Offset(margin + width, (size.height - height) / 2 + height);
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan ${_category.label} Document'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
      ),
      body: _isInitialized && _controller != null
          ? Column(
              children: [
                // Camera preview or captured image
                Expanded(
                  child: Stack(
                    children: [
                      _capturedImage == null
                          ? CameraPreview(_controller!)
                          : _buildImageWidget(),
                      // Interactive grid overlay (only show on camera preview)
                      if (_capturedImage == null)
                        _buildGridOverlay(),
                    ],
                  ),
                ),

                // Scan result message
                if (_scanResult != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: _scanResult!.contains('Rejected')
                        ? Colors.red[100]
                        : Colors.green[100],
                    child: Row(
                      children: [
                        Icon(
                          _scanResult!.contains('Rejected')
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: _scanResult!.contains('Rejected')
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scanResult!,
                            style: TextStyle(
                              color: _scanResult!.contains('Rejected')
                                  ? Colors.red[900]
                                  : Colors.green[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Control buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.black87,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_capturedImage == null)
                        // Capture button with alignment indicator
                        Column(
                          children: [
                            if (_isGridAligned)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(51), // 0.2 opacity
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Grid aligned! Ready to capture',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: _isScanning ? null : _captureImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Capture Document'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                backgroundColor: _isGridAligned ? Colors.green[600] : Colors.blue[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Drag corners to align with document',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        // Action buttons for captured image
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Retake button
                            ElevatedButton.icon(
                              onPressed: _isScanning || _isUploading
                                  ? null
                                  : _retakePhoto,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retake'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            // Scan & Upload button
                            ElevatedButton.icon(
                              onPressed: _isScanning || _isUploading
                                  ? null
                                  : _scanAndUpload,
                              icon: _isScanning || _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(
                                _isScanning
                                    ? 'Scanning...'
                                    : _isUploading
                                        ? 'Uploading...'
                                        : 'Scan & Upload',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

/// Custom painter for drawing interactive grid overlay
class InteractiveGridPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final bool isAligned;

  InteractiveGridPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent overlay outside grid
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final gridPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    
    overlayPath.addPath(gridPath, Offset.zero);
    overlayPath.fillType = PathFillType.evenOdd;
    
    final overlayPaint = Paint()
      ..color = Colors.black.withAlpha(128) // 0.5 opacity
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw grid border
    final borderPaint = Paint()
      ..color = isAligned ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final gridPath2 = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(gridPath2, borderPaint);

    // Draw grid lines (3x3 grid)
    final gridLinePaint = Paint()
      ..color = (isAligned ? Colors.green : Colors.white).withAlpha(77) // 0.3 opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Vertical lines
    for (var i = 1; i < 3; i++) {
      final t = i / 3;
      final top = Offset(
        topLeft.dx + (topRight.dx - topLeft.dx) * t,
        topLeft.dy + (topRight.dy - topLeft.dy) * t,
      );
      final bottom = Offset(
        bottomLeft.dx + (bottomRight.dx - bottomLeft.dx) * t,
        bottomLeft.dy + (bottomRight.dy - bottomLeft.dy) * t,
      );
      canvas.drawLine(top, bottom, gridLinePaint);
    }

    // Horizontal lines
    for (var i = 1; i < 3; i++) {
      final t = i / 3;
      final left = Offset(
        topLeft.dx + (bottomLeft.dx - topLeft.dx) * t,
        topLeft.dy + (bottomLeft.dy - topLeft.dy) * t,
      );
      final right = Offset(
        topRight.dx + (bottomRight.dx - topRight.dx) * t,
        topRight.dy + (bottomRight.dy - topRight.dy) * t,
      );
      canvas.drawLine(left, right, gridLinePaint);
    }

    // Draw draggable corners
    final cornerPaint = Paint()
      ..color = isAligned ? Colors.green : Colors.blue
      ..style = PaintingStyle.fill;
    
    final cornerStrokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const cornerRadius = 15.0;
    final corners = [topLeft, topRight, bottomRight, bottomLeft];
    
    for (final corner in corners) {
      canvas.drawCircle(corner, cornerRadius, cornerPaint);
      canvas.drawCircle(corner, cornerRadius, cornerStrokePaint);
    }

    // Draw corner indicators (L-shapes)
    final indicatorPaint = Paint()
      ..color = isAligned ? Colors.green : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const indicatorLength = 25.0;
    
    // Top-left corner
    canvas.drawLine(
      topLeft,
      Offset(topLeft.dx + indicatorLength, topLeft.dy),
      indicatorPaint,
    );
    canvas.drawLine(
      topLeft,
      Offset(topLeft.dx, topLeft.dy + indicatorLength),
      indicatorPaint,
    );

    // Top-right corner
    canvas.drawLine(
      topRight,
      Offset(topRight.dx - indicatorLength, topRight.dy),
      indicatorPaint,
    );
    canvas.drawLine(
      topRight,
      Offset(topRight.dx, topRight.dy + indicatorLength),
      indicatorPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      bottomLeft,
      Offset(bottomLeft.dx + indicatorLength, bottomLeft.dy),
      indicatorPaint,
    );
    canvas.drawLine(
      bottomLeft,
      Offset(bottomLeft.dx, bottomLeft.dy - indicatorLength),
      indicatorPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      bottomRight,
      Offset(bottomRight.dx - indicatorLength, bottomRight.dy),
      indicatorPaint,
    );
    canvas.drawLine(
      bottomRight,
      Offset(bottomRight.dx, bottomRight.dy - indicatorLength),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant InteractiveGridPainter oldDelegate) {
    return topLeft != oldDelegate.topLeft ||
        topRight != oldDelegate.topRight ||
        bottomLeft != oldDelegate.bottomLeft ||
        bottomRight != oldDelegate.bottomRight ||
        isAligned != oldDelegate.isAligned;
  }
}

