import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_progressive_section_loading_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_detail_content.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_staged_block.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/material.dart';

/// Staged chart skeleton for overview chart detail pages.
class OverviewChartDetailLoadingBlock extends StatelessWidget {
  const OverviewChartDetailLoadingBlock({
    required this.l10n,
    required this.section,
    required this.filter,
    required this.availableAgents,
    super.key,
  });

  final AppLocalizations l10n;
  final OverviewProgressiveSection section;
  final DashboardFilter filter;
  final List<DashboardAgentOption> availableAgents;

  @override
  Widget build(BuildContext context) {
    final motion = context.appMotion;

    return OverviewChartStagedBlock(
      visualState: OverviewChartStageVisualState.skeletonWithChart,
      showDelay: motion.dashboardStageDelay(0),
      loadingSemanticsLabel: section.loadingSemanticsLabel(l10n),
      child: OverviewChartDetailContent(
        l10n: l10n,
        section: section,
        overview: Overview.empty(),
        filter: filter,
        availableAgents: availableAgents,
        animateEntrance: false,
      ),
    );
  }
}
