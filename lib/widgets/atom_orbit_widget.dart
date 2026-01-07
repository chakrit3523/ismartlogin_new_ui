import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Atom Animation that exactly matches the CSS reference
/// 8 Rings structure with specific delays and animations.
class AtomOrbitWidget extends StatefulWidget {
  final double size;
  final Widget child;
  final Color orbitColor;
  final Duration duration;

  const AtomOrbitWidget({
    Key? key,
    required this.size,
    required this.child,
    this.orbitColor = const Color(0xFF0663F7),
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<AtomOrbitWidget> createState() => _AtomOrbitWidgetState();
}

class _AtomOrbitWidgetState extends State<AtomOrbitWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: ExactCSSAtomPainter(
                  progress: _controller.value,
                  color: widget.orbitColor,
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class ExactCSSAtomPainter extends CustomPainter {
  final double progress;
  final Color color;

  ExactCSSAtomPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // SVG viewBox 0..128. rx=60, ry=30.
    final scale = size.width / 128.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 120, height: 60));
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length; // ~293
    // CSS uses 580 for dashoffset range (approx 2 loops). We map 0..1 progress to 0..580 dashoffset.
    final totalDashOffset = 580.0;

    // Ring 1: rotate(0)
    // Orbits: 1 (0.3), 2 (0.5, 50 240), 3 (1.0, 25 265)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: 0,
        ringDelay: 0,
        orbits: [
          _OrbitStyle(opacity: 0.3, isSolid: true),
          _OrbitStyle(opacity: 0.5, dashArray: [50, 240]),
          _OrbitStyle(opacity: 1.0, dashArray: [25, 265]),
        ]);

    // Ring 2: rotate(0)
    // Orbits: 1 (0.0), 2 (0.5, 50 240, delay -0.125), 3 (1.0, 25 265, delay -0.125)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: 0,
        ringDelay: 0,
        orbits: [
          _OrbitStyle(opacity: 0.0, isSolid: true),
          _OrbitStyle(opacity: 0.5, dashArray: [50, 240], delay: -0.125),
          _OrbitStyle(opacity: 1.0, dashArray: [25, 265], delay: -0.125),
        ]);

    // Ring 3: rotate(0)
    // Orbits: 1 (0.0), 2 (0.5, 50 240, delay -0.25), 3 (1.0, 25 265, delay -0.25)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: 0,
        ringDelay: 0,
        orbits: [
          _OrbitStyle(opacity: 0.0, isSolid: true),
          _OrbitStyle(opacity: 0.5, dashArray: [50, 240], delay: -0.25),
          _OrbitStyle(opacity: 1.0, dashArray: [25, 265], delay: -0.25),
        ]);

    // Ring 4: rotate(0)
    // Orbits: 1 (0.0), 2 (0.5, 50 240, delay -0.375), 3 (1.0, 25 265, delay -0.375)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: 0,
        ringDelay: 0,
        orbits: [
          _OrbitStyle(opacity: 0.0, isSolid: true),
          _OrbitStyle(opacity: 0.5, dashArray: [50, 240], delay: -0.375),
          _OrbitStyle(opacity: 1.0, dashArray: [25, 265], delay: -0.375),
        ]);

    // Ring 5: rotate(180)
    // Ring Delay: -0.25
    // Orbits: 1 (0.3), 2 (0.5, 50 240), 3 (1.0, 25 265)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: math.pi,
        ringDelay: -0.25,
        orbits: [
          _OrbitStyle(opacity: 0.3, isSolid: true),
          _OrbitStyle(opacity: 0.5, dashArray: [50, 240]),
          _OrbitStyle(opacity: 1.0, dashArray: [25, 265]),
        ]);

    // Ring 6: rotate(180)
    // Ring Delay: -0.25
    // Orbits: 1 (0.0), 2 (0.5, 50 240, delay -0.25), 3 (1.0, 25 265, delay -0.25)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: math.pi,
        ringDelay: -0.25,
        orbits: [
          _OrbitStyle(opacity: 0.0, isSolid: true),
          _OrbitStyle(opacity: 0.5, dashArray: [50, 240], delay: -0.25),
          _OrbitStyle(opacity: 1.0, dashArray: [25, 265], delay: -0.25),
        ]);

    // Ring 7: rotate(0) - Electrons
    // Ring Delay: -0.25
    // Electrons: 1 (delay 0), 2 (delay -0.25)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: 0,
        ringDelay: -0.25,
        orbits: [
          _OrbitStyle(isElectron: true, delay: 0),
          _OrbitStyle(isElectron: true, delay: -0.25),
        ]);

    // Ring 8: rotate(180) - Electrons
    // Ring Delay: 0 (Not in n+5..7)
    // Electrons: 1 (0), 2 (-0.125), 3 (-0.25), 4 (-0.375)
    _drawRing(canvas, path, pathMetric, pathLength,
        rotationOffset: math.pi,
        ringDelay: 0,
        orbits: [
          _OrbitStyle(isElectron: true, delay: 0),
          _OrbitStyle(isElectron: true, delay: -0.125),
          _OrbitStyle(isElectron: true, delay: -0.25),
          _OrbitStyle(isElectron: true, delay: -0.375),
        ]);

    canvas.restore();
  }

  void _drawRing(
    Canvas canvas,
    Path path,
    ui.PathMetric metric,
    double length, {
    required double rotationOffset,
    required double ringDelay,
    required List<_OrbitStyle> orbits,
  }) {
    canvas.save();

    // Calculate ring rotation
    // Animation 'ring': transform: rotate(0) -> rotate(1turn)
    // Apply delay
    double ringT = (progress + ringDelay) % 1.0;
    if (ringT < 0) ringT += 1.0;
    double currentRotation = rotationOffset + (ringT * 2 * math.pi);

    canvas.rotate(currentRotation);

    for (var orbit in orbits) {
      if (orbit.opacity == 0.0 && !orbit.isElectron) continue;

      // Calculate orbit animation
      // Animation 'orbit': stroke-dashoffset 0 -> 580
      // We simulate moving dashes manually along path.
      double orbitT = (progress + orbit.delay) % 1.0;
      if (orbitT < 0) orbitT += 1.0;

      // CSS dashoffset moves POSITIVELY (0 -> 580).
      // Dashoffset shifts the pattern.
      // Equivalent to shifting dash start point backwards.
      // Or shifting pattern along path.
      double offset = orbitT * 580.0;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (orbit.isElectron) {
        paint.color = Colors.white;
        paint.strokeWidth = 8;
        // Electron dasharray 1 289
        _drawDashedPath(canvas, metric, length, offset, [1, 289], paint);
      } else {
        paint.color = color.withValues(alpha: orbit.opacity);
        paint.strokeWidth = 4;

        if (orbit.isSolid) {
          canvas.drawPath(path, paint);
        } else {
          _drawDashedPath(
              canvas, metric, length, offset, orbit.dashArray!, paint);
        }
      }
    }

    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, ui.PathMetric metric, double length,
      double offset, List<double> dashArray, Paint paint) {
    double dashSize = dashArray[0];
    double gapSize = dashArray[1];
    double cycleSize = dashSize + gapSize;

    // CSS stroke-dashoffset behavior:
    // Positive offset shifts the pattern to the left (start of path is deeper into the pattern).
    // Effective start point in pattern = offset % cycle.

    // We want to draw segments where the dash exists.
    // A dash exists in pattern interval [0, dashSize].
    // At path distance 'd', pattern pos is (d + offset) % cycle.
    // Visible if pattern pos < dashSize.

    // Find first dash start:
    // (d + offset) % cycle = 0  => d = -offset + k*cycle
    double startD = -offset % cycleSize;
    if (startD < 0) startD += cycleSize;

    // If startD is effectively "gap start", we need "dash start".
    // Wait, (d+offset)%cycle starts at 0 at dash start.
    // So d = -offset is a dash start.

    for (double d = startD - cycleSize; d < length; d += cycleSize) {
      // Dash segment is [d, d + dashSize]
      double start = d;
      double end = d + dashSize;

      _drawSegment(canvas, metric, length, start, end, paint);
    }
  }

  void _drawSegment(Canvas canvas, ui.PathMetric metric, double length,
      double start, double end, Paint paint) {
    if (end <= 0 || start >= length) return;

    // Handle normal case
    if (start >= 0 && end <= length) {
      canvas.drawPath(metric.extractPath(start, end), paint);
    } else {
      // Handle overlap/wrapping if logic requires (here we iterate nicely so simple clamping might miss wrap-around visualization if cycle doesn't align?
      // Actually CSS dashoffset does not wrap path automatically unless path is closed?
      // SVG Ellipse is closed.
      // computeMetrics treats it as linear 0..length.

      // If we are strictly following CSS logic on a closed path, the pattern wraps visually.
      // But implementation-wise, my loop above only draws d < length.
      // We need to handle d < 0 (partial start) and d > length (partial end)?
      // Actually simply:

      double drawStart = start;
      double drawEnd = end;

      if (drawStart < 0) {
        // Segment [-x, y].
        // Draw [length-x, length] and [0, y]
        canvas.drawPath(metric.extractPath(length + drawStart, length), paint);
        if (drawEnd > 0) canvas.drawPath(metric.extractPath(0, drawEnd), paint);
      } else if (drawEnd > length) {
        // Segment [x, length+y]
        // Draw [x, length] and [0, y]
        canvas.drawPath(metric.extractPath(drawStart, length), paint);
        canvas.drawPath(metric.extractPath(0, drawEnd - length), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ExactCSSAtomPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _OrbitStyle {
  final double opacity;
  final bool isSolid;
  final List<double>? dashArray;
  final double delay;
  final bool isElectron;

  _OrbitStyle({
    this.opacity = 1.0,
    this.isSolid = false,
    this.dashArray,
    this.delay = 0.0,
    this.isElectron = false,
  });
}
