import 'package:ismart_login/src/core/presentation/bloc/bloc_material.dart';

/// Custom clipper for a white container with single wave curve.
/// Starts high on the left side, curves down to the right side.
///
/// Visual representation:
/// ```
///   ───╮                        ← Left side higher
///       ╰────╮
///            ╰────╮
///                 ╰────╮
///                      ╰────╮
///                          ╰───  ← Right side lower
///   │                         │
///   │      WHITE AREA         │
///   └─────────────────────────┘
/// ```
class CurvedWhitePanelClipper extends CustomClipper<Path> {
  /// The height difference between left (high) and right (low).
  final double radius;

  CurvedWhitePanelClipper({this.radius = 50.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final waveHeight = radius;

    // Start at bottom-left corner
    path.moveTo(0, size.height);

    // Left edge going up to top (higher point)
    path.lineTo(0, 0);

    // Single smooth wave from left (high) to right (low)
    path.quadraticBezierTo(
      size.width * 0.5, 0, // Control point in middle (stays high)
      size.width, waveHeight, // End at right side (lower)
    );

    // Right edge going down
    path.lineTo(size.width, size.height);

    // Bottom edge
    path.lineTo(0, size.height);

    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CurvedWhitePanelClipper oldClipper) {
    return oldClipper.radius != radius;
  }
}
