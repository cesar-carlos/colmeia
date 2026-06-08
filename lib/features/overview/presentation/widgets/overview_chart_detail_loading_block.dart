import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_progressive_section_loading_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_detail_content.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_staged_block.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:flutter/material.dart';

/// Staged chart skeleton for overview chart detail pages.
class OverviewChartDetailLoadingBlock extends StatelessWidget {
  const OverviewChartDetailLoadingBlock({
    required this.l10n,
    required this.section,
    super.key,
  });

  final AppLocalizations l10n;
  final OverviewProgressiveSection section;

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
        animateEntrance: false,
      ),
    );
  }
}
