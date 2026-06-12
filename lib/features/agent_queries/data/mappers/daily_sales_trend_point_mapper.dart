import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';

List<DailySalesTrendPoint> dailySalesTrendPointsFromRows(
  List<ResumoTotalDiarioVendasRow> rows,
) {
  return rows
      .map(
        (row) => DailySalesTrendPoint(
          saleDate: DateTime(
            row.dataVenda.year,
            row.dataVenda.month,
            row.dataVenda.day,
          ),
          salesCount: row.qtdVendas,
          salesAmount: row.valorTotalDiarioVenda,
        ),
      )
      .toList(growable: false);
}
