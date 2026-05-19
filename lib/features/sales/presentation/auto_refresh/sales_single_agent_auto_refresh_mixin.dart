import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:flutter/material.dart';

mixin SalesSingleAgentAutoRefreshMixin<T extends StatefulWidget>
    on State<T>, AutoRefreshStateMixin<T> {
  AutoRefreshReloadResult _lastAutoRefreshReloadResult =
      const AutoRefreshReloadResult.cancelled();

  @protected
  String? get autoRefreshSelectedAgentId;

  @protected
  List<OverviewAgentOption> get autoRefreshAvailableAgents;

  @protected
  bool get autoRefreshPageLoading;

  @protected
  OverviewAgentOption? get selectedAutoRefreshAgentOption {
    final selectedAgentId = autoRefreshSelectedAgentId?.trim();
    if (selectedAgentId == null || selectedAgentId.isEmpty) {
      return null;
    }
    for (final agent in autoRefreshAvailableAgents) {
      if (agent.agentId == selectedAgentId) {
        return agent;
      }
    }
    return null;
  }

  @override
  bool get canScheduleAutoRefresh => resolveAutoRefreshPauseReason() == null;

  @override
  AutoRefreshReloadResult resolveAutoRefreshReloadResult() =>
      _lastAutoRefreshReloadResult;

  @override
  AutoRefreshPauseReason? resolveAutoRefreshPauseReason() {
    if (autoRefreshPageLoading) {
      return AutoRefreshPauseReason.pageLoading;
    }
    final selectedAgentId = autoRefreshSelectedAgentId?.trim();
    if (selectedAgentId == null || selectedAgentId.isEmpty) {
      return AutoRefreshPauseReason.noEligibleSelection;
    }
    final selectedAgent = selectedAutoRefreshAgentOption;
    if (selectedAgent == null) {
      return AutoRefreshPauseReason.noEligibleSelection;
    }
    if (selectedAgent.missingLocalClientToken) {
      return AutoRefreshPauseReason.missingLocalToken;
    }
    return null;
  }

  @protected
  void markAutoRefreshSuccess([DateTime? refreshedAt]) {
    _lastAutoRefreshReloadResult = AutoRefreshReloadResult.success(
      refreshedAt ?? currentAutoRefreshTime,
    );
  }

  @protected
  void markAutoRefreshFailure() {
    _lastAutoRefreshReloadResult = const AutoRefreshReloadResult.failure();
  }

  @protected
  void markAutoRefreshCancelled() {
    _lastAutoRefreshReloadResult = const AutoRefreshReloadResult.cancelled();
  }
}
