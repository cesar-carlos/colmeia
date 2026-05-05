import 'package:flutter/foundation.dart';

/// Monthly P&L bucket for the sales monthly chart (aggregated from lucratividade mensal rows).
@immutable
class SalesMonthlyPnlPoint {
  const SalesMonthlyPnlPoint({
    required this.year,
    required this.month,
    required this.anoMes,
    required this.venda,
    required this.lucro,
    required this.custoMercadoria,
  });

  final int year;
  final int month;

  /// Zero-padded `"YYYY/MM"` label (e.g. `"2026/03"`).
  final String anoMes;
  final double venda;
  final double lucro;
  final double custoMercadoria;

  /// Cost as % of revenue: `(custoMercadoria / venda) × 100`.
  double get percentualCustoSobreVenda {
    if (custoMercadoria > 0 && venda > 0) {
      return (custoMercadoria / venda) * 100;
    }
    return 0;
  }

  /// Gross margin %: `(lucro / venda) × 100`.
  double get margemLucroBrutoPercent {
    if (venda > 0) {
      return (lucro / venda) * 100;
    }
    return 0;
  }

  /// Markup on merchandise cost: `(lucro / custoMercadoria) × 100`.
  /// Returns `0` when [custoMercadoria] is not positive (undefined markup).
  double get markupSobreCustoPercent {
    if (custoMercadoria > 0) {
      return (lucro / custoMercadoria) * 100;
    }
    return 0;
  }
}
