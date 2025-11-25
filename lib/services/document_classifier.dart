import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

/// Result of TFLite document classification
class DocumentClassificationResult {
  final bool isAcademic;
  final double confidence;

  const DocumentClassificationResult({
    required this.isAcademic,
    required this.confidence,
  });
}

/// TFLite-based document classifier service
/// Runs entirely offline in Flutter - no backend required
class DocumentClassifier {
  static const String _modelPath = 'assets/model/safedocs_classifier.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';
  
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  
  /// Initialize the TFLite model
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ TFLite model loaded successfully');
        print('📊 Model input shape: ${_interpreter!.getInputTensor(0).shape}');
        print('📊 Model output shape: ${_interpreter!.getOutputTensor(0).shape}');
        print('📊 Labels loaded: ${_labels.length}');
      }
    } catch (e) {
      throw Exception('Failed to initialize TFLite model: $e');
    }
  }
  
  /// Classify an image as academic or non-academic
  /// 
  /// [imageBytes] - Raw image bytes (JPEG/PNG)
  /// Returns classification result with isAcademic flag and confidence score
  Future<DocumentClassificationResult> classify(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_interpreter == null) {
      throw Exception('TFLite model not initialized');
    }
    
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Preprocess: Resize to 224x224 (standard for image classification)
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );
      
      // Convert to RGB if needed (remove alpha channel)
      img.Image rgbImage = resizedImage;
      if (resizedImage.numChannels == 4) {
        rgbImage = img.Image(width: resizedImage.width, height: resizedImage.height);
        for (int y = 0; y < resizedImage.height; y++) {
          for (int x = 0; x < resizedImage.width; x++) {
            final pixel = resizedImage.getPixel(x, y);
            rgbImage.setPixel(x, y, pixel);
          }
        }
      }
      
      // Convert to float32 array and normalize to [0, 1]
      final inputBuffer = Float32List(224 * 224 * 3);
      int index = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = rgbImage.getPixel(x, y);
          // Extract RGB values and normalize
          inputBuffer[index++] = (pixel.r.toDouble() / 255.0);
          inputBuffer[index++] = (pixel.g.toDouble() / 255.0);
          inputBuffer[index++] = (pixel.b.toDouble() / 255.0);
        }
      }
      
      // Reshape to match model input shape [1, 224, 224, 3]
      final input = inputBuffer.reshape([1, 224, 224, 3]);
      
      // Prepare output buffer
      final outputBuffer = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      
      // Run inference
      _interpreter!.run(input, outputBuffer);
      
      // Get predictions
      final predictions = outputBuffer[0] as List<double>;
      
      // Find the class with highest confidence
      double maxConfidence = 0.0;
      int predictedClass = 0;
      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          predictedClass = i;
        }
      }
      
      // Determine if academic based on label
      // Label 0 = "academic", Label 1 = "non_academic" (or vice versa)
      // Adjust based on your actual labels.txt
      final predictedLabel = _labels[predictedClass].toLowerCase();
      final isAcademic = predictedLabel.contains('academic') || 
                        predictedLabel == 'academic' ||
                        predictedClass == 0; // Assuming index 0 is academic
      
      if (kDebugMode) {
        print('📊 Classification result:');
        print('   Label: ${_labels[predictedClass]}');
        print('   Confidence: ${(maxConfidence * 100).toStringAsFixed(2)}%');
        print('   Is Academic: $isAcademic');
      }
      
      return DocumentClassificationResult(
        isAcademic: isAcademic,
        confidence: maxConfidence,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Classification error: $e');
      }
      // On error, default to rejecting (safer)
      return const DocumentClassificationResult(
        isAcademic: false,
        confidence: 0.0,
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

