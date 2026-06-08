import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_chart_card_descriptor_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _kOverviewNavCardWidth = 92;
const double _kOverviewNavCardHeight = 88;

/// Compact navigation grid for lazy-loaded overview chart detail pages.
class OverviewChartNavGrid extends StatelessWidget {
  const OverviewChartNavGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final gap = tokens.gapSm;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: allOverviewChartCards.map((card) {
        return SizedBox(
          width: _kOverviewNavCardWidth,
          height: _kOverviewNavCardHeight,
          child: AppHubNavigationCard(
            compact: true,
            icon: card.icon,
            label: card.resolvedTitle(l10n),
            aspectRatio: _kOverviewNavCardWidth / _kOverviewNavCardHeight,
            onTap: () {
              final activeFilter =
                  context.read<OverviewController>().activeFilter;
              unawaited(
                context.pushTo(
                  AppRoute.dashboardChart,
                  pathParameters: <String, String>{'chartId': card.id},
                  extra: activeFilter,
                ),
              );
            },
          ),
        );
      }).toList(growable: false),
    );
  }
}
