import 'package:checks/checks.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allSalesCards', () {
    test('contains sales trend card descriptor', () {
      final descriptor = allSalesCards.firstWhere(
        (card) => card.id == 'produto_tendencia_venda',
      );

      check(descriptor.route).equals('/sales/produto_tendencia_venda');
      check(descriptor.icon).equals(Icons.trending_up_rounded);
    });

    test('contains moving-average sales trend card descriptor', () {
      final descriptor = allSalesCards.firstWhere(
        (card) => card.id == 'produto_tendencia_venda_media_movel',
      );

      check(descriptor.route).equals(
        '/sales/produto_tendencia_venda_media_movel',
      );
      check(descriptor.icon).equals(Icons.insights_rounded);
    });

    test('contains product-margin card descriptor', () {
      final descriptor = allSalesCards.firstWhere(
        (card) => card.id == 'margem_produto',
      );

      check(descriptor.route).equals('/sales/margem_produto');
      check(descriptor.icon).equals(Icons.percent_rounded);
    });

    test('contains daily totals card descriptor', () {
      final descriptor = allSalesCards.firstWhere(
        (card) => card.id == 'resumo_total_diario_vendas',
      );

      check(descriptor.route).equals('/sales/resumo_total_diario_vendas');
      check(descriptor.icon).equals(Icons.calendar_view_day_outlined);
    });

    test('should expose seven unique hub card ids', () {
      final ids = allSalesCards.map((card) => card.id).toList();

      check(ids).deepEquals(<String>[
        'produto_rank_lucro',
        'ranking_produtos_faturamento',
        'margem_produto',
        'monthly_pnl',
        'resumo_total_diario_vendas',
        'produto_tendencia_venda',
        'produto_tendencia_venda_media_movel',
      ]);
    });
  });
}
