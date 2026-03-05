import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Thai Buddhist Era Date Range Picker
/// Displays years in พ.ศ. format (e.g. 2569 instead of 2026)
/// Matches the desired UI with bottom bar showing start/end dates and "เสร็จสิ้น" button

class ThaiDateRangePickerDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<DateTime> bookedLeaveDates;

  const ThaiDateRangePickerDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.firstDate,
    required this.lastDate,
    this.bookedLeaveDates = const {},
  });

  @override
  State<ThaiDateRangePickerDialog> createState() =>
      _ThaiDateRangePickerDialogState();
}

class _ThaiDateRangePickerDialogState extends State<ThaiDateRangePickerDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _focusMonth;
  bool _selectingEnd = false; // false=selecting start, true=selecting end
  late ScrollController _scrollController;
  late List<DateTime> _months;

  static const List<String> _thaiMonthFull = [
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
    'ธันวาคม',
  ];

  static const List<String> _thaiMonthShort = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  static const List<String> _thaiWeekdayShort = [
    'อา.',
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    _focusMonth = DateTime(_startDate.year, _startDate.month);
    _generateMonths();

    // Calculate initial scroll offset to show current month
    final currentMonthIndex = _months.indexWhere(
      (m) => m.year == _focusMonth.year && m.month == _focusMonth.month,
    );

    _scrollController = ScrollController(
      initialScrollOffset:
          currentMonthIndex > 0 ? (currentMonthIndex * 328.0) : 0,
    );
  }

  void _generateMonths() {
    _months = [];
    DateTime current = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);

    while (!current.isAfter(lastMonth)) {
      _months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _buddhistYear(int year) => year + 543;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime day) {
    if (_isSameDay(day, _startDate) || _isSameDay(day, _endDate)) return true;
    return day.isAfter(_startDate) && day.isBefore(_endDate);
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (!_selectingEnd) {
        // Selecting start date
        _startDate = day;
        _endDate = day;
        _selectingEnd = true;
      } else {
        // Selecting end date
        if (day.isBefore(_startDate)) {
          _startDate = day;
          _endDate = day;
          _selectingEnd = true;
        } else {
          _endDate = day;
          _selectingEnd = false;
        }
      }
    });
  }

  String _formatShortDate(DateTime date) {
    final weekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    final weekday = weekdays[date.weekday - 1];
    final month = _thaiMonthShort[date.month - 1];
    return '$weekday ${date.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4285F4); // Google Blue

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'เลือกวันที่',
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Weekday header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _thaiWeekdayShort
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.kanit(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Calendar scroll
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8),
              itemCount: _months.length,
              itemExtent: 328,
              itemBuilder: (context, index) {
                return _buildMonth(_months[index], primaryColor);
              },
            ),
          ),

          // Bottom bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date display row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันเริ่มต้น',
                                style: GoogleFonts.kanit(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatShortDate(_startDate),
                                style: GoogleFonts.kanit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward,
                            color: Colors.grey[400], size: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'วันสิ้นสุด',
                                style: GoogleFonts.kanit(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatShortDate(_endDate),
                                style: GoogleFonts.kanit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            DateTimeRange(start: _startDate, end: _endDate),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'เสร็จสิ้น',
                          style: GoogleFonts.kanit(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonth(DateTime month, Color primaryColor) {
    final buddhistYear = _buddhistYear(month.year);
    final monthName = _thaiMonthFull[month.month - 1];
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;

    return SizedBox(
      height: 328,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // Month/Year header
            SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  '$monthName $buddhistYear',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Days grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDaysGrid(
                month,
                daysInMonth,
                firstWeekday,
                primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysGrid(
    DateTime month,
    int daysInMonth,
    int firstWeekday,
    Color primaryColor,
  ) {
    final rows = <Widget>[];
    int dayCounter = 1;
    final totalCells = 42; // Force 6 weeks (6 * 7 = 42) for constant height

    for (int i = 0; i < totalCells; i += 7) {
      final rowCells = <Widget>[];
      for (int j = 0; j < 7; j++) {
        final cellIndex = i + j;
        if (cellIndex < firstWeekday || dayCounter > daysInMonth) {
          rowCells.add(const Expanded(child: SizedBox(height: 44)));
        } else {
          final day = DateTime(month.year, month.month, dayCounter);
          rowCells.add(_buildDayCell(day, primaryColor));
          dayCounter++;
        }
      }
      rows.add(Row(children: rowCells));
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(DateTime day, Color primaryColor) {
    final isStart = _isSameDay(day, _startDate);
    final isEnd = _isSameDay(day, _endDate);
    final isInRange = _isInRange(day);
    final isToday = _isSameDay(day, DateTime.now());
    final isSelected = isStart || isEnd;
    final isRangeMiddle = isInRange && !isSelected;
    final isBooked = widget.bookedLeaveDates.any((bd) => _isSameDay(bd, day));

    return Expanded(
      child: GestureDetector(
        onTap: () => _onDayTap(day),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            // Range background
            color: isRangeMiddle
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            // Only half-fill for start/end edges when there's a range
            gradient: (isStart && !_isSameDay(_startDate, _endDate))
                ? LinearGradient(colors: [
                    Colors.transparent,
                    primaryColor.withValues(alpha: 0.1),
                  ])
                : (isEnd && !_isSameDay(_startDate, _endDate))
                    ? LinearGradient(colors: [
                        primaryColor.withValues(alpha: 0.1),
                        Colors.transparent,
                      ])
                    : null,
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: GoogleFonts.kanit(
                      fontSize: 15,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? primaryColor
                              : Colors.black87,
                    ),
                  ),
                  if (isBooked)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the Thai date range picker as a full-screen dialog
Future<DateTimeRange?> showThaiDateRangePicker({
  required BuildContext context,
  required DateTime initialStart,
  required DateTime initialEnd,
  DateTime? firstDate,
  DateTime? lastDate,
  Set<DateTime> bookedLeaveDates = const {},
}) {
  return Navigator.of(context).push<DateTimeRange>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => ThaiDateRangePickerDialog(
        initialStart: initialStart,
        initialEnd: initialEnd,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2100),
        bookedLeaveDates: bookedLeaveDates,
      ),
    ),
  );
}
