import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_sales_trend_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overviewWeekdaySalesTrendPointsFromRows', () {
    test('maps rows to locale-neutral weekday points', () {
      const rows = <ResumoParcelasDiaSemanaRow>[
        ResumoParcelasDiaSemanaRow(
          codEmpresa: 0,
          codFilial: 0,
          diaSemanaNumero: 1,
          diaSemana: 'Domingo',
          qtdVendas: 4,
          valorParcela: 99.5,
        ),
        ResumoParcelasDiaSemanaRow(
          codEmpresa: 0,
          codFilial: 0,
          diaSemanaNumero: 7,
          diaSemana: 'Sabado',
          qtdVendas: 6,
          valorParcela: 120,
        ),
      ];

      final points = overviewWeekdaySalesTrendPointsFromRows(rows);

      check(points).length.equals(2);
      check(points.first.weekdayNumber).equals(1);
      check(points.first.salesCount).equals(4);
      check(points.first.salesAmount).equals(99.5);
      check(points.last.weekdayNumber).equals(7);
      check(points.last.salesCount).equals(6);
      check(points.last.salesAmount).equals(120);
    });
  });
}
