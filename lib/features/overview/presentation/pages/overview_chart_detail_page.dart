import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_chart_detail_controller.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_chart_card_descriptor_l10n.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_failure_l10n.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_load_labels_l10n.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_detail_content.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart'
    show AppInlineErrorPanel, AppInlinePanelTone;
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverviewChartDetailPage extends StatefulWidget {
  const OverviewChartDetailPage({
    required this.chartId,
    super.key,
  });

  final String chartId;

  @override
  State<OverviewChartDetailPage> createState() =>
      _OverviewChartDetailPageState();
}

class _OverviewChartDetailPageState extends State<OverviewChartDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleLoad());
  }

  void _scheduleLoad() {
    if (!mounted) {
      return;
    }
    final session = context.read<AuthController>().session;
    if (session == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    unawaited(
      context.read<OverviewChartDetailController>().loadIfNeeded(
        userId: session.userId,
        rowLabels: l10n.overviewLoadLabels,
        failureMessageBuilder: (failure) =>
            overviewFailureUserMessage(failure, l10n),
      ),
    );
  }

  Future<void> _retry() async {
    if (!mounted) {
      return;
    }
    final session = context.read<AuthController>().session;
    if (session == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    await context.read<OverviewChartDetailController>().retry(
      userId: session.userId,
      rowLabels: l10n.overviewLoadLabels,
      failureMessageBuilder: (failure) =>
          overviewFailureUserMessage(failure, l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final descriptor = overviewChartCardById(widget.chartId);
    final title = descriptor?.resolvedTitle(l10n) ?? l10n.shellNavDashboardLabel;

    return Selector<OverviewChartDetailController, _ChartDetailSlice>(
      selector: (_, controller) => _ChartDetailSlice(
        isLoading: controller.isLoading,
        hasContent: controller.hasContent,
        errorMessage: controller.errorMessage,
        overview: controller.overview,
        section: controller.section,
      ),
      builder: (context, slice, _) {
        return RefreshIndicator(
          semanticsLabel: l10n.overviewHomeRefreshSemanticsLabel,
          onRefresh: _retry,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: context.pageScrollPadding(
              tokens,
              horizontalAdjustment:
                  AppPageSpacingPresets.dashboardHorizontalAdjustment,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppShellPageIntro(
                  title: title,
                  subtitle: l10n.overviewHomeSubtitle,
                  sectionLabel: l10n.shellNavDashboardLabel,
                  onSectionLabelTap: () => context.goTo(AppRoute.dashboard),
                ),
                SizedBox(height: tokens.sectionSpacing),
                if (slice.errorMessage != null)
                  AppInlineErrorPanel(
                    message: slice.errorMessage!,
                    onRetry: () => unawaited(_retry()),
                  )
                else if (slice.isLoading && !slice.hasContent)
                  AppSkeleton(
                    enabled: true,
                    loadingSemanticsLabel: title,
                    child: SizedBox(height: tokens.chartStandardHeight),
                  )
                else if (slice.overview != null && slice.section != null)
                  OverviewChartDetailContent(
                    l10n: l10n,
                    section: slice.section!,
                    overview: slice.overview!,
                  )
                else if (!slice.isLoading && slice.overview == null)
                  AppInlineErrorPanel(
                    message: l10n.reportEmptyDefaultMessage,
                    tone: AppInlinePanelTone.informational,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

@immutable
class _ChartDetailSlice {
  const _ChartDetailSlice({
    required this.isLoading,
    required this.hasContent,
    required this.errorMessage,
    required this.overview,
    required this.section,
  });

  final bool isLoading;
  final bool hasContent;
  final String? errorMessage;
  final Overview? overview;
  final OverviewProgressiveSection? section;

  @override
  bool operator ==(Object other) {
    return other is _ChartDetailSlice &&
        other.isLoading == isLoading &&
        other.hasContent == hasContent &&
        other.errorMessage == errorMessage &&
        identical(other.overview, overview) &&
        other.section == section;
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    hasContent,
    errorMessage,
    overview,
    section,
  );
}
