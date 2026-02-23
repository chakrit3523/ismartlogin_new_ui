import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ismart_login/src/features/front/presentation/pages/future/summary_future.dart';
import 'package:ismart_login/src/features/front/presentation/pages/model/sumaryToDay.dart';
import 'package:ismart_login/system/shared_preferences.dart';

class CheckinSuccessPopup extends StatefulWidget {
  final String uid;
  final String scheduledTime; // เวลาเข้างาน เช่น "08:30:00"
  final String actualTime; // เวลาที่เข้าจริง เช่น "08:15:00"
  final bool isLate;

  const CheckinSuccessPopup({
    super.key,
    required this.uid,
    required this.scheduledTime,
    required this.actualTime,
    required this.isLate,
  });

  @override
  State<CheckinSuccessPopup> createState() => _CheckinSuccessPopupState();
}

class _CheckinSuccessPopupState extends State<CheckinSuccessPopup>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  // Today's data
  int _myOrder = 0;
  int _totalMembers = 0;

  // Yesterday's stats
  int _yesterdayOntime = 0;
  int _yesterdayLate = 0;
  int _yesterdayOutside = 0;
  int _yesterdayAbsence = 0;

  // Time difference
  String _timeDiffText = '';
  bool _isEarly = true;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _calculateTimeDiff();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _calculateTimeDiff() {
    try {
      if (widget.scheduledTime.isEmpty) {
        _timeDiffText = '';
        return;
      }

      // Parse scheduled time (e.g. "08:30:00")
      final scheduled = DateFormat("HH:mm:ss").parse(widget.scheduledTime);

      // Parse actual time - handle both "HH:mm:ss" and "HH:mm"
      DateTime actual;
      final actualStr = widget.actualTime.trim();
      if (actualStr.contains(':')) {
        final parts = actualStr.split(':');
        if (parts.length >= 3) {
          actual = DateFormat("HH:mm:ss").parse(actualStr);
        } else {
          actual = DateFormat("HH:mm").parse(actualStr);
        }
      } else {
        _timeDiffText = '';
        return;
      }

      final scheduledMinutes = scheduled.hour * 60 + scheduled.minute;
      final actualMinutes = actual.hour * 60 + actual.minute;
      final diffMinutes = scheduledMinutes - actualMinutes;

      if (diffMinutes > 0) {
        // เข้างานก่อน
        _isEarly = true;
        final hours = diffMinutes ~/ 60;
        final mins = diffMinutes % 60;
        if (hours > 0 && mins > 0) {
          _timeDiffText = 'คุณเข้างานก่อน ${hours}ชม.${mins}นาที';
        } else if (hours > 0) {
          _timeDiffText = 'คุณเข้างานก่อน ${hours}ชม.';
        } else {
          _timeDiffText = 'คุณเข้างานก่อน ${mins}นาที';
        }
      } else if (diffMinutes < 0) {
        // เข้างานสาย
        _isEarly = false;
        final lateMins = -diffMinutes;
        final hours = lateMins ~/ 60;
        final mins = lateMins % 60;
        if (hours > 0 && mins > 0) {
          _timeDiffText = 'คุณเข้างานสาย ${hours}ชม.${mins}นาที';
        } else if (hours > 0) {
          _timeDiffText = 'คุณเข้างานสาย ${hours}ชม.';
        } else {
          _timeDiffText = 'คุณเข้างานสาย ${mins}นาที';
        }
      } else {
        _isEarly = true;
        _timeDiffText = 'คุณเข้างานตรงเวลาพอดี!';
      }
    } catch (e) {
      print("Error calculating time diff: $e");
      _timeDiffText = '';
    }
  }

  Future<void> _loadData() async {
    try {
      final orgId = await SharedCashe.getItemsWay(name: 'org_id');
      final now = DateTime.now();
      final todayStr = DateFormat("yyyy-MM-dd").format(now);
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = DateFormat("yyyy-MM-dd").format(yesterday);

      // Fetch today's data
      final todayData = await SummaryFuture().apiGetSummaryToDay({
        "org_id": orgId,
        "create_date": todayStr,
      });

      // Fetch yesterday's data
      List<ItemsSummaryToDay> yesterdayData = [];
      try {
        yesterdayData = await SummaryFuture().apiGetSummaryToDay({
          "org_id": orgId,
          "create_date": yesterdayStr,
        });
      } catch (e) {
        print("Error fetching yesterday data: $e");
      }

      if (mounted) {
        setState(() {
          // Today's stats - count checked-in people
          if (todayData.isNotEmpty) {
            final today = todayData[0];
            final checkedIn =
                today.ONTIME.length + today.LATE.length + today.OUTSIDE.length;
            _myOrder = checkedIn; // Current user is the latest check-in
            _totalMembers = checkedIn + today.ABSENCE.length;
          }

          // Yesterday's stats
          if (yesterdayData.isNotEmpty) {
            final yday = yesterdayData[0];
            _yesterdayOntime = yday.ONTIME.length;
            _yesterdayLate = yday.LATE.length;
            _yesterdayOutside = yday.OUTSIDE.length;
            _yesterdayAbsence = yday.ABSENCE.length;
          }

          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      print("Error loading summary data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _isLoading ? _buildLoading() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          Text(
            'กำลังโหลดข้อมูล...',
            style: GoogleFonts.kanit(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== Header =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ลงเวลาเข้างานสำเร็จ!',
                  style: GoogleFonts.kanit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.actualTime,
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // ===== My Stats =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                // ลำดับการเข้างาน
                if (_totalMembers > 0)
                  _buildInfoRow(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFFFB300),
                    iconBgColor: const Color(0xFFFFF8E1),
                    text: 'คุณเข้างานเป็นลำดับที่',
                    highlight: '$_myOrder/$_totalMembers',
                    highlightColor: const Color(0xFFFF8F00),
                  ),

                if (_totalMembers > 0) const SizedBox(height: 12),

                // เวลาก่อน/สาย
                if (_timeDiffText.isNotEmpty)
                  _buildInfoRow(
                    icon: _isEarly
                        ? Icons.access_time_filled_rounded
                        : Icons.warning_rounded,
                    iconColor: _isEarly
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                    iconBgColor: _isEarly
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    text: _timeDiffText,
                    highlight: '',
                    highlightColor: Colors.transparent,
                  ),
              ],
            ),
          ),

          // ===== Divider =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: Colors.grey[200]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'สถิติเมื่อวาน',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: Colors.grey[200]),
                ),
              ],
            ),
          ),

          // ===== Yesterday Stats =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  count: _yesterdayOntime,
                  label: 'ทันเวลา',
                  color: const Color(0xFF4CAF50),
                  bgColor: const Color(0xFFE8F5E9),
                  icon: Icons.check_circle_outline_rounded,
                ),
                _buildStatCard(
                  count: _yesterdayLate,
                  label: 'สาย',
                  color: const Color(0xFFFF9800),
                  bgColor: const Color(0xFFFFF3E0),
                  icon: Icons.schedule_rounded,
                ),
                _buildStatCard(
                  count: _yesterdayOutside,
                  label: 'นอกสถานที่',
                  color: const Color(0xFF9C27B0),
                  bgColor: const Color(0xFFF3E5F5),
                  icon: Icons.location_on_outlined,
                ),
                _buildStatCard(
                  count: _yesterdayAbsence,
                  label: 'ไม่ลงชื่อ',
                  color: const Color(0xFFE53935),
                  bgColor: const Color(0xFFFFEBEE),
                  icon: Icons.person_off_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===== OK Button =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ตกลง',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String text,
    required String highlight,
    required Color highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: iconBgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: text),
                  if (highlight.isNotEmpty) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: highlight,
                      style: GoogleFonts.kanit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: highlightColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'คน',
              style: GoogleFonts.kanit(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
