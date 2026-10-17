import 'package:intl/intl.dart';

/// All currency operations use integer paise (1 INR = 100 paise).
/// Parsing from text goes directly to int — no intermediate double.
class CurrencyUtils {
  CurrencyUtils._();

  /// Parse a user-typed string to paise.
  ///
  /// "1,234.5"  → 123450
  /// "99"       → 9900
  /// "0.5"      → 50
  /// ""         → null
  /// "abc"      → null
  /// "1.234"    → null (more than 2 decimal places)
  static int? parseToPaise(String input) {
    final s = input.replaceAll(',', '').trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
    if (m == null) return null;
    final rupees = int.parse(m.group(1)!);
    final fraction = (m.group(2) ?? '').padRight(2, '0');
    return rupees * 100 + int.parse(fraction);
  }

  /// Format paise to display string with Indian digit grouping.
  /// 124500000 → "₹12,45,000.00"
  static String format(int paise) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
          .format(paise / 100);

  /// Alias for format
  static String formatRupees(int paise) => format(paise);

  /// Format without the ₹ symbol (for text fields, etc.)
  static String formatPlain(int paise) =>
      NumberFormat('#,##,##0.00', 'en_IN').format(paise / 100);
}
