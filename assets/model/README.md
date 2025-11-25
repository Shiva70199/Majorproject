# TFLite Model Files

## Required Files

1. **safedocs_classifier.tflite** - The trained TFLite model file
2. **labels.txt** - Class labels (already provided)

## Model Requirements

- **Input Shape**: [1, 224, 224, 3] (RGB image, 224x224 pixels)
- **Output Shape**: [1, 2] (2 classes: academic, non_academic)
- **Input Format**: Float32, normalized to [0, 1]
- **Output Format**: Float32 probabilities

## How to Add Your Model

1. Train or obtain a TFLite model that classifies images as "academic" or "non_academic"
2. Place the model file here as `safedocs_classifier.tflite`
3. Ensure the model accepts 224x224 RGB images
4. Ensure the model outputs 2 classes (academic, non_academic)

## Training Data

The model should be trained on:
- **Academic documents**: 10th/12th marksheets, college ID cards, VTU grade cards, certificates, bonafide/TC
- **Non-academic images**: selfies, scenery, group photos, WhatsApp images, social media screenshots, random objects, posters/bills

## Model Training Tips

- Use transfer learning (MobileNet, EfficientNet, etc.)
- Augment data with rotations, brightness, contrast variations
- Balance the dataset (equal academic/non-academic samples)
- Test on blurry, low-light, and tilted document images

## Testing

After adding your model, test with:
- Clear academic documents (should return isAcademic: true, confidence > 0.7)
- Non-academic images (should return isAcademic: false, confidence > 0.7)

