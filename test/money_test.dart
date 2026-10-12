import 'package:flutter_test/flutter_test.dart';
import 'package:vault_nama/util/money.dart';

void main() {
  test('parses rupee input into paise', () {
    expect(parseRupees('500'), 50000);
    expect(parseRupees('1,23,456.5'), 12345650);
    expect(parseRupees('₹ 99.05'), 9905);
    expect(parseRupees('0'), 0);
  });

  test('rejects invalid amounts', () {
    expect(parseRupees(''), isNull);
    expect(parseRupees('-5'), isNull);
    expect(parseRupees('12.345'), isNull);
    expect(parseRupees('abc'), isNull);
  });

  test('formats with Indian grouping and round-trips through input', () {
    expect(formatPaise(12345650), '₹1,23,456.50');
    expect(formatPaise(12345600), '₹1,23,456');
    expect(paiseToInput(12345650), '123456.50');
    expect(paiseToInput(50000), '500');
    expect(parseRupees(paiseToInput(9905)), 9905);
  });

  test('compact amounts and words use lakh and crore', () {
    expect(formatCompact(85000), '₹850');
    expect(formatCompact(4550000), '₹45.5K');
    expect(formatCompact(15000000), '₹1.5L');
    expect(formatCompact(2350000000), '₹2.35Cr');
    expect(amountInWords(15000000), '1.5 lakh');
    expect(amountInWords(2350000000), '2.35 crore');
    expect(amountInWords(50000), isNull);
  });
}
