import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_chart_card_descriptor_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card_density.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Compact navigation grid for lazy-loaded overview chart detail pages.
class OverviewChartNavGrid extends StatelessWidget {
  const OverviewChartNavGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Selector<OverviewController, Set<String>>(
      selector: (_, controller) => controller.chartNavReadySections
          .map((section) => section.name)
          .toSet(),
      builder: (context, readySectionNames, _) {
        return AppHubNavigationGrid(
          density: AppHubNavigationCardDensity.overview,
          itemCount: allOverviewChartCards.length,
          itemBuilder: (context, index, layout) {
            final card = allOverviewChartCards[index];
            final isReady = readySectionNames.contains(card.section.name);
            final title = card.resolvedTitle(l10n);
            final semanticsLabel = isReady
                ? title
                : '$title, ${l10n.overviewChartNavLoadingSemanticsSuffix}';

            return AppHubNavigationCard(
              density: AppHubNavigationCardDensity.overview,
              icon: card.icon,
              label: title,
              labelStyle: layout.narrowLabelStyle,
              showReadyBadge: isReady,
              semanticsLabel: semanticsLabel,
              aspectRatio: layout.aspectRatio,
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
            );
          },
        );
      },
    );
  }
}
