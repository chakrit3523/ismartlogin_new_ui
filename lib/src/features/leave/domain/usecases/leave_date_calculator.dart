import 'package:flutter/material.dart';

enum LeaveDateValidationError {
  endDateBeforeStartDate,
  halfDayRequiresSingleDate,
  timeRangeRequiresSingleDate,
  missingStartTime,
  missingEndTime,
  endTimeMustBeAfterStartTime,
  halfDayAndTimeRangeConflict,
}

LeaveDateValidationError? validateLeaveDateSelection({
  required DateTime startDate,
  required DateTime endDate,
  required bool isHalfDay,
  required bool isTimeRange,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
}) {
  final start = _dateOnly(startDate);
  final end = _dateOnly(endDate);

  if (end.isBefore(start)) {
    return LeaveDateValidationError.endDateBeforeStartDate;
  }

  if (isHalfDay && isTimeRange) {
    return LeaveDateValidationError.halfDayAndTimeRangeConflict;
  }

  if (isHalfDay && !_isSameDate(start, end)) {
    return LeaveDateValidationError.halfDayRequiresSingleDate;
  }

  if (isTimeRange) {
    if (!_isSameDate(start, end)) {
      return LeaveDateValidationError.timeRangeRequiresSingleDate;
    }
    if (startTime == null) {
      return LeaveDateValidationError.missingStartTime;
    }
    if (endTime == null) {
      return LeaveDateValidationError.missingEndTime;
    }

    final startMinutes = _toMinutes(startTime);
    final endMinutes = _toMinutes(endTime);
    if (endMinutes <= startMinutes) {
      return LeaveDateValidationError.endTimeMustBeAfterStartTime;
    }
  }

  return null;
}

String mapLeaveDateValidationError(LeaveDateValidationError error) {
  switch (error) {
    case LeaveDateValidationError.endDateBeforeStartDate:
      return 'วันสิ้นสุดห้ามน้อยกว่าวันเริ่ม';
    case LeaveDateValidationError.halfDayRequiresSingleDate:
      return 'การลาครึ่งวันต้องเลือกวันเดียว';
    case LeaveDateValidationError.timeRangeRequiresSingleDate:
      return 'การลาแบบรายชั่วโมงต้องเลือกวันเดียว';
    case LeaveDateValidationError.missingStartTime:
      return 'กรุณาเลือกเวลาเริ่ม';
    case LeaveDateValidationError.missingEndTime:
      return 'กรุณาเลือกเวลาสิ้นสุด';
    case LeaveDateValidationError.endTimeMustBeAfterStartTime:
      return 'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม';
    case LeaveDateValidationError.halfDayAndTimeRangeConflict:
      return 'ไม่สามารถเลือกครึ่งวันพร้อมกับรายชั่วโมงได้';
  }
}

/// Returns leave amount:
/// - full/half day mode => days
/// - time range mode => hours
/// Throws [ArgumentError] when validation fails.
double calculateLeaveAmount({
  required DateTime startDate,
  required DateTime endDate,
  required bool isHalfDay,
  required bool isTimeRange,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
}) {
  final validation = validateLeaveDateSelection(
    startDate: startDate,
    endDate: endDate,
    isHalfDay: isHalfDay,
    isTimeRange: isTimeRange,
    startTime: startTime,
    endTime: endTime,
  );

  if (validation != null) {
    throw ArgumentError(mapLeaveDateValidationError(validation));
  }

  if (isHalfDay) {
    return 0.5;
  }

  if (isTimeRange) {
    final startMinutes = _toMinutes(startTime!);
    final endMinutes = _toMinutes(endTime!);
    final hours = (endMinutes - startMinutes) / 60.0;
    return _roundTo2(hours);
  }

  final start = _dateOnly(startDate);
  final end = _dateOnly(endDate);
  return end.difference(start).inDays + 1.0;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

double _roundTo2(double value) => double.parse(value.toStringAsFixed(2));
