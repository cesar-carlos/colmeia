import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/localization/app_localizations_fallback.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/localization/overview_failure_l10n.dart';
import 'package:colmeia/features/overview/presentation/overview_available_agents_assembler.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_agent_names_list_sheet.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class OverviewController extends ChangeNotifier {
  OverviewController(
    this._loadOverviewUseCase,
    this._clientAgentsRepository,
  );

  final LoadOverviewUseCase _loadOverviewUseCase;
  final ClientAgentsRepository _clientAgentsRepository;

  AppLocalizations? _l10n;

  /// Set from the active page context (`OverviewHomePage`) for localized
  /// error messages.
  AppLocalizations? get activeLocalizations => _l10n;

  set activeLocalizations(AppLocalizations value) => _l10n = value;

  AppLocalizations get _s =>
      _l10n ?? fallbackAppLocalizationsForPlatform();

  Overview? _overview;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _requestedOverviewSignature;
  String? _loadedOverviewSignature;
  int _loadGeneration = 0;
  bool _disposed = false;

  OverviewFilter _activeFilter = OverviewFilter.initial();

  /// The filter currently applied to the overview.
  OverviewFilter get activeFilter => _activeFilter;

  /// Agent options derived from the last successful overview load.
  ///
  /// Populated after the first successful load so the filter bar can show
  /// agent names. Empty until data arrives.
  List<OverviewAgentOption> _availableAgents = const <OverviewAgentOption>[];
  List<OverviewAgentOption> get availableAgents => _availableAgents;

  Overview? _normalizedNamesCacheRef;
  List<String> _missingTokenNamesNormalized = const <String>[];
  List<String> _partialFailureNamesNormalized = const <String>[];

  /// Normalized display names for missing-token alerts (trim, sort, dedupe).
  List<String> get missingTokenAgentNamesNormalized {
    _ensureNormalizedAlertNamesCache();
    return _missingTokenNamesNormalized;
  }

  /// Normalized display names for partial query failure alerts.
  List<String> get partialQueryFailureAgentNamesNormalized {
    _ensureNormalizedAlertNamesCache();
    return _partialFailureNamesNormalized;
  }

  void _ensureNormalizedAlertNamesCache() {
    final o = _overview;
    if (identical(o, _normalizedNamesCacheRef)) {
      return;
    }
    _normalizedNamesCacheRef = o;
    if (o == null) {
      _missingTokenNamesNormalized = const <String>[];
      _partialFailureNamesNormalized = const <String>[];
      return;
    }
    _missingTokenNamesNormalized = normalizeOverviewAgentNames(
      o.agentNamesMissingClientToken,
    );
    _partialFailureNamesNormalized = normalizeOverviewAgentNames(
      o.agentNamesExcludedFromQueryFailure,
    );
  }

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

  Overview? get overview => _overview;
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get hasContent => _overview != null;
  String? get errorMessage => _errorMessage;

  /// Applies [filter] and immediately reloads the overview.
  Future<void> applyFilter({
    required String userId,
    required OverviewFilter filter,
  }) async {
    _activeFilter = filter;
    _requestedOverviewSignature = null;
    await _loadOverview(
      userId: userId,
      policy: OverviewLoadPolicy.forceRefresh,
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
      policy: OverviewLoadPolicy.defaultLoad,
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
      policy: OverviewLoadPolicy.forceRefresh,
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
          ? OverviewLoadPolicy.forceRefresh
          : OverviewLoadPolicy.defaultLoad,
      keepContentVisible: keepContentVisible,
    );
  }

  Future<void> _loadOverview({
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
  }) async {
    final signature = _signatureFor(userId: userId);
    _requestedOverviewSignature = signature;
    final generation = ++_loadGeneration;

    AppLogger.debug(
      'Starting overview load in controller',
      context: <String, Object?>{
        'operation': 'loadOverview',
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

    final result = await _loadOverviewUseCase(
      userId: userId,
      policy: policy,
      filter: _activeFilter,
    );
    if (_disposed || generation != _loadGeneration) {
      return;
    }

    final overview = result.getOrNull();
    if (overview != null) {
      _overview = overview;
      _loadedOverviewSignature = signature;
      await _updateAvailableAgents(overview, userId);
      AppLogger.info(
        'Overview loaded in controller',
        context: <String, Object?>{
          'operation': 'loadOverview',
          'userId': userId,
          'paymentMethods': overview.paymentMethods.length,
          'policy': policy.name,
        },
      );
    } else {
      final failure = result.exceptionOrNull();
      if (failure != null) {
        if (!keepContentVisible) {
          _overview = null;
          _loadedOverviewSignature = null;
        }
        _errorMessage = overviewFailureUserMessage(failure, _s);
        AppLogger.warning(
          'Overview load failed in controller',
          context: <String, Object?>{
            'operation': 'loadOverview',
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
      }
    }

    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoadingInitial = false;
    }
    _notifyListenersIfAlive();
  }

  String _signatureFor({required String userId}) {
    final ids = _activeFilter.selectedAgentIds;
    final agentPart = ids == null
        ? '*'
        : (List<String>.from(ids)..sort()).join(',');
    return '$userId|$agentPart|${_activeFilter.yearMonth ?? 'default'}';
  }

  /// Rebuilds [_availableAgents] from the overview (per-agent rankings and
  /// failure metadata). Uses names resolved by the repository.
  Future<void> _updateAvailableAgents(Overview overview, String userId) async {
    final onlineIds = await _clientAgentsRepository.loadOnlineAgentIds(
      userId: userId,
    );

    if (_disposed) {
      return;
    }

    final assembled = OverviewAvailableAgentsAssembler.assemble(
      overview: overview,
      previousOptions: _availableAgents,
      onlineAgentIds: onlineIds,
    );
    if (assembled.isEmpty) {
      return;
    }
    _availableAgents = assembled;
  }
}
