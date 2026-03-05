import 'package:flutter/material.dart';

class ThaiLeaveDateFormatter {
  static const List<String> _thaiWeekdayShort = [
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
    'อา.',
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

  static String toThaiShortDate(DateTime date,
      {bool includeBuddhistYear = false}) {
    final weekday = _thaiWeekdayShort[date.weekday - 1];
    final month = _thaiMonthShort[date.month - 1];
    final day = date.day;

    if (!includeBuddhistYear) {
      return '$weekday $day $month';
    }

    final buddhistYear = toBuddhistYear(date.year);
    return '$weekday $day $month $buddhistYear';
  }

  static String toThaiDateRange(
    DateTime start,
    DateTime end, {
    bool includeBuddhistYear = false,
  }) {
    final startLabel =
        toThaiShortDate(start, includeBuddhistYear: includeBuddhistYear);
    final endLabel =
        toThaiShortDate(end, includeBuddhistYear: includeBuddhistYear);

    if (_isSameDate(start, end)) {
      return '$startLabel - $endLabel';
    }

    return '$startLabel - $endLabel';
  }

  static int toBuddhistYear(int gregorianYear) => gregorianYear + 543;

  static String toTimeLabel(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
