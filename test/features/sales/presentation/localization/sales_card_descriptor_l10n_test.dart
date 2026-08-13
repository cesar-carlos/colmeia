import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_card_descriptor_l10n.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('should resolve a localized title for every sales hub card', () {
    for (final card in allSalesCards) {
      final title = card.resolvedTitle(en);
      check(title).isNotEmpty();
      check(title).not((it) => it.equals(card.id));
    }
  });

  test('should map each sales hub card id to its English title', () {
    expect(
      _card('produto_rank_lucro').resolvedTitle(en),
      en.salesCardProdutoRankLucroTitle,
    );
    expect(
      _card('ranking_produtos_faturamento').resolvedTitle(en),
      en.salesCardRankingProdutosFaturamentoTitle,
    );
    expect(
      _card('margem_produto').resolvedTitle(en),
      en.salesCardMargemProdutoTitle,
    );
    expect(
      _card('monthly_pnl').resolvedTitle(en),
      en.salesCardMonthlyPnlTitle,
    );
    expect(
      _card('resumo_total_diario_vendas').resolvedTitle(en),
      en.salesCardResumoTotalDiarioVendasTitle,
    );
    expect(
      _card('produto_tendencia_venda').resolvedTitle(en),
      en.salesCardProdutoTendenciaTitle,
    );
    expect(
      _card('produto_tendencia_venda_media_movel').resolvedTitle(en),
      en.salesCardProdutoTendenciaMediaMovelTitle,
    );
  });

  test('should keep Portuguese titles aligned with the hub catalog', () {
    expect(
      _card('produto_rank_lucro').resolvedTitle(pt),
      'Ranking de produtos',
    );
    expect(
      _card('ranking_produtos_faturamento').resolvedTitle(pt),
      'Ranking por faturamento',
    );
    expect(_card('margem_produto').resolvedTitle(pt), 'Margem produto');
    expect(_card('monthly_pnl').resolvedTitle(pt), 'Resultado mensal');
    expect(
      _card('resumo_total_diario_vendas').resolvedTitle(pt),
      'Vendas diárias',
    );
    expect(
      _card('produto_tendencia_venda').resolvedTitle(pt),
      'Tendência de vendas',
    );
    expect(
      _card('produto_tendencia_venda_media_movel').resolvedTitle(pt),
      'Tendência de vendas (média móvel)',
    );
  });

  test('should fall back to the raw id when the card is unknown', () {
    const card = SalesCardDescriptor(
      id: 'unknown_card',
      icon: Icons.help_outline,
    );

    check(card.resolvedTitle(en)).equals('unknown_card');
  });
}

SalesCardDescriptor _card(String id) {
  return allSalesCards.firstWhere((card) => card.id == id);
}
