import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrbitClockWidget extends StatefulWidget {
  final double size;

  const OrbitClockWidget({
    Key? key,
    this.size = 320,
  }) : super(key: key);

  @override
  State<OrbitClockWidget> createState() => _OrbitClockWidgetState();
}

class _OrbitClockWidgetState extends State<OrbitClockWidget> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  final List<String> _thaiMonths = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม'
  ];
  final List<String> _thaiDays = [
    'อาทิตย์',
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์'
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final double centerRadius = size * 0.28;

    final double innerRadius = size * 0.35;
    final double middleRadius = size * 0.43;
    final double outerRadius = size * 0.51;

    // คำนวณมุม (ลบ math.pi / 2 เพื่อให้เริ่มที่ 12 นาฬิกา)
    final double secAngle = (_now.second / 60) * 2 * math.pi - math.pi / 2;
    final double minAngle = (_now.minute / 60) * 2 * math.pi - math.pi / 2;
    final double hourAngle =
        ((_now.hour % 12) / 12 + _now.minute / 720) * 2 * math.pi - math.pi / 2;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. เส้นวงโคจร และ Progress Arcs
            CustomPaint(
              size: Size(size, size),
              painter: OrbitPainter(
                radii: [innerRadius, middleRadius, outerRadius],
                angles: [hourAngle, minAngle, secAngle],
              ),
            ),

            // 2. วงกลมหลักตรงกลาง
            Container(
              width: centerRadius * 2,
              height: centerRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Softer shadow
                    blurRadius: 30, // Smoother blur
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getThaiDay(),
                    style: GoogleFonts.kanit(
                      fontSize: size * 0.11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3142),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '${_now.day} ${_thaiMonths[_now.month]} ${_now.year + 543}',
                    style: GoogleFonts.kanit(
                      fontSize: size * 0.042,
                      color: Colors.grey.shade500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.kanit(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 0.9,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Satellite Circles (Hours, Minutes, Seconds)
            _buildSatellite(
                angle: hourAngle,
                radius: innerRadius,
                value: "${_now.hour}"
                    .padLeft(2, '0'), // Add padLeft to match "10", "48" style
                size: size * 0.13),
            _buildSatellite(
                angle: minAngle,
                radius: middleRadius,
                value: "${_now.minute}".padLeft(2, '0'),
                size: size * 0.13),
            _buildSatellite(
                angle: secAngle,
                radius: outerRadius,
                value: "${_now.second}".padLeft(2, '0'),
                size: size * 0.13),
          ],
        ),
      ),
    );
  }

  String _getThaiDay() {
    int dayIndex = _now.weekday % 7;
    return _thaiDays[dayIndex];
  }

  Widget _buildSatellite(
      {required double angle,
      required double radius,
      required String value,
      required double size}) {
    final double x = radius * math.cos(angle);
    final double y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Softer shadow
              blurRadius: 12, // Smoother blur
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            value.padLeft(2, '0'),
            style: GoogleFonts.kanit(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D47A1),
            ),
          ),
        ),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  final List<double> radii;
  final List<double> angles;

  OrbitPainter({required this.radii, required this.angles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ตั้งค่าปากกาสำหรับวงแหวนพื้นหลัง
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08) // More subtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8; // Thinner

    // ตั้งค่าปากกาสำหรับ Progress Arc (เส้นที่วิ่งตาม)
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.5) // Less opaque
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5; // Thinner

    for (int i = 0; i < radii.length; i++) {
      // วาดวงกลมพื้นหลัง
      canvas.drawCircle(center, radii[i], bgPaint);

      // วาดเส้นโค้งที่วิ่งจากจุดเริ่มต้น (บนสุด) มาถึงตำแหน่งปัจจุบันของดาวเทียม
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radii[i]),
        -math.pi / 2, // เริ่มที่ 12 นาฬิกา
        angles[i] - (-math.pi / 2), // กวาดไปถึงมุมปัจจุบัน
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) =>
      true; // ให้ Repaint ตามวินาที
}
