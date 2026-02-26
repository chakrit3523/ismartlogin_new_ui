import 'package:flutter/material.dart';
import 'package:ismart_login/src/features/leave/domain/entities/leave_date_selection.dart';
import 'package:ismart_login/src/features/leave/domain/usecases/leave_date_calculator.dart';

class LeaveDateRangePickerController extends ChangeNotifier {
  LeaveDateRangePickerController({
    DateTime? initialStart,
    DateTime? initialEnd,
  })  : _startDate = _dateOnly(initialStart ?? DateTime.now()),
        _endDate = _dateOnly(initialEnd ?? initialStart ?? DateTime.now());

  DateTime _startDate;
  DateTime _endDate;
  bool _isHalfDay = false;
  bool _isTimeRange = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  HalfDayPeriod? _halfDayPeriod;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isHalfDay => _isHalfDay;
  bool get isTimeRange => _isTimeRange;
  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  HalfDayPeriod? get halfDayPeriod => _halfDayPeriod;

  void setDateRange(DateTime start, DateTime end) {
    final startOnly = _dateOnly(start);
    final endOnly = _dateOnly(end);
    _startDate = startOnly;
    _endDate = endOnly.isBefore(startOnly) ? startOnly : endOnly;

    if (!_isSameDate(_startDate, _endDate)) {
      _isHalfDay = false;
      _isTimeRange = false;
      _startTime = null;
      _endTime = null;
    }

    notifyListeners();
  }

  void setHalfDay(bool value) {
    _isHalfDay = value;
    if (value) {
      _isTimeRange = false;
      _startTime = null;
      _endTime = null;
      _endDate = _startDate;
      _halfDayPeriod ??= HalfDayPeriod.morning;
    } else {
      _halfDayPeriod = null;
    }
    notifyListeners();
  }

  void setHalfDayPeriod(HalfDayPeriod value) {
    _halfDayPeriod = value;
    notifyListeners();
  }

  void setTimeRange(bool value) {
    _isTimeRange = value;
    if (value) {
      _isHalfDay = false;
      _endDate = _startDate;
    } else {
      _startTime = null;
      _endTime = null;
    }
    notifyListeners();
  }

  void setStartTime(TimeOfDay? value) {
    _startTime = value;
    notifyListeners();
  }

  void setEndTime(TimeOfDay? value) {
    _endTime = value;
    notifyListeners();
  }

  LeaveDateValidationError? validate() {
    return validateLeaveDateSelection(
      startDate: _startDate,
      endDate: _endDate,
      isHalfDay: _isHalfDay,
      isTimeRange: _isTimeRange,
      startTime: _startTime,
      endTime: _endTime,
    );
  }

  LeaveDateSelection toSelection() {
    final amount = calculateLeaveAmount(
      startDate: _startDate,
      endDate: _endDate,
      isHalfDay: _isHalfDay,
      isTimeRange: _isTimeRange,
      startTime: _startTime,
      endTime: _endTime,
    );

    return LeaveDateSelection(
      startDate: _startDate,
      endDate: _endDate,
      totalDays: amount,
      startTime: _startTime,
      endTime: _endTime,
      isHalfDay: _isHalfDay,
      isTimeRange: _isTimeRange,
      halfDayPeriod: _isHalfDay ? _halfDayPeriod : null,
    );
  }

  void applySelection(LeaveDateSelection value) {
    _startDate = _dateOnly(value.startDate);
    _endDate = _dateOnly(value.endDate);
    _isHalfDay = value.isHalfDay;
    _isTimeRange = value.isTimeRange;
    _startTime = value.startTime;
    _endTime = value.endTime;
    _halfDayPeriod = value.halfDayPeriod;
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
