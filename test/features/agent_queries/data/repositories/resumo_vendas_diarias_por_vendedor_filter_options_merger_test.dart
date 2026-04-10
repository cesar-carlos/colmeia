import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_merger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dedupeVendedorOptions', () {
    test('merges same codVendedor and keeps lexicographically first nome', () {
      final merged =
          ResumoVendasDiariasPorVendedorFilterOptionsMerger //
          .dedupeVendedorOptions(
            const <ResumoVendasDiariasPorVendedorVendedorOption>[
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 1,
                nomeVendedor: 'Zed',
              ),
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 1,
                nomeVendedor: 'Anna',
              ),
            ],
            20,
          );
      check(merged).length.equals(1);
      check(merged.single.nomeVendedor).equals('Anna');
    });

    test('applies limit after global sort by nome', () {
      final merged =
          ResumoVendasDiariasPorVendedorFilterOptionsMerger //
          .dedupeVendedorOptions(
            const <ResumoVendasDiariasPorVendedorVendedorOption>[
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 2,
                nomeVendedor: 'Bob',
              ),
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 1,
                nomeVendedor: 'Amy',
              ),
            ],
            1,
          );
      check(merged).length.equals(1);
      check(merged.single.nomeVendedor).equals('Amy');
    });
  });

  group('dedupeTextOptions', () {
    test('merges case-insensitive duplicate values', () {
      final merged =
          ResumoVendasDiariasPorVendedorFilterOptionsMerger.dedupeTextOptions(
            const <ResumoVendasDiariasPorVendedorTextOption>[
              ResumoVendasDiariasPorVendedorTextOption(value: 'Centro'),
              ResumoVendasDiariasPorVendedorTextOption(value: 'centro'),
            ],
            20,
          );
      check(merged).length.equals(1);
      check(merged.single.value).equals('Centro');
    });

    test('applies limit after alphabetical sort', () {
      final merged =
          ResumoVendasDiariasPorVendedorFilterOptionsMerger.dedupeTextOptions(
            const <ResumoVendasDiariasPorVendedorTextOption>[
              ResumoVendasDiariasPorVendedorTextOption(value: 'Zona'),
              ResumoVendasDiariasPorVendedorTextOption(value: 'Agua'),
            ],
            1,
          );
      check(merged).length.equals(1);
      check(merged.single.value).equals('Agua');
    });
  });
}
