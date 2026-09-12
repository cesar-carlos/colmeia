import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';

class SalesNotasEntradaColumnLabels {
  const SalesNotasEntradaColumnLabels({
    required this.documento,
    required this.emissao,
    required this.entrada,
    required this.lancamento,
    required this.codFornecedor,
    required this.fornecedor,
    required this.cnpjCpf,
    required this.valorTotal,
  });

  factory SalesNotasEntradaColumnLabels.fromL10n(AppLocalizations l10n) {
    return SalesNotasEntradaColumnLabels(
      documento: l10n.salesNotasEntradaColumnDocumento,
      emissao: l10n.salesNotasEntradaColumnEmissao,
      entrada: l10n.salesNotasEntradaColumnEntrada,
      lancamento: l10n.salesNotasEntradaColumnLancamento,
      codFornecedor: l10n.salesNotasEntradaColumnCodFornecedor,
      fornecedor: l10n.salesNotasEntradaColumnFornecedor,
      cnpjCpf: l10n.salesNotasEntradaColumnCnpjCpf,
      valorTotal: l10n.salesNotasEntradaColumnValorTotal,
    );
  }

  final String documento;
  final String emissao;
  final String entrada;
  final String lancamento;
  final String codFornecedor;
  final String fornecedor;
  final String cnpjCpf;
  final String valorTotal;
}

/// Minimum column widths so labels stay on one line; leftover width goes to
/// the supplier name. The sum forces horizontal overflow on compact rails.
abstract final class SalesNotasEntradaTableLayout {
  static const double documentoWidth = 112;
  static const double dateWidth = 120;
  static const double lancamentoWidth = 136;
  static const double codFornecedorWidth = 112;
  static const double fornecedorMinWidth = 320;
  static const double cnpjWidth = 168;
  static const double valorWidth = 136;

  static double minWidth() {
    return documentoWidth +
        dateWidth +
        dateWidth +
        lancamentoWidth +
        codFornecedorWidth +
        fornecedorMinWidth +
        cnpjWidth +
        valorWidth;
  }

  /// Row padding uses [AppThemeTokens.gapSm] on each horizontal side.
  static double minScrollContentWidth(AppThemeTokens tokens) =>
      minWidth() + 2 * tokens.gapSm;
}

String formatSalesNotasEntradaLaunchDate(Object? value) {
  if (value is! DateTime) {
    return '';
  }
  final local = value.toLocal();
  final hasClockTime =
      local.hour != 0 ||
      local.minute != 0 ||
      local.second != 0 ||
      local.millisecond != 0;
  return hasClockTime
      ? AppBrFormatters.shortDateTime(local)
      : AppBrFormatters.shortDate(local);
}

String formatSalesNotasEntradaDate(Object? value) =>
    value is DateTime ? AppBrFormatters.shortDate(value.toLocal()) : '';

String formatSalesNotasEntradaCurrency(Object? value) =>
    value is num ? AppBrFormatters.currency(value) : '';

String formatSalesNotasEntradaTaxId(Object? value) {
  if (value is! String) {
    return '';
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final digits = AppBrFormatters.digitsOnly(trimmed);
  try {
    if (digits.length == 11) {
      return AppBrFormatters.cpf(digits);
    }
    if (digits.length == 14) {
      return AppBrFormatters.cnpj(digits);
    }
  } on Object {
    return trimmed;
  }
  return trimmed;
}
