import 'package:intl/intl.dart';

final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Formats paise as rupees with Indian digit grouping, e.g. ₹1,23,456.00.
String formatPaise(int paise) => _rupees.format(paise / 100);

/// Parses a rupee amount typed by the user ("1,23,456.5", "₹ 500") into
/// paise. Returns null for anything that isn't a non-negative amount with at
/// most two decimal places.
int? parseRupees(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

/// Shows paise as a plain editable amount, e.g. 12345650 -> "123456.50".
String paiseToInput(int paise) {
  final whole = paise ~/ 100;
  final fraction = paise % 100;
  return fraction == 0
      ? '$whole'
      : '$whole.${fraction.toString().padLeft(2, '0')}';
}
