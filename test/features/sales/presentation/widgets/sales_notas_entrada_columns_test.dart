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
    check(
      SalesNotasEntradaTableLayout.minWidth(compactChave: false),
    ).equals(
      SalesNotasEntradaTableLayout.documentoWidth +
          SalesNotasEntradaTableLayout.dateWidth +
          SalesNotasEntradaTableLayout.dateWidth +
          SalesNotasEntradaTableLayout.chaveAcessoFullWidth +
          SalesNotasEntradaTableLayout.fornecedorMinWidth +
          SalesNotasEntradaTableLayout.cnpjWidth +
          SalesNotasEntradaTableLayout.valorWidth,
    );
    check(
      SalesNotasEntradaTableLayout.minWidth(compactChave: true),
    ).equals(
      SalesNotasEntradaTableLayout.documentoWidth +
          SalesNotasEntradaTableLayout.dateWidth +
          SalesNotasEntradaTableLayout.dateWidth +
          SalesNotasEntradaTableLayout.chaveAcessoCompactWidth +
          SalesNotasEntradaTableLayout.fornecedorMinWidth +
          SalesNotasEntradaTableLayout.cnpjWidth +
          SalesNotasEntradaTableLayout.valorWidth,
    );
    check(
      SalesNotasEntradaTableLayout.minWidth(compactChave: false),
    ).isGreaterThan(1100);
    check(SalesNotasEntradaResumoTableLayout.minWidth()).equals(
      SalesNotasEntradaResumoTableLayout.codFornecedorWidth +
          SalesNotasEntradaResumoTableLayout.fornecedorMinWidth +
          SalesNotasEntradaResumoTableLayout.cnpjWidth +
          SalesNotasEntradaResumoTableLayout.qtdNotasWidth +
          SalesNotasEntradaResumoTableLayout.ticketMedioWidth +
          SalesNotasEntradaResumoTableLayout.valorWidth,
    );
  });

  test('groups a 44-digit NF-e access key and copies digits only', () {
    const raw = '3526 0314 2001 6600 0187 5500 1000 0001 0012 3456 7890';
    const digits = '35260314200166000187550010000001001234567890';
    check(
      formatSalesNotasEntradaChaveAcesso(raw, compact: false),
    ).equals('3526 0314 2001 6600 0187 5500 1000 0001 0012 3456 7890');
    check(
      formatSalesNotasEntradaChaveAcesso(raw, compact: true),
    ).equals('3526 0314 … 3456 7890');
    check(salesNotasEntradaChaveAcessoClipboardText(raw)).equals(digits);
  });

  test('keeps an irregular access key ungrouped', () {
    check(
      formatSalesNotasEntradaChaveAcesso('NFE-123', compact: false),
    ).equals('NFE-123');
    check(
      formatSalesNotasEntradaChaveAcesso('1234567890123456', compact: true),
    ).equals('12345678…90123456');
    check(salesNotasEntradaChaveAcessoClipboardText('NFE-123')).equals('123');
  });

  test('shows an em dash when the access key is missing', () {
    check(formatSalesNotasEntradaChaveAcesso(null, compact: false)).equals('—');
    check(formatSalesNotasEntradaChaveAcesso('  ', compact: true)).equals('—');
    check(salesNotasEntradaChaveAcessoClipboardText(null)).isNull();
    check(salesNotasEntradaChaveAcessoClipboardText('   ')).isNull();
  });
}
