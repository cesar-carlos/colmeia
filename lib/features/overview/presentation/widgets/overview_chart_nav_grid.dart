import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_chart_card_descriptor_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _kOverviewNavCardMinWidth = 104;
const double _kOverviewNavCardMinHeight = 90;

/// Compact navigation grid for lazy-loaded overview chart detail pages.
class OverviewChartNavGrid extends StatelessWidget {
  const OverviewChartNavGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final typography = Theme.of(context).appTypography;

    return Selector<OverviewController, Set<String>>(
      selector: (_, controller) => controller.chartNavReadySections
          .map((section) => section.name)
          .toSet(),
      builder: (context, readySectionNames, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final gap = tokens.gapSm;
            final cardCount = allOverviewChartCards.length;
            final maxCols = math.max(
              1,
              math.min(
                cardCount,
                ((constraints.maxWidth + gap) /
                        (_kOverviewNavCardMinWidth + gap))
                    .floor(),
              ),
            );
            final cardWidth = math
                .max(
                  _kOverviewNavCardMinWidth,
                  (constraints.maxWidth - gap * (maxCols - 1)) / maxCols,
                )
                .floorToDouble();
            final cardHeight =
                (cardWidth * _kOverviewNavCardMinHeight / _kOverviewNavCardMinWidth)
                    .floorToDouble();
            final aspectRatio = cardWidth / cardHeight;
            final compactLabelStyle = cardWidth <= _kOverviewNavCardMinWidth + 4
                ? typography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    height: 1.15,
                  )
                : null;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: allOverviewChartCards.map((card) {
                final isReady =
                    readySectionNames.contains(card.section.name);
                final title = card.resolvedTitle(l10n);
                final semanticsLabel = isReady
                    ? title
                    : '$title, ${l10n.overviewChartNavLoadingSemanticsSuffix}';

                return SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: AppHubNavigationCard(
                    compact: true,
                    icon: card.icon,
                    label: title,
                    labelStyle: compactLabelStyle,
                    showReadyBadge: isReady,
                    semanticsLabel: semanticsLabel,
                    aspectRatio: aspectRatio,
                    onTap: () {
                      final activeFilter =
                          context.read<OverviewController>().activeFilter;
                      unawaited(
                        context.pushTo(
                          AppRoute.dashboardChart,
                          pathParameters: <String, String>{
                            'chartId': card.id,
                          },
                          extra: activeFilter,
                        ),
                      );
                    },
                  ),
                );
              }).toList(growable: false),
            );
          },
        );
      },
    );
  }
}
