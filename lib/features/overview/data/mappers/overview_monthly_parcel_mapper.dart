import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';

List<OverviewMonthlyParcelPoint> overviewMonthlyParcelPointsFromRows(
  List<ResumoParcelasMensalRow> rows,
) {
  return rows
      .map(
        (r) => OverviewMonthlyParcelPoint(
          anoMes: r.anoMes,
          qtdVendas: r.qtdVendas,
          valorParcela: r.valorParcela,
        ),
      )
      .toList(growable: false);
}
