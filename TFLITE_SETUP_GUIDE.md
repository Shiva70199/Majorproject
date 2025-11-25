# TFLite Document Classifier Setup Guide

## Overview

SafeDocs now uses a **TFLite-based image classifier** that runs entirely offline in Flutter. This replaces the previous Python/HuggingFace backend.

## Architecture

- **TFLite Model**: Runs locally in Flutter app
- **No Backend Required**: All classification happens on-device
- **Fast & Reliable**: No network calls, no API failures
- **Privacy**: Images never leave the device for classification

## Model Requirements

### Input
- **Shape**: [1, 224, 224, 3]
- **Format**: RGB image, 224x224 pixels
- **Type**: Float32, normalized to [0, 1]

### Output
- **Shape**: [1, 2]
- **Format**: Float32 probabilities
- **Classes**: 
  - Index 0: `academic`
  - Index 1: `non_academic`

## Setup Steps

### 1. Train or Obtain a TFLite Model

You need a TFLite model trained to classify images as:
- **Academic**: 10th/12th marksheets, college ID cards, VTU grade cards, certificates, bonafide/TC
- **Non-academic**: selfies, scenery, group photos, WhatsApp images, social media screenshots, random objects, posters/bills

#### Option A: Train Your Own Model

1. **Collect Training Data**:
   - Academic documents: 500-1000 images
   - Non-academic images: 500-1000 images
   - Include variations: blurry, low-light, tilted, B&W copies

2. **Use Transfer Learning**:
   ```python
   # Example using TensorFlow/Keras
   base_model = tf.keras.applications.MobileNetV2(
       input_shape=(224, 224, 3),
       include_top=False,
       weights='imagenet'
   )
   
   model = tf.keras.Sequential([
       base_model,
       tf.keras.layers.GlobalAveragePooling2D(),
       tf.keras.layers.Dense(128, activation='relu'),
       tf.keras.layers.Dropout(0.2),
       tf.keras.layers.Dense(2, activation='softmax')  # 2 classes
   ])
   ```

3. **Convert to TFLite**:
   ```python
   converter = tf.lite.TFLiteConverter.from_keras_model(model)
   converter.optimizations = [tf.lite.Optimize.DEFAULT]
   tflite_model = converter.convert()
   
   with open('safedocs_classifier.tflite', 'wb') as f:
       f.write(tflite_model)
   ```

#### Option B: Use Pre-trained Model

If you have access to a pre-trained academic document classifier, convert it to TFLite format.

### 2. Place Model Files

1. Copy `safedocs_classifier.tflite` to `assets/model/`
2. Ensure `assets/model/labels.txt` contains:
   ```
   academic
   non_academic
   ```

### 3. Update pubspec.yaml

The assets are already configured:
```yaml
flutter:
  assets:
    - assets/model/safedocs_classifier.tflite
    - assets/model/labels.txt
```

### 4. Test the Model

1. Run the app: `flutter run`
2. Try uploading:
   - ✅ Academic document (should accept)
   - ❌ Non-academic image (should reject)

## Model Training Tips

### Data Augmentation
- Rotations: ±15 degrees
- Brightness: ±20%
- Contrast: ±20%
- Blur: slight Gaussian blur
- Noise: slight random noise

### Training Best Practices
- **Balanced Dataset**: Equal academic/non-academic samples
- **Validation Split**: 20-30% for validation
- **Test on Edge Cases**: Blurry, low-light, tilted documents
- **Monitor Overfitting**: Use early stopping

### Recommended Models
- **MobileNetV2**: Fast, small (~14MB), good accuracy
- **EfficientNet-Lite**: Better accuracy, slightly larger
- **Custom CNN**: If you have specific requirements

## Troubleshooting

### Model Not Loading
- Check file path: `assets/model/safedocs_classifier.tflite`
- Verify file exists in `pubspec.yaml` assets
- Run `flutter clean` and `flutter pub get`

### Wrong Predictions
- Verify model input/output shapes match
- Check labels.txt matches model output classes
- Test with known good/bad images

### Performance Issues
- Use quantized model (INT8) for faster inference
- Reduce model size if needed
- Consider using GPU delegate on supported devices

## Next Steps

1. **Train Model**: Use your dataset to train the classifier
2. **Test Thoroughly**: Test with various document types
3. **Deploy**: Place model in `assets/model/` and run app
4. **Monitor**: Check classification accuracy in production

## Support

For issues or questions:
- Check model input/output shapes
- Verify labels.txt format
- Test with sample images
- Review TFLite documentation

