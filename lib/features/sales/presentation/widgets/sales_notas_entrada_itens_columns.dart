import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';

class SalesNotasEntradaItensColumnLabels {
  const SalesNotasEntradaItensColumnLabels({
    required this.nome,
    required this.unidade,
    required this.quantidade,
    required this.valorUnitario,
    required this.subtotal,
    required this.descontoItem,
    required this.descontoTotal,
    required this.descontoProporcional,
    required this.valorTotal,
  });

  factory SalesNotasEntradaItensColumnLabels.fromL10n(AppLocalizations l10n) {
    return SalesNotasEntradaItensColumnLabels(
      nome: l10n.salesNotasEntradaItensColumnNome,
      unidade: l10n.salesNotasEntradaItensColumnUnidade,
      quantidade: l10n.salesNotasEntradaItensColumnQuantidade,
      valorUnitario: l10n.salesNotasEntradaItensColumnValorUnitario,
      subtotal: l10n.salesNotasEntradaItensColumnSubtotal,
      descontoItem: l10n.salesNotasEntradaItensColumnDescontoItem,
      descontoTotal: l10n.salesNotasEntradaItensColumnDescontoTotal,
      descontoProporcional:
          l10n.salesNotasEntradaItensColumnDescontoProporcional,
      valorTotal: l10n.salesNotasEntradaItensColumnValorTotal,
    );
  }

  final String nome;
  final String unidade;
  final String quantidade;
  final String valorUnitario;
  final String subtotal;
  final String descontoItem;
  final String descontoTotal;
  final String descontoProporcional;
  final String valorTotal;
}

abstract final class SalesNotasEntradaItensTableLayout {
  static const double nomeMinWidth = 240;
  static const double unidadeWidth = 72;
  static const double quantidadeWidth = 88;
  static const double moneyWidth = 128;

  /// Unit price and line total stay visible. Subtotal and discounts follow.
  static const int alwaysVisibleMoneyColumnCount = 2;

  static double minWidth(SalesNotasEntradaItensVisibleColumns columns) {
    return nomeMinWidth +
        unidadeWidth +
        quantidadeWidth +
        moneyWidth * (alwaysVisibleMoneyColumnCount + columns.accessoryCount);
  }

  static double minScrollContentWidth(
    AppThemeTokens tokens,
    SalesNotasEntradaItensVisibleColumns columns,
  ) => minWidth(columns) + 2 * tokens.gapSm;
}

/// Accessory money columns hidden when every loaded line is zero.
class SalesNotasEntradaItensVisibleColumns {
  const SalesNotasEntradaItensVisibleColumns({
    required this.subtotal,
    required this.descontoItem,
    required this.descontoTotal,
    required this.descontoProporcional,
  });

  factory SalesNotasEntradaItensVisibleColumns.fromRows(
    List<NotaEntradaItemRow> rows,
  ) {
    var subtotal = false;
    var descontoItem = false;
    var descontoTotal = false;
    var descontoProporcional = false;
    for (final row in rows) {
      subtotal |= _hasAmount(row.subTotal);
      descontoItem |= _hasAmount(row.valorDescontoItem);
      descontoTotal |= _hasAmount(row.valorTotalDesconto);
      descontoProporcional |= _hasAmount(row.valorDescontoProporcional);
    }
    return SalesNotasEntradaItensVisibleColumns(
      subtotal: subtotal,
      descontoItem: descontoItem,
      descontoTotal: descontoTotal,
      descontoProporcional: descontoProporcional,
    );
  }

  static const SalesNotasEntradaItensVisibleColumns none =
      SalesNotasEntradaItensVisibleColumns(
        subtotal: false,
        descontoItem: false,
        descontoTotal: false,
        descontoProporcional: false,
      );

  final bool subtotal;
  final bool descontoItem;
  final bool descontoTotal;
  final bool descontoProporcional;

  int get accessoryCount {
    var count = 0;
    if (subtotal) {
      count += 1;
    }
    if (descontoItem) {
      count += 1;
    }
    if (descontoTotal) {
      count += 1;
    }
    if (descontoProporcional) {
      count += 1;
    }
    return count;
  }

  static bool _hasAmount(double value) => value.abs() > 0.0000001;
}
