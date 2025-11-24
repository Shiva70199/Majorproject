import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Service for detecting document edges in images
class EdgeDetectionService {
  /// Detect document edges in an image
  /// Returns a list of 4 points representing the document corners
  /// Returns null if no document is detected
  Future<List<Offset>?> detectDocumentEdges(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize image for faster processing (max 800px width)
      final processedImage = image.width > 800
          ? img.copyResize(image, width: 800)
          : image;

      // Convert to grayscale
      final gray = img.grayscale(processedImage);

      // Apply Gaussian blur to reduce noise
      final blurred = img.gaussianBlur(gray, radius: 3);

      // Apply Canny edge detection
      final edges = _cannyEdgeDetection(blurred);

      // Find contours
      final contours = _findContours(edges);

      // Find the largest rectangular contour (likely the document)
      final documentContour = _findLargestRectangle(contours, processedImage.width, processedImage.height);

      if (documentContour == null || documentContour.length < 4) {
        return null;
      }

      // Convert contour points to screen coordinates
      final scaleX = image.width / processedImage.width;
      final scaleY = image.height / processedImage.height;

      final corners = documentContour.map((point) {
        return Offset(
          point.dx * scaleX,
          point.dy * scaleY,
        );
      }).toList();

      // Order corners: top-left, top-right, bottom-right, bottom-left
      return _orderCorners(corners);
    } catch (e) {
      return null;
    }
  }

  /// Canny edge detection algorithm
  List<List<bool>> _cannyEdgeDetection(img.Image image) {
    final width = image.width;
    final height = image.height;
    final edges = List.generate(height, (_) => List<bool>.filled(width, false));

    // Sobel operator for gradient detection
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    final gradients = List.generate(height, (_) => List<double>.filled(width, 0));
    final directions = List.generate(height, (_) => List<double>.filled(width, 0));

    // Calculate gradients
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        double gx = 0, gy = 0;

        for (var i = -1; i <= 1; i++) {
          for (var j = -1; j <= 1; j++) {
            final pixel = image.getPixel(x + j, y + i);
            final gray = img.getLuminance(pixel);
            gx += gray * sobelX[i + 1][j + 1];
            gy += gray * sobelY[i + 1][j + 1];
          }
        }

        final magnitude = math.sqrt(gx * gx + gy * gy);
        gradients[y][x] = magnitude;
        directions[y][x] = math.atan2(gy, gx);
      }
    }

    // Non-maximum suppression
    final threshold = _calculateThreshold(gradients);
    final lowThreshold = threshold * 0.5;
    final highThreshold = threshold * 1.5;

    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final angle = directions[y][x];
        final magnitude = gradients[y][x];

        if (magnitude < lowThreshold) {
          continue;
        }

        // Determine edge direction
        double neighbor1, neighbor2;
        if ((angle >= -math.pi / 8 && angle < math.pi / 8) ||
            (angle >= 7 * math.pi / 8 || angle < -7 * math.pi / 8)) {
          // Horizontal edge
          neighbor1 = gradients[y][x - 1];
          neighbor2 = gradients[y][x + 1];
        } else if ((angle >= math.pi / 8 && angle < 3 * math.pi / 8) ||
            (angle >= -7 * math.pi / 8 && angle < -5 * math.pi / 8)) {
          // Diagonal edge (top-left to bottom-right)
          neighbor1 = gradients[y - 1][x - 1];
          neighbor2 = gradients[y + 1][x + 1];
        } else if ((angle >= 3 * math.pi / 8 && angle < 5 * math.pi / 8) ||
            (angle >= -5 * math.pi / 8 && angle < -3 * math.pi / 8)) {
          // Vertical edge
          neighbor1 = gradients[y - 1][x];
          neighbor2 = gradients[y + 1][x];
        } else {
          // Diagonal edge (top-right to bottom-left)
          neighbor1 = gradients[y - 1][x + 1];
          neighbor2 = gradients[y + 1][x - 1];
        }

        if (magnitude >= neighbor1 && magnitude >= neighbor2) {
          edges[y][x] = magnitude >= highThreshold;
        }
      }
    }

    return edges;
  }

  /// Calculate adaptive threshold for edge detection
  double _calculateThreshold(List<List<double>> gradients) {
    double sum = 0;
    int count = 0;

    for (var row in gradients) {
      for (var value in row) {
        sum += value;
        count++;
      }
    }

    return sum / count;
  }

  /// Find contours in edge image
  List<List<Offset>> _findContours(List<List<bool>> edges) {
    final contours = <List<Offset>>[];
    final visited = List.generate(
      edges.length,
      (_) => List<bool>.filled(edges[0].length, false),
    );

    for (var y = 0; y < edges.length; y++) {
      for (var x = 0; x < edges[0].length; x++) {
        if (edges[y][x] && !visited[y][x]) {
          final contour = _traceContour(edges, visited, x, y);
          if (contour.length > 20) {
            // Filter small contours
            contours.add(contour);
          }
        }
      }
    }

    return contours;
  }

  /// Trace a single contour
  List<Offset> _traceContour(
    List<List<bool>> edges,
    List<List<bool>> visited,
    int startX,
    int startY,
  ) {
    final contour = <Offset>[];
    final stack = <Point>[];
    stack.add(Point(startX, startY));

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;

      if (x < 0 ||
          x >= edges[0].length ||
          y < 0 ||
          y >= edges.length ||
          visited[y][x] ||
          !edges[y][x]) {
        continue;
      }

      visited[y][x] = true;
      contour.add(Offset(x.toDouble(), y.toDouble()));

      // Check 8-connected neighbors
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          stack.add(Point(x + dx, y + dy));
        }
      }
    }

    return contour;
  }

  /// Find the largest rectangular contour
  List<Offset>? _findLargestRectangle(
    List<List<Offset>> contours,
    int imageWidth,
    int imageHeight,
  ) {
    if (contours.isEmpty) return null;

    List<Offset>? bestContour;
    double bestScore = 0;

    for (var contour in contours) {
      if (contour.length < 4) continue;

      // Approximate contour to polygon
      final approx = _approximatePolygon(contour);

      if (approx.length == 4) {
        // Check if it's roughly rectangular
        final score = _calculateRectangleScore(approx, imageWidth, imageHeight);
        if (score > bestScore) {
          bestScore = score;
          bestContour = approx;
        }
      }
    }

    return bestContour;
  }

  /// Approximate contour to polygon using Douglas-Peucker algorithm
  List<Offset> _approximatePolygon(List<Offset> contour, {double epsilon = 5.0}) {
    if (contour.length <= 2) return contour;

    // Find the point with maximum distance from line between first and last point
    double maxDistance = 0;
    int maxIndex = 0;
    final first = contour.first;
    final last = contour.last;

    for (var i = 1; i < contour.length - 1; i++) {
      final distance = _pointToLineDistance(contour[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance > epsilon) {
      // Recursively simplify
      final left = _approximatePolygon(contour.sublist(0, maxIndex + 1), epsilon: epsilon);
      final right = _approximatePolygon(contour.sublist(maxIndex), epsilon: epsilon);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [first, last];
    }
  }

  /// Calculate distance from point to line segment
  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final a = point.dx - lineStart.dx;
    final b = point.dy - lineStart.dy;
    final c = lineEnd.dx - lineStart.dx;
    final d = lineEnd.dy - lineStart.dy;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;
    final param = lenSq != 0 ? dot / lenSq : -1;

    double xx, yy;

    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * c;
      yy = lineStart.dy + param * d;
    }

    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculate score for how rectangular a contour is
  double _calculateRectangleScore(
    List<Offset> corners,
    int imageWidth,
    int imageHeight,
  ) {
    if (corners.length != 4) return 0;

    // Calculate area
    final area = _polygonArea(corners);

    // Check if corners form a convex quadrilateral
    if (area < imageWidth * imageHeight * 0.1) {
      return 0; // Too small
    }

    // Calculate angles to check if they're close to 90 degrees
    double angleScore = 0;
    for (var i = 0; i < 4; i++) {
      final p1 = corners[i];
      final p2 = corners[(i + 1) % 4];
      final p3 = corners[(i + 2) % 4];

      final angle = _calculateAngle(p1, p2, p3);
      final angleDiff = (angle - math.pi / 2).abs();
      angleScore += 1 - (angleDiff / (math.pi / 2));
    }
    angleScore /= 4;

    // Area score (prefer larger rectangles)
    final areaScore = area / (imageWidth * imageHeight);

    return angleScore * 0.7 + areaScore * 0.3;
  }

  /// Calculate area of polygon
  double _polygonArea(List<Offset> points) {
    double area = 0;
    for (var i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].dx * points[j].dy;
      area -= points[j].dx * points[i].dy;
    }
    return area.abs() / 2;
  }

  /// Calculate angle between three points
  double _calculateAngle(Offset p1, Offset p2, Offset p3) {
    final v1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);

    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    final mag2 = math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);

    if (mag1 == 0 || mag2 == 0) return 0;

    final cosAngle = dot / (mag1 * mag2);
    return math.acos(cosAngle.clamp(-1.0, 1.0));
  }

  /// Order corners: top-left, top-right, bottom-right, bottom-left
  List<Offset> _orderCorners(List<Offset> corners) {
    if (corners.length != 4) return corners;

    // Find center point
    final center = Offset(
      corners.map((p) => p.dx).reduce((a, b) => a + b) / 4,
      corners.map((p) => p.dy).reduce((a, b) => a + b) / 4,
    );

    // Sort by angle from center
    corners.sort((a, b) {
      final angleA = math.atan2(a.dy - center.dy, a.dx - center.dx);
      final angleB = math.atan2(b.dy - center.dy, b.dx - center.dx);
      return angleA.compareTo(angleB);
    });

    // Find top-left (smallest x+y), top-right, bottom-right, bottom-left
    final topLeft = corners.reduce((a, b) => (a.dx + a.dy) < (b.dx + b.dy) ? a : b);
    final bottomRight = corners.reduce((a, b) => (a.dx + a.dy) > (b.dx + b.dy) ? a : b);

    final remaining = corners.where((p) => p != topLeft && p != bottomRight).toList();
    final topRight = remaining.reduce((a, b) => a.dx > b.dx ? a : b);
    final bottomLeft = remaining.firstWhere((p) => p != topRight);

    return [topLeft, topRight, bottomRight, bottomLeft];
  }
}

/// Helper class for point coordinates
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

