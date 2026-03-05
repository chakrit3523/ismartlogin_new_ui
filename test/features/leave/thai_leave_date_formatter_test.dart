import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ismart_login/src/features/leave/presentation/helpers/thai_leave_date_formatter.dart';

void main() {
  group('ThaiLeaveDateFormatter', () {
    test('formats thai short date', () {
      final value =
          ThaiLeaveDateFormatter.toThaiShortDate(DateTime(2026, 2, 16));
      expect(value, 'จ. 16 ก.พ.');
    });

    test('formats buddhist year', () {
      final value = ThaiLeaveDateFormatter.toThaiShortDate(
        DateTime(2026, 2, 16),
        includeBuddhistYear: true,
      );
      expect(value, 'จ. 16 ก.พ. 2569');
    });

    test('formats range label', () {
      final value = ThaiLeaveDateFormatter.toThaiDateRange(
        DateTime(2026, 2, 16),
        DateTime(2026, 2, 18),
      );
      expect(value, 'จ. 16 ก.พ. - พ. 18 ก.พ.');
    });

    test('formats time label HH:mm', () {
      const time = TimeOfDay(hour: 8, minute: 5);
      expect(ThaiLeaveDateFormatter.toTimeLabel(time), '08:05');
    });
  });
}
