import 'dart:math' as math;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';

class SalesNotasEntradaColumnLabels {
  const SalesNotasEntradaColumnLabels({
    required this.documento,
    required this.chaveAcesso,
    required this.emissao,
    required this.entrada,
    required this.codFornecedor,
    required this.fornecedor,
    required this.cnpjCpf,
    required this.qtdNotas,
    required this.ticketMedio,
    required this.valorTotal,
  });

  factory SalesNotasEntradaColumnLabels.fromL10n(AppLocalizations l10n) {
    return SalesNotasEntradaColumnLabels(
      documento: l10n.salesNotasEntradaColumnDocumento,
      chaveAcesso: l10n.salesNotasEntradaColumnChaveAcesso,
      emissao: l10n.salesNotasEntradaColumnEmissao,
      entrada: l10n.salesNotasEntradaColumnEntrada,
      codFornecedor: l10n.salesNotasEntradaColumnCodFornecedor,
      fornecedor: l10n.salesNotasEntradaColumnFornecedor,
      cnpjCpf: l10n.salesNotasEntradaColumnCnpjCpf,
      qtdNotas: l10n.salesNotasEntradaColumnQtdNotas,
      ticketMedio: l10n.salesNotasEntradaColumnTicketMedio,
      valorTotal: l10n.salesNotasEntradaColumnValorTotal,
    );
  }

  final String documento;
  final String chaveAcesso;
  final String emissao;
  final String entrada;
  final String codFornecedor;
  final String fornecedor;
  final String cnpjCpf;
  final String qtdNotas;
  final String ticketMedio;
  final String valorTotal;
}

/// Minimum column widths so labels stay on one line; leftover width goes to
/// the supplier name. The sum forces horizontal overflow on compact rails.
abstract final class SalesNotasEntradaTableLayout {
  static const double documentoWidth = 112;
  static const double dateWidth = 120;
  static const double codFornecedorWidth = 112;
  static const double fornecedorMinWidth = 320;
  static const double cnpjWidth = 168;
  static const double valorWidth = 136;

  static const double chaveAcessoCopyIconSize = 16;
  static const double chaveAcessoCopyButtonSize = 28;
  static const double chaveAcessoCopyGap = 4;
  static const double chaveAcessoCopySlotWidth =
      chaveAcessoCopyButtonSize + chaveAcessoCopyGap;
  static const double chaveAcessoFullWidth = 520;
  static const double chaveAcessoCompactWidth = 240;
  static const Duration chaveAcessoCopiedFeedbackDuration = Duration(
    seconds: 2,
  );

  static double chaveAcessoWidth({required bool compactChave}) {
    return compactChave ? chaveAcessoCompactWidth : chaveAcessoFullWidth;
  }

  static double minWidth({required bool compactChave}) {
    return documentoWidth +
        dateWidth +
        dateWidth +
        chaveAcessoWidth(compactChave: compactChave) +
        fornecedorMinWidth +
        cnpjWidth +
        valorWidth;
  }

  /// Row padding uses [AppThemeTokens.gapSm] on each horizontal side.
  static double minScrollContentWidth(
    AppThemeTokens tokens, {
    required bool compactChave,
  }) {
    return minWidth(compactChave: compactChave) + 2 * tokens.gapSm;
  }
}

abstract final class SalesNotasEntradaResumoTableLayout {
  static const double codFornecedorWidth =
      SalesNotasEntradaTableLayout.codFornecedorWidth;
  static const double fornecedorMinWidth =
      SalesNotasEntradaTableLayout.fornecedorMinWidth;
  static const double cnpjWidth = SalesNotasEntradaTableLayout.cnpjWidth;
  static const double qtdNotasWidth = 104;
  static const double ticketMedioWidth = 136;
  static const double valorWidth = SalesNotasEntradaTableLayout.valorWidth;

  static double minWidth() {
    return codFornecedorWidth +
        fornecedorMinWidth +
        cnpjWidth +
        qtdNotasWidth +
        ticketMedioWidth +
        valorWidth;
  }

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

const String _chaveAcessoMissingGlyph = '—';
const String _chaveAcessoCompactEllipsis = '…';
const int _chaveAcessoGroupedDigitCount = 44;
const int _chaveAcessoGroupSize = 4;
const int _chaveAcessoCompactHeadDigits = 8;
const int _chaveAcessoCompactTailDigits = 8;

String? salesNotasEntradaChaveAcessoClipboardText(String? value) {
  final digits = _chaveAcessoDigits(value);
  if (digits.isEmpty) {
    return null;
  }
  return digits;
}

String formatSalesNotasEntradaChaveAcesso(
  String? value, {
  required bool compact,
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return _chaveAcessoMissingGlyph;
  }
  final digits = _chaveAcessoDigits(trimmed);
  if (digits.length != _chaveAcessoGroupedDigitCount) {
    if (compact &&
        digits.length >=
            _chaveAcessoCompactHeadDigits + _chaveAcessoCompactTailDigits) {
      return '${digits.substring(0, _chaveAcessoCompactHeadDigits)}'
          '$_chaveAcessoCompactEllipsis'
          '${digits.substring(digits.length - _chaveAcessoCompactTailDigits)}';
    }
    return trimmed;
  }
  if (compact) {
    final head = _groupChaveAcessoDigits(
      digits.substring(0, _chaveAcessoCompactHeadDigits),
    );
    final tail = _groupChaveAcessoDigits(
      digits.substring(digits.length - _chaveAcessoCompactTailDigits),
    );
    return '$head $_chaveAcessoCompactEllipsis $tail';
  }
  return _groupChaveAcessoDigits(digits);
}

String _chaveAcessoDigits(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '';
  }
  return AppBrFormatters.digitsOnly(trimmed).replaceAll(RegExp('[^0-9]'), '');
}

String _groupChaveAcessoDigits(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index += _chaveAcessoGroupSize) {
    if (index > 0) {
      buffer.write(' ');
    }
    final end = math.min(index + _chaveAcessoGroupSize, digits.length);
    buffer.write(digits.substring(index, end));
  }
  return buffer.toString();
}
