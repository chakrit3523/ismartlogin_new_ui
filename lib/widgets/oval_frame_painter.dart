import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Professional rectangular frame overlay for face detection with face bounding box
class OvalFramePainter extends CustomPainter {
  final double faceQuality;
  final Size screenSize;
  final List<Face>? faces;
  final double scanValue;

  OvalFramePainter({
    required this.faceQuality,
    required this.screenSize,
    this.faces,
    this.scanValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rectangular frame for face capture (instead of oval)
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2.5),
        width: size.width * 0.70, // Wider for rectangular
        height: size.height * 0.40, // Taller for rectangular
      ),
      Radius.circular(20), // Rounded corners
    );

    // Darken area outside frame
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(frameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.75),
    );

    // Clean, professional color scheme
    Color frameColor;
    Color glowColor;
    if (faceQuality >= 80) {
      frameColor = const Color(0xFF4CAF50); // Green
      glowColor = Colors.greenAccent;
    } else if (faceQuality >= 50) {
      frameColor = const Color(0xFF2196F3); // Blue
      glowColor = Colors.blueAccent;
    } else {
      frameColor = const Color(0xFFE0E0E0); // Light gray
      glowColor = Colors.white54;
    }

    // Outer glow (subtle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frameRect.outerRect.inflate(3),
        Radius.circular(23),
      ),
      Paint()
        ..color = glowColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main rectangular frame - clean solid line
    canvas.drawRRect(
      frameRect,
      Paint()
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Inner highlight line (professional double-line effect)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frameRect.outerRect.deflate(4),
        Radius.circular(16),
      ),
      Paint()
        ..color = frameColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Corner brackets for professional look
    _drawCornerBrackets(canvas, size, frameRect.outerRect, frameColor);

    // Quality indicator dots at top
    _drawQualityIndicator(canvas, frameRect.outerRect, frameColor);
  }

  void _drawCornerBrackets(
      Canvas canvas, Size size, Rect frameRect, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final bracketLength = 25.0;
    final padding = 15.0;

    // Calculate frame bounds with padding
    final rect = Rect.fromCenter(
      center: frameRect.center,
      width: frameRect.width + padding * 2,
      height: frameRect.height + padding * 2,
    );

    // Top Left
    final tl = rect.topLeft;
    canvas.drawLine(tl, tl + Offset(bracketLength, 0), paint);
    canvas.drawLine(tl, tl + Offset(0, bracketLength), paint);

    // Top Right
    final tr = rect.topRight;
    canvas.drawLine(tr, tr - Offset(bracketLength, 0), paint);
    canvas.drawLine(tr, tr + Offset(0, bracketLength), paint);

    // Bottom Left
    final bl = rect.bottomLeft;
    canvas.drawLine(bl, bl + Offset(bracketLength, 0), paint);
    canvas.drawLine(bl, bl - Offset(0, bracketLength), paint);

    // Bottom Right
    final br = rect.bottomRight;
    canvas.drawLine(br, br - Offset(bracketLength, 0), paint);
    canvas.drawLine(br, br - Offset(0, bracketLength), paint);
  }

  void _drawQualityIndicator(Canvas canvas, Rect frameRect, Color activeColor) {
    // Three dots at the top center to show quality level
    final centerX = frameRect.center.dx;
    final topY = frameRect.top - 25;
    final dotRadius = 5.0;
    final spacing = 18.0;

    final dotPositions = [
      Offset(centerX - spacing, topY),
      Offset(centerX, topY),
      Offset(centerX + spacing, topY),
    ];

    // Determine how many dots are active
    int activeDots;
    if (faceQuality >= 80) {
      activeDots = 3;
    } else if (faceQuality >= 50) {
      activeDots = 2;
    } else if (faceQuality >= 20) {
      activeDots = 1;
    } else {
      activeDots = 0;
    }

    for (int i = 0; i < 3; i++) {
      final isActive = i < activeDots;
      canvas.drawCircle(
        dotPositions[i],
        dotRadius,
        Paint()
          ..color = isActive ? activeColor : Colors.grey.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );

      // Add border
      canvas.drawCircle(
        dotPositions[i],
        dotRadius,
        Paint()
          ..color = isActive
              ? activeColor.withValues(alpha: 0.8)
              : Colors.grey.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(OvalFramePainter oldDelegate) {
    return oldDelegate.faceQuality != faceQuality ||
        oldDelegate.scanValue != scanValue ||
        oldDelegate.faces != faces;
  }
}
