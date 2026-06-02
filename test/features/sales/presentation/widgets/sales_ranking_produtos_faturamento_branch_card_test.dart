import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_branch_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

RankingProdutosFaturamentoRow _row({
  required int codProduto,
  required String nome,
  required double valor,
  required double percentual,
  int? posicao,
}) {
  return RankingProdutosFaturamentoRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: nome,
    valorVenda: valor,
    percentual: percentual,
    posicao: posicao,
  );
}

void main() {
  testWidgets('uses two-column desktop layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: SalesRankingProdutosFaturamentoBranchCard(
          l10n: lookupAppLocalizations(const Locale('pt', 'BR')),
          codEmpresa: 1,
          codFilial: 1,
          branchDisplayName: 'Rondonopolis Lions',
          rows: <RankingProdutosFaturamentoRow>[
            _row(
              codProduto: 1,
              nome: 'Cafe',
              valor: 320,
              percentual: 32,
              posicao: 1,
            ),
            _row(
              codProduto: 2,
              nome: 'Acucar',
              valor: 180,
              percentual: 18,
              posicao: 2,
            ),
          ],
          metricSubtitle: 'Top 5 • Faturamento',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rondonopolis Lions'), findsOneWidget);
    expect(
      find.byKey(const Key('sales-ranking-branch-desktop-layout')),
      findsOneWidget,
    );
  });
}
