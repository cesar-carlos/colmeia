import 'package:colmeia/app/refresh/app_auto_refresh_support.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_option_set.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/material.dart';

abstract final class SalesAutoRefreshOptions {
  static const AutoRefreshOption fiveMinutes = AutoRefreshOption(
    id: 'fiveMinutes',
    duration: Duration(minutes: 5),
  );
  static const AutoRefreshOption tenMinutes = AutoRefreshOption(
    id: 'tenMinutes',
    duration: Duration(minutes: 10),
  );
  static const AutoRefreshOption fifteenMinutes = AutoRefreshOption(
    id: 'fifteenMinutes',
    duration: Duration(minutes: 15),
  );
  static const AutoRefreshOption thirtyMinutes = AutoRefreshOption(
    id: 'thirtyMinutes',
    duration: Duration(minutes: 30),
  );

  static final AutoRefreshOptionSet optionSet = AutoRefreshOptionSet(
    values: const <AutoRefreshOption>[
      fiveMinutes,
      tenMinutes,
      fifteenMinutes,
      thirtyMinutes,
    ],
  );

  static List<AutoRefreshOption> get values => optionSet.values;
}

abstract final class SalesAutoRefreshCardIds {
  static const String dailyTotals = 'daily_totals';
  static const String monthlyPnl = 'monthly_pnl';
  static const String liveMap = 'sales_live_map';
  static const String produtoRankLucro = 'produto_rank_lucro';
  static const String produtoTendencia = 'produto_tendencia_venda';
  static const String produtoTendenciaMediaMovel =
      'produto_tendencia_venda_media_movel';
}

extension SalesAutoRefreshOptionLabel on AutoRefreshOption {
  String get salesLabel => switch (id) {
    'fiveMinutes' => '5 min',
    'tenMinutes' => '10 min',
    'fifteenMinutes' => '15 min',
    'thirtyMinutes' => '30 min',
    _ => id,
  };
}

bool salesAutoRefreshIsAvailableForViewport(BuildContext context) =>
    AppBreakpoints.isDesktop(context);

bool salesAutoRefreshCanScheduleSelectedAgent({
  required String? selectedAgentId,
  required List<DashboardAgentOption> availableAgents,
}) {
  final trimmedAgentId = selectedAgentId?.trim();
  if (trimmedAgentId == null || trimmedAgentId.isEmpty) {
    return false;
  }
  for (final agent in availableAgents) {
    if (agent.agentId == trimmedAgentId) {
      return !agent.missingLocalClientToken;
    }
  }
  return false;
}

mixin SalesCardAutoRefreshBinding<T extends StatefulWidget> on State<T> {
  @protected
  bool get supportsAutoRefresh =>
      salesAutoRefreshIsAvailableForViewport(context);

  @protected
  SalesSessionService get salesSessionService;

  @protected
  String get salesAutoRefreshCardId;

  @protected
  RouteObserver<ModalRoute<void>>? get autoRefreshRouteObserver =>
      AppAutoRefreshSupport.routeObserver;

  @protected
  AutoRefreshStatePersistence get autoRefreshStatePersistence =>
      SalesCardAutoRefreshPersistence(
        sessionService: salesSessionService,
        cardId: salesAutoRefreshCardId,
        optionSet: SalesAutoRefreshOptions.optionSet,
      );

  @protected
  void logAutoRefreshInfo(String message, Map<String, Object?> context) {
    AppAutoRefreshSupport.logInfo(message, <String, Object?>{
      'cardId': salesAutoRefreshCardId,
      ...context,
    });
  }

  @protected
  void logAutoRefreshWarning(String message, Map<String, Object?> context) {
    AppAutoRefreshSupport.logWarning(message, <String, Object?>{
      'cardId': salesAutoRefreshCardId,
      ...context,
    });
  }
}

class SalesCardAutoRefreshPersistence implements AutoRefreshStatePersistence {
  const SalesCardAutoRefreshPersistence({
    required this.sessionService,
    required this.cardId,
    required this.optionSet,
  });

  final SalesSessionService sessionService;
  final String cardId;
  final AutoRefreshOptionSet optionSet;

  @override
  AutoRefreshSnapshot restoreAutoRefreshSnapshot() {
    return sessionService.restoreAutoRefreshSnapshot(
      cardId: cardId,
      optionSet: optionSet,
    );
  }

  @override
  Future<void> persistAutoRefreshSnapshot(AutoRefreshSnapshot snapshot) {
    return sessionService.persistAutoRefreshSnapshot(
      cardId: cardId,
      snapshot: snapshot,
    );
  }
}
