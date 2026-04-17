import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';

/// Maps merged weekday-by-user SQL rows to chart points.
///
/// Sorted by [OverviewWeekdayUserSalesTrendPoint.weekdayNumber], then by user
/// name (case-insensitive). Lowercase names are computed once per row for sort.
List<OverviewWeekdayUserSalesTrendPoint> overviewWeekdayUserSalesTrendPointsFromRows(
  List<ResumoParcelasDiaSemanaUsuarioRow> rows,
) {
  if (rows.isEmpty) {
    return const <OverviewWeekdayUserSalesTrendPoint>[];
  }
  final points = List<OverviewWeekdayUserSalesTrendPoint>.generate(
    rows.length,
    (i) {
      final row = rows[i];
      return OverviewWeekdayUserSalesTrendPoint(
        weekdayNumber: row.diaSemanaNumero,
        userName: row.nomeUsuario.trim(),
        salesCount: row.qtdVendas,
        salesAmount: row.valorParcela,
      );
    },
    growable: false,
  );
  final lowerForSort = List<String>.generate(
    rows.length,
    (i) => rows[i].nomeUsuario.trim().toLowerCase(),
    growable: false,
  );
  final order = List<int>.generate(rows.length, (i) => i, growable: false)
    ..sort((i, j) {
      final day = points[i].weekdayNumber.compareTo(points[j].weekdayNumber);
      if (day != 0) {
        return day;
      }
      return lowerForSort[i].compareTo(lowerForSort[j]);
    });
  return [for (final i in order) points[i]];
}
