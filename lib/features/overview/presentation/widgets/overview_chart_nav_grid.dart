import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_chart_card_descriptor_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_hub_navigation_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Compact navigation grid for lazy-loaded overview chart detail pages.
class OverviewChartNavGrid extends StatelessWidget {
  const OverviewChartNavGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.mobile;
        final cols = math.max(
          1,
          math.min(isWide ? 3 : 2, allOverviewChartCards.length),
        );
        final gap = tokens.gapMd;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: allOverviewChartCards.map((card) {
            final width =
                ((constraints.maxWidth - (gap * (cols - 1))) / cols)
                    .floorToDouble();
            return SizedBox(
              width: width,
              child: AppHubNavigationCard(
                icon: card.icon,
                label: card.resolvedTitle(l10n),
                aspectRatio: 1.35,
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
      },
    );
  }
}
