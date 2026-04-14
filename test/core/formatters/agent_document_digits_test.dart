import 'package:colmeia/core/formatters/agent_document_digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('digitsOnlyDocument strips non-digits', () {
    expect(digitsOnlyDocument('59.261.947/0001-07'), '59261947000107');
    expect(digitsOnlyDocument('123'), '123');
    expect(digitsOnlyDocument(''), null);
    expect(digitsOnlyDocument(null), null);
    expect(digitsOnlyDocument('abc'), null);
  });
}
