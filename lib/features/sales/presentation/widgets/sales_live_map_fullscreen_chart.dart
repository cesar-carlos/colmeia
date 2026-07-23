import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_map_chrome_fingerprint.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_chart_panel.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_inline_chart_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesLiveMapFullscreenHeader extends StatelessWidget {
  const SalesLiveMapFullscreenHeader({required this.controller, super.key});

  final SalesLiveMapController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SalesLiveMapController>.value(
      value: controller,
      child:
          Selector<SalesLiveMapController, _SalesLiveMapFullscreenHeaderSlice>(
            selector: (_, controller) =>
                _SalesLiveMapFullscreenHeaderSlice.fromState(controller.state),
            builder: (context, slice, _) {
              final l10n = AppLocalizations.of(context);
              final viewModel = SalesLiveMapViewModel.fromState(
                slice.state,
                l10n,
              );
              return AppChartFullscreenHeader(
                title: l10n.salesLiveMapChartTitle,
                subtitle: viewModel.mapSubtitle,
                filterSummary: viewModel.fullscreenFilterSummary,
              );
            },
          ),
    );
  }
}

class SalesLiveMapFullscreenChart extends StatelessWidget {
  const SalesLiveMapFullscreenChart({required this.controller, super.key});

  final SalesLiveMapController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SalesLiveMapController>.value(
      value: controller,
      child: Selector<SalesLiveMapController, SalesLiveMapMapSlice>(
        selector: (_, controller) =>
            SalesLiveMapMapSlice.fromState(controller.state),
        builder: (context, slice, _) {
          return SalesLiveMapChartPanel(
            mode: SalesLiveMapChartPanelMode.fullscreen,
            mapPayloadDigest: slice.mapPayloadDigest,
            points: slice.points,
            metric: slice.metric,
            filterBranchIds: slice.filterBranchIds,
            visualSpec: slice.visualSpec,
            isRefreshing: slice.isRefreshing,
            onMetricChanged: controller.updateMetric,
            showSidebar: true,
            showHeader: false,
          );
        },
      ),
    );
  }
}

@immutable
class _SalesLiveMapFullscreenHeaderSlice {
  const _SalesLiveMapFullscreenHeaderSlice({
    required this.state,
    required this.chrome,
  });

  factory _SalesLiveMapFullscreenHeaderSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return _SalesLiveMapFullscreenHeaderSlice(
      state: state,
      chrome: SalesLiveMapMapChromeFingerprint.from(state),
    );
  }

  final SalesLiveMapPresentationState state;
  final SalesLiveMapMapChromeFingerprint chrome;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapFullscreenHeaderSlice &&
        other.chrome == chrome &&
        other.state.filter == state.filter &&
        other.state.isLoading == state.isLoading;
  }

  @override
  int get hashCode => Object.hash(chrome, state.filter, state.isLoading);
}
