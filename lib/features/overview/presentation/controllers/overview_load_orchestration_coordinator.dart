import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/agent_queries/application/agent_query_retry_after.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/application/overview_app_failure_diagnostic.dart';
import 'package:colmeia/features/overview/application/overview_prefetch_session.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_load_session.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
/// Surface the load orchestration coordinator needs from the overview
/// controller host.
abstract interface class OverviewLoadOrchestrationHost {
  bool get disposed;

  DashboardFilter get activeFilter;

  set activeFilter(DashboardFilter value);

  Overview? get overview;

  void setOverview(Overview? overview);

  bool get isLoadingInitial;

  bool get isRefreshing;

  set isLoadingInitial(bool value);

  set isRefreshing(bool value);

  String? get errorMessage;

  set errorMessage(String? value);

  AppFailure? get loadFailure;

  set loadFailure(AppFailure? value);

  String? get errorDiagnosticBody;

  set errorDiagnosticBody(String? value);

  Set<OverviewProgressiveSection> get completedOverviewSections;

  set completedOverviewSections(Set<OverviewProgressiveSection> value);

  OverviewLoadSession get session;

  OverviewPrefetchSession get prefetchSession;

  OverviewShellCache? get shellCache;

  RetryAfterGate get retryAfterGate;

  void notifyOverviewChanged();

  bool isOverviewLoadStale(int generation);

  Future<bool> updateAvailableAgents(
    Overview overview,
    String userId,
    int generation,
  );

  void scheduleSectionPrefetch({
    required String userId,
    required String signature,
    required int generation,
    required OverviewLoadLabels rowLabels,
  });

  void publishShellCache(String signature);
}

/// Owns the overview load lifecycle: begin/cancel scope, one-shot and
/// progressive paths, failure handling and retry-after arming.
class OverviewLoadOrchestrationCoordinator {
  OverviewLoadOrchestrationCoordinator({
    required OverviewLoadOrchestrationHost host,
    required LoadOverviewUseCase loadOverviewUseCase,
  }) : _host = host,
       _loadOverviewUseCase = loadOverviewUseCase;

  final OverviewLoadOrchestrationHost _host;
  final LoadOverviewUseCase _loadOverviewUseCase;

  Future<void> loadOverview({
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewLoadingMode loadingMode,
    required OverviewLoadLabels rowLabels,
    required OverviewFailureMessageBuilder failureMessageBuilder,
  }) async {
    final ctx = _beginLoad(
      userId: userId,
      keepContentVisible: keepContentVisible,
      loadingMode: loadingMode,
      policy: policy,
    );

    if (loadingMode == OverviewLoadingMode.progressive) {
      await _loadOverviewProgressively(
        userId: userId,
        policy: policy,
        keepContentVisible: keepContentVisible,
        rowLabels: rowLabels,
        failureMessageBuilder: failureMessageBuilder,
        signature: ctx.signature,
        generation: ctx.generation,
        sqlCancelScope: ctx.sqlCancelScope,
      );
      return;
    }

    final result = await _loadOverviewUseCase(
      userId: userId,
      policy: policy,
      filter: _host.activeFilter,
      rowLabels: rowLabels,
      cancelScope: ctx.sqlCancelScope,
      sectionRequest: OverviewSectionRequest.home,
    );
    if (_host.isOverviewLoadStale(ctx.generation)) {
      return;
    }

    final overview = result.getOrNull();
    if (overview != null) {
      _applyOneShotSuccess(
        overview: overview,
        signature: ctx.signature,
        userId: userId,
        policy: policy,
      );
    } else {
      final failure = result.exceptionOrNull();
      if (failure != null) {
        _applyFailure(
          failure,
          userId: userId,
          policy: policy,
          keepContentVisible: keepContentVisible,
          failureMessageBuilder: failureMessageBuilder,
        );
      }
    }

    if (keepContentVisible) {
      _host.isRefreshing = false;
    } else {
      _host.isLoadingInitial = false;
    }
    _host.notifyOverviewChanged();

    if (overview != null &&
        await _host.updateAvailableAgents(overview, userId, ctx.generation)) {
      _host.notifyOverviewChanged();
    }

    if (overview != null && !_host.isOverviewLoadStale(ctx.generation)) {
      _host.scheduleSectionPrefetch(
        userId: userId,
        signature: ctx.signature,
        generation: ctx.generation,
        rowLabels: rowLabels,
      );
    }
  }

  ({
    String signature,
    int generation,
    AgentQueriesCancelScope sqlCancelScope,
  })
  _beginLoad({
    required String userId,
    required bool keepContentVisible,
    required OverviewLoadingMode loadingMode,
    required OverviewLoadPolicy policy,
  }) {
    final normalized = _host.activeFilter
        .normalizedForHomeDashboardReferenceRange();
    if (normalized != _host.activeFilter) {
      _host.activeFilter = normalized;
      _host.notifyOverviewChanged();
    }
    final signature = overviewLoadSignature(
      userId: userId,
      filter: _host.activeFilter,
    );
    _host.prefetchSession.cancel();
    final generation = _host.session.begin(signature);
    final sqlCancelScope = _host.session.cancelScope!;

    AppLogger.debug(
      'Starting overview load in controller',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'policy': policy.name,
        'keepContentVisible': keepContentVisible,
        'loadingMode': loadingMode.name,
      },
    );

    if (keepContentVisible) {
      _host.isLoadingInitial = false;
      _host.isRefreshing = true;
    } else {
      _host.isRefreshing = false;
      _host.isLoadingInitial = true;
      _host.setOverview(null);
      _host.session.clearLoaded();
      _host.completedOverviewSections = const <OverviewProgressiveSection>{};
    }
    _host.errorMessage = null;
    _host.errorDiagnosticBody = null;
    _host.loadFailure = null;
    _host.notifyOverviewChanged();
    return (
      signature: signature,
      generation: generation,
      sqlCancelScope: sqlCancelScope,
    );
  }

  void _armRetryAfterFromFailures(AppFailure failure) {
    armAgentQueryRetryAfterGate(_host.retryAfterGate, failure);
  }

  void _armRetryAfterFromPartialFailures(Overview overview) {
    for (final detail in overview.partialQueryFailureDetails) {
      if (shouldArmRetryAfterFromPartialAgentQueryFailure(detail.failure)) {
        _armRetryAfterFromFailures(detail.failure);
      }
    }
  }

  void _applyOneShotSuccess({
    required Overview overview,
    required String signature,
    required String userId,
    required OverviewLoadPolicy policy,
  }) {
    _armRetryAfterFromPartialFailures(overview);
    _host
      ..setOverview(overview)
      ..completedOverviewSections = OverviewSectionRequest.home
          .completedWhenFinal();
    _host.session.loadedSignature = signature;
    _host.errorMessage = null;
    _host.errorDiagnosticBody = null;
    _host.loadFailure = null;
    _host.publishShellCache(signature);
    AppLogger.info(
      'Overview loaded in controller',
      context: <String, Object?>{
        'operation': 'loadOverview',
        'userId': userId,
        'paymentMethods': overview.paymentMethods.length,
        'policy': policy.name,
      },
    );
  }

  void _applyFailure(
    AppFailure failure, {
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewFailureMessageBuilder failureMessageBuilder,
  }) {
    if (!keepContentVisible) {
      _host.setOverview(null);
      _host.session.clearLoaded();
      _host.completedOverviewSections = const <OverviewProgressiveSection>{};
    }
    _armRetryAfterFromFailures(failure);
    final userMessage = failureMessageBuilder(failure);
    _host.errorMessage = userMessage;
    _host.loadFailure = failure;
    _host.errorDiagnosticBody = overviewAppFailureDiagnosticBody(
      failure,
      localizedUserMessage: userMessage,
    );
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

  Future<void> _loadOverviewProgressively({
    required String userId,
    required OverviewLoadPolicy policy,
    required bool keepContentVisible,
    required OverviewLoadLabels rowLabels,
    required OverviewFailureMessageBuilder failureMessageBuilder,
    required String signature,
    required int generation,
    required AgentQueriesCancelScope sqlCancelScope,
  }) async {
    await for (final result in _loadOverviewUseCase.progressively(
      userId: userId,
      policy: policy,
      filter: _host.activeFilter,
      rowLabels: rowLabels,
      cancelScope: sqlCancelScope,
      sectionRequest: OverviewSectionRequest.home,
    )) {
      if (_host.isOverviewLoadStale(generation)) {
        return;
      }

      final snapshot = result.getOrNull();
      if (snapshot != null) {
        _host
          ..setOverview(snapshot.overview)
          ..completedOverviewSections = snapshot.completedSections;
        _armRetryAfterFromPartialFailures(snapshot.overview);
        _host.errorMessage = null;
        _host.errorDiagnosticBody = null;
        _host.loadFailure = null;
        if (snapshot.completedSections.contains(
          OverviewProgressiveSection.summary,
        )) {
          _host.isLoadingInitial = false;
        }
        if (snapshot.isFinal) {
          _host.session.loadedSignature = signature;
          _host.publishShellCache(signature);
          AppLogger.info(
            'Overview loaded progressively in controller',
            context: <String, Object?>{
              'operation': 'loadOverview',
              'userId': userId,
              'paymentMethods': snapshot.overview.paymentMethods.length,
              'policy': policy.name,
            },
          );
          _finishProgressiveLoading(keepContentVisible: keepContentVisible);
          if (await _host.updateAvailableAgents(
            snapshot.overview,
            userId,
            generation,
          )) {
            _host.notifyOverviewChanged();
          }
          _host.scheduleSectionPrefetch(
            userId: userId,
            signature: signature,
            generation: generation,
            rowLabels: rowLabels,
          );
          return;
        }
        _host.notifyOverviewChanged();
        continue;
      }

      final failure = result.exceptionOrNull();
      if (failure != null) {
        _applyFailure(
          failure,
          userId: userId,
          policy: policy,
          keepContentVisible: keepContentVisible,
          failureMessageBuilder: failureMessageBuilder,
        );
      }
      _finishProgressiveLoading(keepContentVisible: keepContentVisible);
      return;
    }

    _finishProgressiveLoading(keepContentVisible: keepContentVisible);
  }

  void _finishProgressiveLoading({required bool keepContentVisible}) {
    if (keepContentVisible) {
      _host.isRefreshing = false;
    } else {
      _host.isLoadingInitial = false;
    }
    _host.notifyOverviewChanged();
  }
}

typedef OverviewFailureMessageBuilder = String Function(AppFailure failure);
