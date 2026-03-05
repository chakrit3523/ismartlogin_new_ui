import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ismart_login/src/features/leave/domain/usecases/leave_date_calculator.dart';

void main() {
  group('validateLeaveDateSelection', () {
    test('end date cannot be before start date', () {
      final error = validateLeaveDateSelection(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 15),
        isHalfDay: false,
        isTimeRange: false,
      );

      expect(error, LeaveDateValidationError.endDateBeforeStartDate);
    });

    test('half day must be single date', () {
      final error = validateLeaveDateSelection(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 17),
        isHalfDay: true,
        isTimeRange: false,
      );

      expect(error, LeaveDateValidationError.halfDayRequiresSingleDate);
    });

    test('time range requires start/end time', () {
      final error = validateLeaveDateSelection(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 16),
        isHalfDay: false,
        isTimeRange: true,
      );

      expect(error, LeaveDateValidationError.missingStartTime);
    });

    test('end time must be after start time', () {
      final error = validateLeaveDateSelection(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 16),
        isHalfDay: false,
        isTimeRange: true,
        startTime: const TimeOfDay(hour: 13, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 30),
      );

      expect(error, LeaveDateValidationError.endTimeMustBeAfterStartTime);
    });

    test('valid time range passes validation', () {
      final error = validateLeaveDateSelection(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 16),
        isHalfDay: false,
        isTimeRange: true,
        startTime: const TimeOfDay(hour: 8, minute: 30),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      );

      expect(error, isNull);
    });
  });
}
