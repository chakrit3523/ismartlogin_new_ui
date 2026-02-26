import 'package:flutter/material.dart';

enum HalfDayPeriod { morning, afternoon }

@immutable
class LeaveDateSelection {
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isHalfDay;
  final bool isTimeRange;
  final HalfDayPeriod? halfDayPeriod;

  const LeaveDateSelection({
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.startTime,
    this.endTime,
    this.isHalfDay = false,
    this.isTimeRange = false,
    this.halfDayPeriod,
  });

  LeaveDateSelection copyWith({
    DateTime? startDate,
    DateTime? endDate,
    double? totalDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isHalfDay,
    bool? isTimeRange,
    HalfDayPeriod? halfDayPeriod,
    bool clearStartTime = false,
    bool clearEndTime = false,
    bool clearHalfDayPeriod = false,
  }) {
    return LeaveDateSelection(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      isHalfDay: isHalfDay ?? this.isHalfDay,
      isTimeRange: isTimeRange ?? this.isTimeRange,
      halfDayPeriod:
          clearHalfDayPeriod ? null : (halfDayPeriod ?? this.halfDayPeriod),
    );
  }

  static LeaveDateSelection initial({DateTime? date}) {
    final now = _dateOnly(date ?? DateTime.now());
    return LeaveDateSelection(
      startDate: now,
      endDate: now,
      totalDays: 1,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
