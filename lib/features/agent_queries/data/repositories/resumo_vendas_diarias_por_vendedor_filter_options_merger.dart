import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';

abstract final class ResumoVendasDiariasPorVendedorFilterOptionsMerger {
  static List<ResumoVendasDiariasPorVendedorVendedorOption>
  dedupeVendedorOptions(
    List<ResumoVendasDiariasPorVendedorVendedorOption> rows,
    int limit,
  ) {
    final byCod = <int, List<ResumoVendasDiariasPorVendedorVendedorOption>>{};
    for (final row in rows) {
      byCod
          .putIfAbsent(
            row.codVendedor,
            () => <ResumoVendasDiariasPorVendedorVendedorOption>[],
          )
          .add(row);
    }
    final keys = byCod.keys.toList(growable: false)..sort();
    final chosen = <ResumoVendasDiariasPorVendedorVendedorOption>[];
    for (final cod in keys) {
      final list =
          List<ResumoVendasDiariasPorVendedorVendedorOption>.from(
            byCod[cod]!,
          )..sort(
            (a, b) => a.nomeVendedor.toLowerCase().compareTo(
              b.nomeVendedor.toLowerCase(),
            ),
          );
      chosen.add(list.first);
    }
    chosen.sort((a, b) {
      final byName = a.nomeVendedor.toLowerCase().compareTo(
        b.nomeVendedor.toLowerCase(),
      );
      if (byName != 0) {
        return byName;
      }
      return a.codVendedor.compareTo(b.codVendedor);
    });
    if (chosen.length > limit) {
      return chosen.sublist(0, limit);
    }
    return chosen;
  }

  static List<ResumoVendasDiariasPorVendedorTextOption> dedupeTextOptions(
    List<ResumoVendasDiariasPorVendedorTextOption> rows,
    int limit,
  ) {
    final byNorm = <String, List<ResumoVendasDiariasPorVendedorTextOption>>{};
    for (final row in rows) {
      final key = row.value.trim().toLowerCase();
      byNorm
          .putIfAbsent(
            key,
            () => <ResumoVendasDiariasPorVendedorTextOption>[],
          )
          .add(row);
    }
    final keys = byNorm.keys.toList(growable: false)..sort();
    final chosen = <ResumoVendasDiariasPorVendedorTextOption>[];
    for (final key in keys) {
      final list =
          List<ResumoVendasDiariasPorVendedorTextOption>.from(
            byNorm[key]!,
          )..sort(
            (a, b) => a.value.toLowerCase().compareTo(
              b.value.toLowerCase(),
            ),
          );
      chosen.add(list.first);
    }
    chosen.sort(
      (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()),
    );
    if (chosen.length > limit) {
      return chosen.sublist(0, limit);
    }
    return chosen;
  }
}
