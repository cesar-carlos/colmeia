import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_weekday_user_sales_trend_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overviewWeekdayUserSalesTrendPointsFromRows', () {
    test('maps rows and sorts by weekday then user name', () {
      final rows = <ResumoParcelasDiaSemanaUsuarioRow>[
        const ResumoParcelasDiaSemanaUsuarioRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeUsuario: 'Bob',
          diaSemanaNumero: 3,
          diaSemana: 'Terça-feira',
          qtdVendas: 2,
          valorParcela: 20,
        ),
        const ResumoParcelasDiaSemanaUsuarioRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeUsuario: 'Alice',
          diaSemanaNumero: 3,
          diaSemana: 'Terça-feira',
          qtdVendas: 1,
          valorParcela: 10,
        ),
        const ResumoParcelasDiaSemanaUsuarioRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeUsuario: 'Zed',
          diaSemanaNumero: 2,
          diaSemana: 'Segunda-feira',
          qtdVendas: 5,
          valorParcela: 50,
        ),
      ];

      final points = overviewWeekdayUserSalesTrendPointsFromRows(rows);

      check(points).length.equals(3);
      check(points[0].weekdayNumber).equals(2);
      check(points[0].userName).equals('Zed');
      check(points[0].salesCount).equals(5);
      check(points[0].salesAmount).equals(50);
      check(points[1].weekdayNumber).equals(3);
      check(points[1].userName).equals('Alice');
      check(points[2].userName).equals('Bob');
    });
  });
}
