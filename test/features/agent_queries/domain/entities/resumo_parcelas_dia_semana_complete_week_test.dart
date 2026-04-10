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
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            quantidade: 5,
            valorTotal: 10,
          ),
        ],
      );
      check(filled.length).equals(7);
      check(filled.first.diaSemanaNumero).equals(1);
      check(filled.first.quantidade).equals(0);
      check(filled[1].quantidade).equals(5);
      check(filled[1].valorTotal).equals(10);
      check(filled.last.diaSemanaNumero).equals(7);
    });

    test('fill sums duplicate weekday numbers', () {
      final filled = ResumoParcelasDiaSemanaCompleteWeek.fill(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            diaSemanaNumero: 3,
            diaSemana: 'Terça',
            quantidade: 1,
            valorTotal: 1,
          ),
          const ResumoParcelasDiaSemanaRow(
            diaSemanaNumero: 3,
            diaSemana: 'Terça',
            quantidade: 2,
            valorTotal: 4,
          ),
        ],
      );
      check(filled[2].quantidade).equals(3);
      check(filled[2].valorTotal).equals(5);
    });

    test('fill skips invalid weekday numbers', () {
      final filled = ResumoParcelasDiaSemanaCompleteWeek.fill(
        <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            diaSemanaNumero: 99,
            diaSemana: 'X',
            quantidade: 9,
            valorTotal: 9,
          ),
        ],
      );
      check(filled.every((r) => r.quantidade == 0)).isTrue();
    });
  });
}
