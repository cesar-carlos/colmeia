import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';

List<OverviewWeekdaySalesTrendPoint> overviewWeekdaySalesTrendPointsFromRows(
  List<ResumoParcelasDiaSemanaRow> rows,
) {
  return rows
      .map(
        (row) => OverviewWeekdaySalesTrendPoint(
          weekdayNumber: row.diaSemanaNumero,
          salesCount: row.qtdVendas,
          salesAmount: row.valorParcela,
        ),
      )
      .toList(growable: false);
}
