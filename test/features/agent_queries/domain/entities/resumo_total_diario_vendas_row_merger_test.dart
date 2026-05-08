import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row_merger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sums quantities and amounts for the same company, branch, and day', () {
    final merged = ResumoTotalDiarioVendasRowMerger.merge(
      <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 2,
          dataVenda: DateTime(2026, 4, 8),
          qtdVendas: 3,
          valorTotalDiarioVenda: 10.5,
        ),
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 2,
          dataVenda: DateTime(2026, 4, 8, 12),
          qtdVendas: 7,
          valorTotalDiarioVenda: 4.25,
        ),
      ],
    );

    check(merged).length.equals(1);
    final row = merged.single;
    check(row.qtdVendas).equals(10);
    check(row.valorTotalDiarioVenda).equals(14.75);
    check(row.dataVenda).equals(DateTime(2026, 4, 8));
  });

  test('keeps separate rows for different days or branches', () {
    final merged = ResumoTotalDiarioVendasRowMerger.merge(
      <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 2,
          dataVenda: DateTime(2026, 4, 8),
          qtdVendas: 1,
          valorTotalDiarioVenda: 1,
        ),
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 3,
          dataVenda: DateTime(2026, 4, 8),
          qtdVendas: 2,
          valorTotalDiarioVenda: 2,
        ),
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 2,
          dataVenda: DateTime(2026, 4, 9),
          qtdVendas: 4,
          valorTotalDiarioVenda: 8,
        ),
      ],
    );

    check(merged).length.equals(3);
    check(merged[0].codFilial).equals(2);
    check(merged[0].dataVenda).equals(DateTime(2026, 4, 8));
    check(merged[1].codFilial).equals(2);
    check(merged[1].dataVenda).equals(DateTime(2026, 4, 9));
    check(merged[2].codFilial).equals(3);
    check(merged[2].dataVenda).equals(DateTime(2026, 4, 8));
  });
}
