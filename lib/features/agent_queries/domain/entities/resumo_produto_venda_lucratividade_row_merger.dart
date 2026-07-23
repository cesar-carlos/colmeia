import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';

/// Combines [ResumoProdutoVendaLucratividadeRow] from multiple calendar buckets.
///
/// `qtdVendas` and `pontoEquilibrio` come from period `COUNT(DISTINCT …)` /
/// non-additive aggregates and must not be summed across duplicate keys.
abstract final class ResumoProdutoVendaLucratividadeRowMerger {
  static List<ResumoProdutoVendaLucratividadeRow> merge(
    Iterable<ResumoProdutoVendaLucratividadeRow> rows,
  ) {
    final byKey =
        <
          String,
          ({
            int codEmpresa,
            int codFilial,
            int qtdVendas,
            double qtdItensVendido,
            double valorTotalCustoMedio,
            double custoReposicao,
            double pontoEquilibrio,
            double valorTotalItem,
            String? chartAxisLabel,
          })
        >{};
    for (final row in rows) {
      final key = '${row.codEmpresa}|${row.codFilial}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = (
          codEmpresa: row.codEmpresa,
          codFilial: row.codFilial,
          qtdVendas: row.qtdVendas,
          qtdItensVendido: row.qtdItensVendido,
          valorTotalCustoMedio: row.valorTotalCustoMedio,
          custoReposicao: row.custoReposicao,
          pontoEquilibrio: row.pontoEquilibrio,
          valorTotalItem: row.valorTotalItem,
          chartAxisLabel: row.chartAxisLabel,
        );
      } else {
        byKey[key] = (
          codEmpresa: existing.codEmpresa,
          codFilial: existing.codFilial,
          qtdVendas: existing.qtdVendas,
          qtdItensVendido: existing.qtdItensVendido + row.qtdItensVendido,
          valorTotalCustoMedio:
              existing.valorTotalCustoMedio + row.valorTotalCustoMedio,
          custoReposicao: existing.custoReposicao + row.custoReposicao,
          pontoEquilibrio: existing.pontoEquilibrio,
          valorTotalItem: existing.valorTotalItem + row.valorTotalItem,
          chartAxisLabel: existing.chartAxisLabel ?? row.chartAxisLabel,
        );
      }
    }
    final sortedKeys = byKey.keys.toList(growable: false)
      ..sort((a, b) {
        final va = byKey[a]!;
        final vb = byKey[b]!;
        final c = va.codEmpresa.compareTo(vb.codEmpresa);
        if (c != 0) {
          return c;
        }
        return va.codFilial.compareTo(vb.codFilial);
      });
    return <ResumoProdutoVendaLucratividadeRow>[
      for (final key in sortedKeys)
        ResumoProdutoVendaLucratividadeRow(
          codEmpresa: byKey[key]!.codEmpresa,
          codFilial: byKey[key]!.codFilial,
          qtdVendas: byKey[key]!.qtdVendas,
          qtdItensVendido: byKey[key]!.qtdItensVendido,
          valorTotalCustoMedio: byKey[key]!.valorTotalCustoMedio,
          custoReposicao: byKey[key]!.custoReposicao,
          pontoEquilibrio: byKey[key]!.pontoEquilibrio,
          valorTotalItem: byKey[key]!.valorTotalItem,
          chartAxisLabel: byKey[key]!.chartAxisLabel,
        ),
    ];
  }
}
