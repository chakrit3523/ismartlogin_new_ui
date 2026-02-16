import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ismart_login/src/features/leave/domain/usecases/leave_date_calculator.dart';

void main() {
  group('calculateLeaveAmount', () {
    test('single day returns 1', () {
      final value = calculateLeaveAmount(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 16),
        isHalfDay: false,
        isTimeRange: false,
      );

      expect(value, 1);
    });

    test('range day is inclusive', () {
      final value = calculateLeaveAmount(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 18),
        isHalfDay: false,
        isTimeRange: false,
      );

      expect(value, 3);
    });

    test('half day returns 0.5', () {
      final value = calculateLeaveAmount(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 16),
        isHalfDay: true,
        isTimeRange: false,
      );

      expect(value, 0.5);
    });

    test('time range returns hours', () {
      final value = calculateLeaveAmount(
        startDate: DateTime(2026, 2, 16),
        endDate: DateTime(2026, 2, 16),
        isHalfDay: false,
        isTimeRange: true,
        startTime: const TimeOfDay(hour: 8, minute: 30),
        endTime: const TimeOfDay(hour: 11, minute: 0),
      );

      expect(value, 2.5);
    });
  });
}
