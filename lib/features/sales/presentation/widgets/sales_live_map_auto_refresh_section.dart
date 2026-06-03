import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _kSalesLiveMapReloadProgressHeight = 2;

class SalesLiveMapAutoRefreshSection extends StatelessWidget {
  const SalesLiveMapAutoRefreshSection({
    required this.onOptionChanged,
    required this.onRefreshNow,
    required this.stateListenable,
    super.key,
  });

  final ValueChanged<AutoRefreshOption?> onOptionChanged;
  final VoidCallback onRefreshNow;
  final ValueListenable<AutoRefreshUiState> stateListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final autoRefreshSupported = salesAutoRefreshIsAvailableForViewport(
      context,
    );

    return ValueListenableBuilder<AutoRefreshUiState>(
      valueListenable: stateListenable,
      builder: (context, refreshState, _) {
        return Selector<SalesLiveMapController, _SalesLiveMapAutoRefreshSlice>(
          selector: (_, controller) => _SalesLiveMapAutoRefreshSlice.from(
            state: controller.state,
            retryRemainingSeconds:
                controller.retryAfterGate.remaining?.inSeconds ?? 0,
          ),
          builder: (context, slice, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SalesAutoRefreshActionsRow(
                  value: refreshState.option,
                  onChanged: onOptionChanged,
                  onRefreshNow: slice.canReload ? onRefreshNow : () {},
                  enabled: slice.canScheduleAutoRefresh,
                  refreshNowEnabled: slice.canReload,
                  options: SalesLiveMapAutoRefreshOptions.values,
                  lastUpdatedAt: refreshState.lastUpdatedAt,
                  nextDueAt: autoRefreshSupported
                      ? refreshState.nextDueAt
                      : null,
                  isBackingOff: refreshState.isBackingOff,
                  isPaused: refreshState.isPaused,
                  pauseReason: refreshState.pauseReason,
                  l10n: l10n,
                ),
                if (slice.showReloadProgress) ...<Widget>[
                  SizedBox(height: context.appTokens.gapSm),
                  const LinearProgressIndicator(
                    minHeight: _kSalesLiveMapReloadProgressHeight,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

@immutable
class _SalesLiveMapAutoRefreshSlice {
  const _SalesLiveMapAutoRefreshSlice({
    required this.canReload,
    required this.canScheduleAutoRefresh,
    required this.showReloadProgress,
  });

  factory _SalesLiveMapAutoRefreshSlice.from({
    required SalesLiveMapPresentationState state,
    required int retryRemainingSeconds,
  }) {
    final onCooldown = retryRemainingSeconds > 0;
    return _SalesLiveMapAutoRefreshSlice(
      canReload: state.canReload && !onCooldown,
      canScheduleAutoRefresh: state.canScheduleAutoRefresh,
      showReloadProgress: state.isLoading && state.result != null,
    );
  }

  final bool canReload;
  final bool canScheduleAutoRefresh;
  final bool showReloadProgress;

  @override
  bool operator ==(Object other) {
    return other is _SalesLiveMapAutoRefreshSlice &&
        other.canReload == canReload &&
        other.canScheduleAutoRefresh == canScheduleAutoRefresh &&
        other.showReloadProgress == showReloadProgress;
  }

  @override
  int get hashCode => Object.hash(
    canReload,
    canScheduleAutoRefresh,
    showReloadProgress,
  );
}
