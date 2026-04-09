import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:colmeia/features/dashboards/presentation/localization/dashboard_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._loadDashboardOverviewUseCase);

  final LoadDashboardOverviewUseCase _loadDashboardOverviewUseCase;

  AppLocalizations? _l10n;

  /// Set from the active page context (`DashboardHomePage`) for localized
  /// error messages.
  AppLocalizations? get activeLocalizations => _l10n;

  set activeLocalizations(AppLocalizations value) => _l10n = value;

  AppLocalizations get _s => _l10n ?? AppLocalizationsEn();

  DashboardOverview? _overview;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _requestedOverviewSignature;
  String? _loadedOverviewSignature;
  int _loadGeneration = 0;
  bool _disposed = false;

  DashboardFilter _activeFilter = const DashboardFilter();

  /// The filter currently applied to the dashboard.
  DashboardFilter get activeFilter => _activeFilter;

  /// Agent options derived from the last successful overview load.
  ///
  /// Populated after the first successful load so the filter bar can show
  /// agent names. Empty until data arrives.
  List<DashboardAgentOption> _availableAgents = const <DashboardAgentOption>[];
  List<DashboardAgentOption> get availableAgents => _availableAgents;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  DashboardOverview? get overview => _overview;
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get hasContent => _overview != null;
  String? get errorMessage => _errorMessage;

  /// Applies [filter] and immediately reloads the overview.
  Future<void> applyFilter({
    required String userId,
    required DashboardFilter filter,
  }) async {
    _activeFilter = filter;
    _requestedOverviewSignature = null;
    await _loadOverview(
      userId: userId,
      policy: DashboardLoadPolicy.forceRefresh,
      keepContentVisible: _overview != null,
    );
  }

  /// Schedules [loadOverview] after the current frame when the
  /// user changes. Safe to call from widget build methods.
  void scheduleOverviewLoadIfNeeded({
    required String userId,
  }) {
    final signature = _signatureFor(userId: userId);
    if (_requestedOverviewSignature == signature) {
      return;
    }
    _requestedOverviewSignature = signature;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_requestedOverviewSignature != signature) {
        return;
      }
      unawaited(
        loadOverview(
          userId: userId,
        ),
      );
    });
  }

  Future<void> loadOverview({
    required String userId,
  }) async {
    await _loadOverview(
      userId: userId,
      policy: DashboardLoadPolicy.defaultLoad,
      keepContentVisible: false,
    );
  }

  Future<void> refreshOverview({
    required String userId,
  }) async {
    final signature = _signatureFor(userId: userId);
    final keepContentVisible =
        _loadedOverviewSignature == signature && _overview != null;
    await _loadOverview(
      userId: userId,
      policy: DashboardLoadPolicy.forceRefresh,
      keepContentVisible: keepContentVisible,
    );
  }

  Future<void> retryOverview({
    required String userId,
  }) async {
    final signature = _signatureFor(userId: userId);
    final keepContentVisible =
        _loadedOverviewSignature == signature && _overview != null;
    await _loadOverview(
      userId: userId,
      policy: keepContentVisible
          ? DashboardLoadPolicy.forceRefresh
          : DashboardLoadPolicy.defaultLoad,
      keepContentVisible: keepContentVisible,
    );
  }

  Future<void> _loadOverview({
    required String userId,
    required DashboardLoadPolicy policy,
    required bool keepContentVisible,
  }) async {
    final signature = _signatureFor(userId: userId);
    _requestedOverviewSignature = signature;
    final generation = ++_loadGeneration;

    AppLogger.debug(
      'Starting dashboard load in controller',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
        'userId': userId,
        'policy': policy.name,
        'keepContentVisible': keepContentVisible,
      },
    );

    if (keepContentVisible) {
      _isLoadingInitial = false;
      _isRefreshing = true;
    } else {
      _isRefreshing = false;
      _isLoadingInitial = true;
      _overview = null;
      _loadedOverviewSignature = null;
    }
    _errorMessage = null;
    _notifyListenersIfAlive();

    final result = await _loadDashboardOverviewUseCase(
      userId: userId,
      policy: policy,
      filter: _activeFilter,
    );
    if (_disposed || generation != _loadGeneration) {
      return;
    }

    result.fold(
      (overview) {
        _overview = overview;
        _loadedOverviewSignature = signature;
        _updateAvailableAgents(overview);
        AppLogger.info(
          'Dashboard loaded in controller',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'paymentMethods': overview.paymentMethods.length,
            'policy': policy.name,
          },
        );
      },
      (failure) {
        if (!keepContentVisible) {
          _overview = null;
          _loadedOverviewSignature = null;
        }
        _errorMessage = dashboardFailureUserMessage(failure, _s);
        AppLogger.warning(
          'Dashboard load failed in controller',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'policy': policy.name,
            'keepContentVisible': keepContentVisible,
            'technicalMessage': switch (failure) {
              RpcFailure(:final technicalMessage) => technicalMessage,
              _ => failure.message,
            },
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );

    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoadingInitial = false;
    }
    _notifyListenersIfAlive();
  }

  String _signatureFor({required String userId}) {
    return '$userId|${_activeFilter.selectedAgentId ?? '*'}'
        '|${_activeFilter.yearMonth ?? 'default'}';
  }

  /// Rebuilds [_availableAgents] from the approved-agent metadata stored in
  /// the overview.  Uses the names already resolved by the repository so we
  /// never need a separate agents call here.
  void _updateAvailableAgents(DashboardOverview overview) {
    // Collect all agent ids/names we know about from the overview metadata.
    final seen = <String, String>{};
    for (var i = 0;
        i < overview.agentIdsExcludedFromQueryFailure.length;
        i++) {
      final id = overview.agentIdsExcludedFromQueryFailure[i];
      final name = i < overview.agentNamesExcludedFromQueryFailure.length
          ? overview.agentNamesExcludedFromQueryFailure[i]
          : id;
      seen[id] = name;
    }
    for (var i = 0; i < overview.agentIdsMissingClientToken.length; i++) {
      final id = overview.agentIdsMissingClientToken[i];
      final name = i < overview.agentNamesMissingClientToken.length
          ? overview.agentNamesMissingClientToken[i]
          : id;
      seen[id] = name;
    }

    // The overview itself doesn't carry the full agent list, so we keep
    // whatever we already have and merge new names in.
    final merged = <String, String>{
      for (final opt in _availableAgents) opt.agentId: opt.name,
      ...seen,
    };

    if (merged.isEmpty) {
      return;
    }

    _availableAgents = merged.entries
        .map((e) => DashboardAgentOption(agentId: e.key, name: e.value))
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
