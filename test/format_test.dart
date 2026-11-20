import 'package:cnno_app/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rm() ringgit formatting (BR-07)', () {
    test('always shows two decimal places', () {
      expect(rm(8), 'RM 8.00');
      expect(rm(17.5), 'RM 17.50');
      expect(rm(0), 'RM 0.00');
    });

    test('rounds to the nearest sen', () {
      expect(rm(10.005 + 0.001), 'RM 10.01');
      expect(rm(54.994), 'RM 54.99');
    });
  });

  group('dates', () {
    final d = DateTime(2026, 11, 21, 15, 45);

    test('shortDate shows day and month', () {
      expect(shortDate(d), '21 Nov');
    });

    test('longDate adds the year', () {
      expect(longDate(d), '21 Nov 2026');
    });
  });

  group('earliestPreorderDate (FR-07, BR-03)', () {
    test('ignores the time of day', () {
      expect(earliestPreorderDate(DateTime(2026, 11, 20, 0, 1), 1), DateTime(2026, 11, 21));
      expect(earliestPreorderDate(DateTime(2026, 11, 20, 23, 59), 1), DateTime(2026, 11, 21));
    });

    test('rolls over month and year ends', () {
      expect(earliestPreorderDate(DateTime(2026, 11, 30, 9), 1), DateTime(2026, 12, 1));
      expect(earliestPreorderDate(DateTime(2026, 12, 31, 9), 1), DateTime(2027, 1, 1));
    });

    test('supports longer lead times', () {
      expect(earliestPreorderDate(DateTime(2026, 11, 20, 9), 3), DateTime(2026, 11, 23));
    });
  });
}
