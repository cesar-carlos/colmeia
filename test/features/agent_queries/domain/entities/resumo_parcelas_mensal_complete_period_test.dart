import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_complete_period.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasMensalCompletePeriod', () {
    test('fill returns empty when fim is before inicio', () {
      final filled = ResumoParcelasMensalCompletePeriod.fill(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 3),
        rows: const <ResumoParcelasMensalRow>[],
      );
      check(filled).isEmpty();
    });

    test('fill includes each calendar month in range with zeros for gaps', () {
      final filled = ResumoParcelasMensalCompletePeriod.fill(
        dataVendaInicio: DateTime.utc(2026, 1, 15),
        dataVendaFim: DateTime.utc(2026, 3, 10),
        rows: <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2026,
            mes: 2,
            anoMes: '2026/02',
            qtdVendas: 3,
            valorParcela: 30,
          ),
        ],
      );
      check(filled.length).equals(3);
      check(filled[0].mes).equals(1);
      check(filled[0].qtdVendas).equals(0);
      check(filled[0].codEmpresa).equals(
        ResumoParcelasMensalRow.aggregatedBranchSentinel,
      );
      check(filled[1].mes).equals(2);
      check(filled[1].qtdVendas).equals(3);
      check(filled[1].valorParcela).equals(30);
      check(filled[2].mes).equals(3);
      check(filled[2].qtdVendas).equals(0);
    });

    test('fill spans year boundary', () {
      final filled = ResumoParcelasMensalCompletePeriod.fill(
        dataVendaInicio: DateTime.utc(2025, 11),
        dataVendaFim: DateTime.utc(2026, 2, 28),
        rows: const <ResumoParcelasMensalRow>[],
      );
      check(filled.length).equals(4);
      check(filled.first.anoMes).equals('2025/11');
      check(filled.last.anoMes).equals('2026/02');
    });

    test('fill sums duplicate ano/mes across filiais in input', () {
      final filled = ResumoParcelasMensalCompletePeriod.fill(
        dataVendaInicio: DateTime.utc(2026, 5),
        dataVendaFim: DateTime.utc(2026, 5, 31),
        rows: <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2026,
            mes: 5,
            anoMes: '2026/05',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 2,
            ano: 2026,
            mes: 5,
            anoMes: '2026/05',
            qtdVendas: 2,
            valorParcela: 4,
          ),
        ],
      );
      check(filled.length).equals(1);
      check(filled.single.qtdVendas).equals(3);
      check(filled.single.valorParcela).equals(5);
    });

    test('fill sums duplicate ano/mes in input for same filial', () {
      final filled = ResumoParcelasMensalCompletePeriod.fill(
        dataVendaInicio: DateTime.utc(2026, 5),
        dataVendaFim: DateTime.utc(2026, 5, 31),
        rows: <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2026,
            mes: 5,
            anoMes: '2026/05',
            qtdVendas: 1,
            valorParcela: 1,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2026,
            mes: 5,
            anoMes: '2026/05',
            qtdVendas: 2,
            valorParcela: 4,
          ),
        ],
      );
      check(filled.length).equals(1);
      check(filled.single.qtdVendas).equals(3);
      check(filled.single.valorParcela).equals(5);
    });

    test('fill skips invalid mes and invalid ano when aggregating input', () {
      final filled = ResumoParcelasMensalCompletePeriod.fill(
        dataVendaInicio: DateTime.utc(2026, 6),
        dataVendaFim: DateTime.utc(2026, 6, 30),
        rows: <ResumoParcelasMensalRow>[
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 2026,
            mes: 0,
            anoMes: 'x',
            qtdVendas: 9,
            valorParcela: 9,
          ),
          const ResumoParcelasMensalRow(
            codEmpresa: 1,
            codFilial: 1,
            ano: 1899,
            mes: 6,
            anoMes: 'x',
            qtdVendas: 9,
            valorParcela: 9,
          ),
        ],
      );
      check(filled.single.qtdVendas).equals(0);
    });
  });
}
