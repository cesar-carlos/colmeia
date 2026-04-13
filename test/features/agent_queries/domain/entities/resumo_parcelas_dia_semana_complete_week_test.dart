import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_complete_week.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaCompleteWeek', () {
    test('fill returns seven rows in order with zeros for gaps', () {
      final filled = ResumoParcelasDiaSemanaCompleteWeek.fill(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 6,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 5,
            valorParcela: 10,
          ),
        ],
      );
      check(filled.length).equals(7);
      check(filled.first.codEmpresa).equals(
        ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel,
      );
      check(filled.first.codFilial).equals(
        ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel,
      );
      check(filled.first.diaSemanaNumero).equals(1);
      check(filled.first.qtdVendas).equals(0);
      check(filled[1].qtdVendas).equals(5);
      check(filled[1].valorParcela).equals(10);
      check(filled.last.diaSemanaNumero).equals(7);
    });

    test('fill sums duplicate weekday numbers', () {
      final filled = ResumoParcelasDiaSemanaCompleteWeek.fill(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 3,
            diaSemana: 'Terça',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 2,
            diaSemanaNumero: 3,
            diaSemana: 'Terça',
            qtdVendas: 2,
            valorParcela: 4,
          ),
        ],
      );
      check(filled[2].qtdVendas).equals(3);
      check(filled[2].valorParcela).equals(5);
    });

    test('fill skips invalid weekday numbers', () {
      final filled = ResumoParcelasDiaSemanaCompleteWeek.fill(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 99,
            diaSemana: 'X',
            qtdVendas: 9,
            valorParcela: 9,
          ),
        ],
      );
      check(filled.every((r) => r.qtdVendas == 0)).isTrue();
    });
  });
}
