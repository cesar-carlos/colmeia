import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('formats CPF and CNPJ digits for the tax-id column', () {
    check(formatSalesNotasEntradaTaxId('52998224725')).equals('529.982.247-25');
    check(
      formatSalesNotasEntradaTaxId('19131243000197'),
    ).equals('19.131.243/0001-97');
  });

  test('formats midnight launch dates without a clock time', () {
    check(
      formatSalesNotasEntradaLaunchDate(DateTime(2026, 9, 4)),
    ).equals('04/09/2026');
    check(
      formatSalesNotasEntradaLaunchDate(DateTime(2026, 9, 4, 10, 30)),
    ).equals('04/09/2026 10:30');
  });

  test('keeps an unrecognized tax-id value unchanged', () {
    check(formatSalesNotasEntradaTaxId('ABC')).equals('ABC');
    check(formatSalesNotasEntradaTaxId(null)).equals('');
  });

  test('reserves enough width to overflow compact viewports', () {
    check(SalesNotasEntradaTableLayout.minWidth()).equals(
      SalesNotasEntradaTableLayout.documentoWidth +
          SalesNotasEntradaTableLayout.dateWidth +
          SalesNotasEntradaTableLayout.dateWidth +
          SalesNotasEntradaTableLayout.lancamentoWidth +
          SalesNotasEntradaTableLayout.codFornecedorWidth +
          SalesNotasEntradaTableLayout.fornecedorMinWidth +
          SalesNotasEntradaTableLayout.cnpjWidth +
          SalesNotasEntradaTableLayout.valorWidth,
    );
    check(SalesNotasEntradaTableLayout.minWidth()).isGreaterThan(1100);
    check(SalesNotasEntradaResumoTableLayout.minWidth()).equals(
      SalesNotasEntradaResumoTableLayout.codFornecedorWidth +
          SalesNotasEntradaResumoTableLayout.fornecedorMinWidth +
          SalesNotasEntradaResumoTableLayout.cnpjWidth +
          SalesNotasEntradaResumoTableLayout.qtdNotasWidth +
          SalesNotasEntradaResumoTableLayout.ticketMedioWidth +
          SalesNotasEntradaResumoTableLayout.valorWidth,
    );
  });
}
