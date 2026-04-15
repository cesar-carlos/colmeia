import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_monthly_parcel_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overviewMonthlyParcelPointsFromRows', () {
    test('maps rows to points', () {
      const rows = <ResumoParcelasMensalRow>[
        ResumoParcelasMensalRow(
          codEmpresa: 0,
          codFilial: 0,
          ano: 2026,
          mes: 4,
          anoMes: '2026/04',
          qtdVendas: 10,
          valorParcela: 100.5,
        ),
      ];
      final points = overviewMonthlyParcelPointsFromRows(rows);
      check(points).length.equals(1);
      check(points.single.anoMes).equals('2026/04');
      check(points.single.qtdVendas).equals(10);
      check(points.single.valorParcela).equals(100.5);
    });
  });
}
