import 'package:flutter_test/flutter_test.dart';
import 'package:lexledger/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils Tests', () {
    test('parseToPaise parses standard and fractional inputs correctly', () {
      expect(CurrencyUtils.parseToPaise('100'), equals(10000));
      expect(CurrencyUtils.parseToPaise('45.5'), equals(4550));
      expect(CurrencyUtils.parseToPaise('45.50'), equals(4550));
      expect(CurrencyUtils.parseToPaise('0.25'), equals(25));
      expect(CurrencyUtils.parseToPaise('1,500.75'), equals(150075));
      expect(CurrencyUtils.parseToPaise('0'), equals(0));
    });

    test('parseToPaise returns null for invalid inputs', () {
      expect(CurrencyUtils.parseToPaise(''), isNull);
      expect(CurrencyUtils.parseToPaise('abc'), isNull);
      expect(CurrencyUtils.parseToPaise('1.234'), isNull); // more than 2 decimal digits
      expect(CurrencyUtils.parseToPaise('-50'), isNull);
    });

    test('format produces Indian formatted string', () {
      final formatted = CurrencyUtils.format(1245000); // 12,450.00
      expect(formatted, contains('12,450.00'));
    });
  });
}
