import 'package:intl/intl.dart';

/// Ringgit amount, e.g. "RM 8.00" (BR-07).
String rm(double amount) => 'RM ${amount.toStringAsFixed(2)}';

String shortDate(DateTime d) => DateFormat('d MMM').format(d);

String longDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// Earliest date a customer may choose for a preorder (BR-03).
DateTime earliestPreorderDate(DateTime now, int leadDays) {
  final today = DateTime(now.year, now.month, now.day);
  return today.add(Duration(days: leadDays));
}
