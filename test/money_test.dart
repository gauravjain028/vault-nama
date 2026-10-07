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
    expect(paiseToInput(12345650), '123456.50');
    expect(paiseToInput(50000), '500');
    expect(parseRupees(paiseToInput(9905)), 9905);
  });
}
