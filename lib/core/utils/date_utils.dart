import 'package:intl/intl.dart';

/// Helpers for YYYY-MM-DD date strings used in the database.
class AppDateUtils {
  AppDateUtils._();

  static final _dbFormat = DateFormat('yyyy-MM-dd');
  static final _displayFormat = DateFormat('dd MMM yyyy');
  static final _shortFormat = DateFormat('dd/MM');

  /// Today as 'YYYY-MM-DD'.
  static String today() => _dbFormat.format(DateTime.now());

  /// DateTime to DB string.
  static String toDbString(DateTime date) => _dbFormat.format(date);

  /// DB string to DateTime.
  static DateTime fromDbString(String s) => _dbFormat.parse(s);

  /// DB string to display format: "14 Oct 2026"
  static String toDisplay(String dbDate) =>
      _displayFormat.format(_dbFormat.parse(dbDate));

  /// DB string to short format: "14/10"
  static String toShort(String dbDate) =>
      _shortFormat.format(_dbFormat.parse(dbDate));
}
