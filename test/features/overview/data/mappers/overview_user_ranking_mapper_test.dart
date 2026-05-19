import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/overview/data/mappers/overview_user_ranking_mapper.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labels = OverviewLoadLabels.englishFallback;

  test('merges same user across branches by normalized key', () {
    final rows = <ResumoParcelaPorUsuarioRow>[
      const ResumoParcelaPorUsuarioRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeUsuario: '  Ana ',
        qtdVendas: 2,
        valorParcela: 100,
      ),
      const ResumoParcelaPorUsuarioRow(
        codEmpresa: 1,
        codFilial: 2,
        nomeUsuario: 'ana',
        qtdVendas: 3,
        valorParcela: 200,
      ),
    ];
    final rankings = overviewUserRankingsFromResumoParcelaPorUsuarioRows(
      rows,
      rowLabels: labels,
    );
    check(rankings).length.equals(1);
    check(rankings.single.userName).equals('Ana');
    check(rankings.single.totalSalesCount).equals(5);
    check(rankings.single.totalAmount).equals(300);
    check(rankings.single.averageTicket).equals(60);
  });

  test('normalize key matches legacy payment bucket for blank usuario', () {
    check(
      overviewUserRankingNormalizeKey('  ', labels),
    ).equals(labels.unknownUserNameLabel.toLowerCase());
    check(
      overviewUserRankingNormalizeKey('', labels),
    ).equals(labels.unknownUserNameLabel.toLowerCase());
  });
}
