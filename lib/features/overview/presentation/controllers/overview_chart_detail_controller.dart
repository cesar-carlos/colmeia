import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_load_session.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

typedef OverviewChartFailureMessageBuilder =
    String Function(AppFailure failure);

class OverviewChartDetailController extends ChangeNotifier {
  OverviewChartDetailController({
    required String chartId,
    required LoadOverviewSectionsUseCase loadOverviewSectionsUseCase,
    required OverviewShellCache shellCache,
    DashboardFilter? initialFilter,
    RetryAfterGate? retryAfterGate,
    OverviewRelayCancelScopeBinder? relayCancelScopeBinder,
  }) : _chartId = chartId,
       _loadOverviewSectionsUseCase = loadOverviewSectionsUseCase,
       _shellCache = shellCache,
       _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
       _ownsRetryAfterGate = retryAfterGate == null,
       _activeFilter =
           initialFilter ??
           shellCache.latestEntry?.activeFilter ??
           DashboardFilter.initial(),
       _session = OverviewLoadSession(
         relayCancelScopeBinder: relayCancelScopeBinder,
       ) {
    _descriptor = overviewChartCardById(chartId);
    _sectionRequest = _descriptor == null
        ? null
        : OverviewSectionRequest.forChartSection(_descriptor!.section);
  }

  final String _chartId;
  final LoadOverviewSectionsUseCase _loadOverviewSectionsUseCase;
  final OverviewShellCache _shellCache;
  final RetryAfterGate _retryAfterGate;
  final bool _ownsRetryAfterGate;
  final OverviewLoadSession _session;

  OverviewChartCardDescriptor? _descriptor;
  OverviewSectionRequest? _sectionRequest;
  OverviewProgressiveSection? get section => _descriptor?.section;

  Overview? _overview;
  bool _isLoading = false;
  String? _errorMessage;
  AppFailure? _loadFailure;
  bool _disposed = false;
  final DashboardFilter _activeFilter;

  Overview? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppFailure? get loadFailure => _loadFailure;
  bool get hasContent => _overview != null;
  DashboardFilter get activeFilter => _activeFilter;

  List<DashboardAgentOption> get availableAgents =>
      _shellCache.latestEntry?.availableAgents ??
      const <DashboardAgentOption>[];
  OverviewChartCardDescriptor? get descriptor => _descriptor;
  bool get isOnRetryCooldown => !_retryAfterGate.isOpen;

  @override
  void dispose() {
    _disposed = true;
    if (_ownsRetryAfterGate) {
      _retryAfterGate.dispose();
    }
    _session.dispose();
    super.dispose();
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> loadIfNeeded({
    required String userId,
    OverviewLoadLabels? rowLabels,
    OverviewChartFailureMessageBuilder? failureMessageBuilder,
  }) async {
    final descriptor = _descriptor;
    final sectionRequest = _sectionRequest;
    if (descriptor == null || sectionRequest == null) {
      return;
    }

    if (isOnRetryCooldown) {
      return;
    }

    final signature = overviewLoadSignature(
      userId: userId,
      filter: _activeFilter,
    );
    final shellEntry = _shellCache.read(signature);
    if (shellEntry != null &&
        shellEntry.completedSections.contains(descriptor.section)) {
      _overview = shellEntry.overview;
      _errorMessage = null;
      _loadFailure = null;
      _isLoading = false;
      _notifyIfAlive();
      return;
    }

    final generation = _session.begin(signature);
    final cancelScope = _session.cancelScope!;
    _isLoading = true;
    _errorMessage = null;
    _loadFailure = null;
    _overview = null;
    _notifyIfAlive();

    final resolvedLabels = rowLabels ?? OverviewLoadLabels.englishFallback;
    final resolvedFailureBuilder =
        failureMessageBuilder ??
        (failure) => failure.userMessage ?? failure.message;

    await for (final result in _loadOverviewSectionsUseCase.progressively(
      userId: userId,
      sectionRequest: sectionRequest,
      filter: _activeFilter,
      rowLabels: resolvedLabels,
      cancelScope: cancelScope,
    )) {
      if (_session.isStale(generation)) {
        return;
      }

      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _overview = snapshot.overview;
        _errorMessage = null;
        _loadFailure = null;
        if (snapshot.isFinal) {
          _isLoading = false;
          _session.loadedSignature = signature;
          if (sectionRequest.isSectionBatchOnly) {
            _shellCache.mergePublish(
              signature: signature,
              detailOverview: snapshot.overview,
              section: descriptor.section,
              addedSections: sectionRequest.completedWhenFinal(),
            );
          }
          _notifyIfAlive();
          return;
        }
        _notifyIfAlive();
        continue;
      }

      final failure = result.exceptionOrNull();
      if (failure != null) {
        _isLoading = false;
        _loadFailure = failure;
        _errorMessage = resolvedFailureBuilder(failure);
        armAgentQueryRetryAfterGate(_retryAfterGate, failure);
        AppLogger.warning(
          'Overview chart detail load failed',
          context: <String, Object?>{
            'operation': 'loadOverviewChartDetail',
            'chartId': _chartId,
            'userId': userId,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        _notifyIfAlive();
        return;
      }
    }

    if (!_session.isStale(generation)) {
      _isLoading = false;
      _notifyIfAlive();
    }
  }

  Future<void> retry({
    required String userId,
    OverviewLoadLabels? rowLabels,
    OverviewChartFailureMessageBuilder? failureMessageBuilder,
  }) {
    if (isOnRetryCooldown) {
      return Future<void>.value();
    }
    _session.resetRequested();
    return loadIfNeeded(
      userId: userId,
      rowLabels: rowLabels,
      failureMessageBuilder: failureMessageBuilder,
    );
  }
}
