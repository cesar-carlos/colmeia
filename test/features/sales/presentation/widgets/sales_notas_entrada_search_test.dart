import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes blank supplier search terms to null', () {
    expect(SalesNotasEntradaSearch.normalize(null), isNull);
    expect(SalesNotasEntradaSearch.normalize(''), isNull);
    expect(SalesNotasEntradaSearch.normalize('   '), isNull);
    expect(SalesNotasEntradaSearch.normalize(12), isNull);
    expect(SalesNotasEntradaSearch.normalize('  Mel  '), 'Mel');
  });

  test('uses a 400ms debounce so agent SQL is not hit per keystroke', () {
    expect(
      SalesNotasEntradaSearch.debounce,
      const Duration(milliseconds: 400),
    );
  });
}
