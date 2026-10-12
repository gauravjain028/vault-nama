import 'package:intl/intl.dart';

final _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

final _wholeRupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Formats paise as rupees with Indian digit grouping, e.g. ₹1,23,456 or
/// ₹1,23,456.50; whole amounts drop the paise.
String formatPaise(int paise) => paise % 100 == 0
    ? _wholeRupees.format(paise ~/ 100)
    : _rupees.format(paise / 100);

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

/// Short rupee amount for chart labels and hints: ₹850, ₹45.5K, ₹1.5L,
/// ₹2.35Cr (Indian lakh and crore).
String formatCompact(int paise) {
  final rupees = paise / 100;
  String trim(double v) {
    final s = v.toStringAsFixed(v >= 100 ? 0 : (v >= 10 ? 1 : 2));
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  if (rupees >= 1e7) return '₹${trim(rupees / 1e7)}Cr';
  if (rupees >= 1e5) return '₹${trim(rupees / 1e5)}L';
  if (rupees >= 1e3) return '₹${trim(rupees / 1e3)}K';
  return '₹${rupees.round()}';
}

/// The amount in words, e.g. "1.5 lakh", "2.35 crore"; null under ₹1,000.
String? amountInWords(int paise) {
  final rupees = paise / 100;
  String trim(double v) =>
      v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  if (rupees >= 1e7) return '${trim(rupees / 1e7)} crore';
  if (rupees >= 1e5) return '${trim(rupees / 1e5)} lakh';
  if (rupees >= 1e3) return '${trim(rupees / 1e3)} thousand';
  return null;
}
