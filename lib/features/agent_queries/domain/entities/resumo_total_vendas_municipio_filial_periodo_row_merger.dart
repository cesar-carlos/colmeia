import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';

/// Deduplicates period branch rows by `empresa|filial`.
///
/// `qtdVendas` is a period `COUNT(DISTINCT …)` and must not be summed across
/// day slices. When duplicate keys appear, keep the first `qtdVendas` and sum
/// only additive money fields.
abstract final class ResumoTotalVendasMunicipioFilialPeriodoRowMerger {
  static List<ResumoTotalVendasMunicipioFilialPeriodoRow> merge(
    Iterable<ResumoTotalVendasMunicipioFilialPeriodoRow> rows,
  ) {
    final byKey = <String, ResumoTotalVendasMunicipioFilialPeriodoRow>{};
    for (final row in rows) {
      final key = '${row.codEmpresa}|${row.codFilial}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = row;
        continue;
      }
      byKey[key] = ResumoTotalVendasMunicipioFilialPeriodoRow(
        codEmpresa: existing.codEmpresa,
        codFilial: existing.codFilial,
        nomeFilial: existing.nomeFilial,
        codMunicipioFilial:
            existing.codMunicipioFilial ?? row.codMunicipioFilial,
        nomeMunicipioFilial:
            existing.nomeMunicipioFilial ?? row.nomeMunicipioFilial,
        ufMunicipioFilial: existing.ufMunicipioFilial ?? row.ufMunicipioFilial,
        qtdVendas: existing.qtdVendas,
        totalVenda: existing.totalVenda + row.totalVenda,
        nomeFantasiaFilial:
            existing.nomeFantasiaFilial ?? row.nomeFantasiaFilial,
        cepFilial: existing.cepFilial ?? row.cepFilial,
        codigoIbgeMunicipioFilial:
            existing.codigoIbgeMunicipioFilial ?? row.codigoIbgeMunicipioFilial,
      );
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
    return <ResumoTotalVendasMunicipioFilialPeriodoRow>[
      for (final key in sortedKeys) byKey[key]!,
    ];
  }
}
