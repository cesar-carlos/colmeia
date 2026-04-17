import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumoParcelasDiaSemanaUsuarioRowMerger', () {
    test(
      'merge sums by codEmpresa, codFilial, nomeUsuario, and diaSemanaNumero',
      () {
        final merged = ResumoParcelasDiaSemanaUsuarioRowMerger.merge(
          <ResumoParcelasDiaSemanaUsuarioRow>[
            const ResumoParcelasDiaSemanaUsuarioRow(
              codEmpresa: 1,
              codFilial: 1,
              nomeUsuario: 'Ada',
              diaSemanaNumero: 2,
              diaSemana: 'Segunda',
              qtdVendas: 1,
              valorParcela: 10,
            ),
            const ResumoParcelasDiaSemanaUsuarioRow(
              codEmpresa: 1,
              codFilial: 1,
              nomeUsuario: 'Ada',
              diaSemanaNumero: 2,
              diaSemana: 'Segunda',
              qtdVendas: 2,
              valorParcela: 5,
            ),
          ],
        );
        check(merged.length).equals(1);
        check(merged.single.qtdVendas).equals(3);
        check(merged.single.valorParcela).equals(15);
        check(merged.single.nomeUsuario).equals('Ada');
      },
    );

    test('merge does not combine different users on same weekday', () {
      final merged = ResumoParcelasDiaSemanaUsuarioRowMerger.merge(
        <ResumoParcelasDiaSemanaUsuarioRow>[
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Ada',
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 1,
            valorParcela: 10,
          ),
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Bob',
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 3,
            valorParcela: 7,
          ),
        ],
      );
      check(merged.length).equals(2);
    });
  });

  group('Usuario rows fold to weekday totals', () {
    test(
      'sum of per-user rows matches merged weekday rows for the same splits',
      () {
        final usuario = <ResumoParcelasDiaSemanaUsuarioRow>[
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Ada',
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 10,
            valorParcela: 100,
          ),
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Bob',
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 3,
            valorParcela: 30,
          ),
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Ada',
            diaSemanaNumero: 3,
            diaSemana: 'Terça',
            qtdVendas: 1,
            valorParcela: 50,
          ),
        ];

        final folded = _foldUsuarioRowsToWeekday(usuario);
        final expected = <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 13,
            valorParcela: 130,
          ),
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 3,
            diaSemana: 'Terça',
            qtdVendas: 1,
            valorParcela: 50,
          ),
        ];
        check(folded.length).equals(expected.length);
        check(folded[0].codEmpresa).equals(expected[0].codEmpresa);
        check(folded[0].codFilial).equals(expected[0].codFilial);
        check(folded[0].diaSemanaNumero).equals(expected[0].diaSemanaNumero);
        check(folded[0].qtdVendas).equals(expected[0].qtdVendas);
        check(folded[0].valorParcela).equals(expected[0].valorParcela);
        check(folded[1].diaSemanaNumero).equals(expected[1].diaSemanaNumero);
        check(folded[1].qtdVendas).equals(expected[1].qtdVendas);
        check(folded[1].valorParcela).equals(expected[1].valorParcela);
      },
    );

    test(
      'after usuario and weekday mergers, folded usuario matches merged '
      'weekday',
      () {
        final usuarioFromAgents = <ResumoParcelasDiaSemanaUsuarioRow>[
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Ada',
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 10,
            valorParcela: 100,
          ),
          const ResumoParcelasDiaSemanaUsuarioRow(
            codEmpresa: 1,
            codFilial: 1,
            nomeUsuario: 'Ada',
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 5,
            valorParcela: 50,
          ),
        ];
        final weekdayFromAgents = <ResumoParcelasDiaSemanaRow>[
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 10,
            valorParcela: 100,
          ),
          const ResumoParcelasDiaSemanaRow(
            codEmpresa: 1,
            codFilial: 1,
            diaSemanaNumero: 2,
            diaSemana: 'Segunda',
            qtdVendas: 5,
            valorParcela: 50,
          ),
        ];

        final mergedUsuario = ResumoParcelasDiaSemanaUsuarioRowMerger.merge(
          usuarioFromAgents,
        );
        final mergedWeekday = ResumoParcelasDiaSemanaRowMerger.merge(
          weekdayFromAgents,
        );

        final folded = _foldUsuarioRowsToWeekday(mergedUsuario);
        check(folded.length).equals(mergedWeekday.length);
        check(folded.single.codEmpresa).equals(mergedWeekday.single.codEmpresa);
        check(folded.single.codFilial).equals(mergedWeekday.single.codFilial);
        check(
          folded.single.diaSemanaNumero,
        ).equals(mergedWeekday.single.diaSemanaNumero);
        check(folded.single.qtdVendas).equals(mergedWeekday.single.qtdVendas);
        check(
          folded.single.valorParcela,
        ).equals(mergedWeekday.single.valorParcela);
      },
    );
  });
}

/// Sums sales quantity and installment value across users for each branch + weekday.
List<ResumoParcelasDiaSemanaRow> _foldUsuarioRowsToWeekday(
  List<ResumoParcelasDiaSemanaUsuarioRow> rows,
) {
  final acc = <String, ({int qtdVendas, double valorParcela, int n})>{};
  for (final r in rows) {
    final key = '${r.codEmpresa}|${r.codFilial}|${r.diaSemanaNumero}';
    final prev = acc[key];
    if (prev == null) {
      acc[key] = (
        qtdVendas: r.qtdVendas,
        valorParcela: r.valorParcela,
        n: r.diaSemanaNumero,
      );
    } else {
      acc[key] = (
        qtdVendas: prev.qtdVendas + r.qtdVendas,
        valorParcela: prev.valorParcela + r.valorParcela,
        n: prev.n,
      );
    }
  }
  final keys = acc.keys.toList()..sort();
  return <ResumoParcelasDiaSemanaRow>[
    for (final k in keys)
      ResumoParcelasDiaSemanaRow(
        codEmpresa: int.parse(k.split('|')[0]),
        codFilial: int.parse(k.split('|')[1]),
        diaSemanaNumero: acc[k]!.n,
        diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(acc[k]!.n),
        qtdVendas: acc[k]!.qtdVendas,
        valorParcela: acc[k]!.valorParcela,
      ),
  ];
}
