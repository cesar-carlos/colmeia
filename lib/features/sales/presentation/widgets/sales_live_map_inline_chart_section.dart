import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/features/sales/presentation/rules/sales_live_map_presentation_rules.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_operational_fingerprint.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_chart_panel.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapInlineChartSection extends StatelessWidget {
  const SalesLiveMapInlineChartSection({
    required this.onOpenFullscreen,
    required this.recoveryRequestId,
    this.onRequestShare,
    this.suspendParentScrollLock = false,
    super.key,
  });

  final VoidCallback onOpenFullscreen;
  final AppChartShareRequestCallback? onRequestShare;
  final int recoveryRequestId;
  final bool suspendParentScrollLock;

  @override
  Widget build(BuildContext context) {
    return Selector<SalesLiveMapController, SalesLiveMapMapSlice>(
      selector: (_, controller) =>
          SalesLiveMapMapSlice.fromState(controller.state),
      builder: (context, slice, _) {
        final l10n = AppLocalizations.of(context);
        final controller = context.read<SalesLiveMapController>();
        final viewModel = SalesLiveMapViewModel.fromState(slice.state, l10n);
        if (SalesLiveMapViewModel.shouldShowChartFailurePlaceholder(
          slice.state,
        )) {
          final result = slice.state.result;
          final tokens = context.appTokens;
          return AppSectionCard(
            child: AgentQueryChartFailurePlaceholderContent(
              emptyMessage: SalesLiveMapViewModel.chartLoadFailureMessage(
                slice.state,
                l10n,
              ),
              textStyle: Theme.of(context).textTheme.bodyMedium,
              verticalPadding: tokens.contentSpacing,
              loadFailure: result?.loadFailure,
            ),
          );
        }
        return SalesLiveMapChartPanel(
          mode: SalesLiveMapChartPanelMode.inline,
          mapPayloadDigest: slice.mapPayloadDigest,
          lifecycleRecoveryRequestId: recoveryRequestId,
          suspendParentScrollLock: suspendParentScrollLock,
          title: l10n.salesLiveMapChartTitle,
          subtitle: viewModel.mapSubtitle,
          points: slice.points,
          metric: slice.metric,
          filterBranchIds: slice.filterBranchIds,
          visualSpec: slice.visualSpec,
          isRefreshing: slice.isRefreshing,
          onMetricChanged: controller.updateMetric,
          onOpenFullscreen: onOpenFullscreen,
          onRequestShare: onRequestShare,
        );
      },
    );
  }
}

@immutable
class SalesLiveMapMapSlice {
  const SalesLiveMapMapSlice({
    required this.state,
    required this.points,
    required this.mapPayloadDigest,
    required this.metric,
    required this.filterBranchIds,
    required this.visualSpec,
    required this.isRefreshing,
    required this.showChartFailurePlaceholder,
    required this.operational,
  });

  factory SalesLiveMapMapSlice.fromState(SalesLiveMapPresentationState state) {
    final filterBranchIds = Set<String>.unmodifiable(
      state.filterBranchStorageKeys,
    );
    return SalesLiveMapMapSlice(
      state: state,
      points: state.visualResult?.points ?? const <SalesLiveMapPoint>[],
      mapPayloadDigest: state.mapPayloadDigest,
      metric: state.filter.metric,
      filterBranchIds: filterBranchIds,
      visualSpec: SalesLiveMapPresentationRules.visualSpec(state),
      isRefreshing: state.isMapRefreshing,
      showChartFailurePlaceholder:
          SalesLiveMapViewModel.shouldShowChartFailurePlaceholder(state),
      operational: SalesLiveMapOperationalFingerprint.from(state.result),
    );
  }

  final SalesLiveMapPresentationState state;
  final List<SalesLiveMapPoint> points;
  final int mapPayloadDigest;
  final SalesLiveMapMetric metric;
  final Set<String> filterBranchIds;
  final SalesLiveMapVisualSpec visualSpec;
  final bool isRefreshing;
  final bool showChartFailurePlaceholder;
  final SalesLiveMapOperationalFingerprint operational;

  @override
  bool operator ==(Object other) {
    return other is SalesLiveMapMapSlice &&
        other.mapPayloadDigest == mapPayloadDigest &&
        other.metric == metric &&
        setEquals(other.filterBranchIds, filterBranchIds) &&
        other.visualSpec == visualSpec &&
        other.isRefreshing == isRefreshing &&
        other.showChartFailurePlaceholder == showChartFailurePlaceholder &&
        other.operational == operational;
  }

  @override
  int get hashCode => Object.hash(
    mapPayloadDigest,
    metric,
    Object.hashAll(filterBranchIds.toList(growable: false)..sort()),
    visualSpec,
    isRefreshing,
    showChartFailurePlaceholder,
    operational,
  );
}
