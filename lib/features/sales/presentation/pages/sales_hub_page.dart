import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_hub_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class SalesHubPage extends StatelessWidget {
  const SalesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.salesHubTitle),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: context.pageScrollPadding(tokens),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppShellPageIntro(
                  subtitle: l10n.salesHubSubtitle,
                ),
                SizedBox(height: tokens.sectionSpacing),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    final cols = math.max(
                      1,
                      math.min(
                        isWide ? 4 : 2,
                        allSalesCards.length,
                      ),
                    );
                    final gap = tokens.gapMd;
                    final isSingleCardRow = allSalesCards.length == 1;
                    final singleCardMaxWidth =
                        tokens.chartCompactHeight + tokens.contentSpacing;

                    return Wrap(
                      alignment: isSingleCardRow
                          ? WrapAlignment.center
                          : WrapAlignment.start,
                      spacing: gap,
                      runSpacing: gap,
                      children: allSalesCards.map((card) {
                        var width =
                            ((constraints.maxWidth - (gap * (cols - 1))) / cols)
                                .floorToDouble();
                        if (isSingleCardRow) {
                          width = math
                              .min(width, singleCardMaxWidth)
                              .floorToDouble();
                        }
                        return SizedBox(
                          width: width,
                          child: SalesHubCard(
                            icon: card.icon,
                            label: _getCardTitle(l10n, card.l10nTitleKey),
                            onTap: () {
                              unawaited(
                                context.pushTo<void>(
                                  AppRoute.salesCard,
                                  pathParameters: <String, String>{
                                    'cardId': card.id,
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getCardTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'salesCardProdutoRankLucroTitle' => l10n.salesCardProdutoRankLucroTitle,
      _ => key,
    };
  }
}
