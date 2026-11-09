import 'dart:async';
import 'dart:math';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';

class CacheRefreshCoordinator {
  CacheRefreshCoordinator({
    required this.repository,
    required this.executor,
    required this.presence,
    required this.lock,
    required this.online,
    DateTime Function()? clock,
    double Function()? random,
    Timer Function(Duration, void Function(Timer))? periodicTimer,
    this.onRevoked,
    this.onSessionRejected,
    this.onWorkStarted,
    this.onWorkFinished,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random().nextDouble,
       _periodicTimer = periodicTimer ?? Timer.periodic;
  final CacheRefreshScheduleRepository repository;
  final ScheduledReportRefreshExecutor executor;
  final CacheRefreshPresence presence;
  final CacheRefreshLock lock;
  final bool Function() online;
  final Future<void> Function(String user, String agent)? onRevoked;
  final void Function()? onSessionRejected;
  final void Function()? onWorkStarted;
  final void Function()? onWorkFinished;
  final DateTime Function() _clock;
  final double Function() _random;
  final Timer Function(Duration, void Function(Timer)) _periodicTimer;
  final _events = StreamController<void>.broadcast();
  Stream<void> get events => _events.stream;
  final _running = <String, ({String id, AgentQueriesCancelScope scope})>{};
  final _attempts = <String, DateTime>{};
  final _unpersistedStates = <String, CacheRefreshState>{};
  CacheRefreshState? unpersistedState(String id) => _unpersistedStates[id];
  final _manual = <String>{};
  final _recovered = <String>{};
  final _presenceTimes = <String, DateTime>{};
  Timer? _timer;
  String? _user;
  int _epoch = 0;
  bool _pumping = false;
  bool _disposed = false;
  DateTime? _networkRetry;
  String? _lastAgent;
  Set<String> get runningIds => _running.values.map((v) => v.id).toSet();
  String? get userId => _user;

  void start(String user) {
    if (_disposed || user == _user) return;
    stop();
    _user = user;
    _timer = _periodicTimer(
      const Duration(seconds: 30),
      (_) => unawaited(tick()),
    );
    unawaited(tick());
  }

  void stop() {
    _epoch++;
    _user = null;
    _timer?.cancel();
    _timer = null;
    for (final entry in _running.values) {
      entry.scope.cancelAll();
    }
    _running.clear();
    _attempts.clear();
    _unpersistedStates.clear();
    _manual.clear();
    _recovered.clear();
    _presenceTimes.clear();
    _networkRetry = null;
    _emit();
  }

  Future<void> logout() async {
    final user = _user;
    stop();
    if (user != null) await repository.clearUser(user);
    _emit();
  }

  void cancel(String id) {
    _unpersistedStates.remove(id);
    for (final entry in _running.values.where((e) => e.id == id)) {
      entry.scope.cancelAll();
    }
    _manual.remove(id);
  }

  void requestNow(String id) {
    if (runningIds.contains(id)) return;
    _manual.add(id);
    unawaited(tick());
  }

  void resume() {
    _networkRetry = null;
    unawaited(tick());
  }

  void presenceChanged(String agent, DateTime observedAt) {
    final previous = _presenceTimes[agent];
    if (previous != null && !observedAt.isAfter(previous)) return;
    _presenceTimes[agent] = observedAt;
    _recovered.add(agent);
    unawaited(tick());
  }

  void _emit() {
    if (!_disposed) _events.add(null);
  }

  bool _current(String user, int epoch, AgentQueriesCancelScope scope) =>
      _user == user && _epoch == epoch && !scope.isCancelled;

  Future<void> tick() async {
    final user = _user;
    if (_pumping || _disposed || user == null) return;
    _pumping = true;
    try {
      final records = await repository.list(user);
      if (_user != user) return;
      final now = _clock().toUtc();
      final eligible =
          records.where((r) {
            final s = r.schedule;
            if (!s.enabled ||
                _running.containsKey(s.agentId) ||
                r.state.status == CacheRefreshStatus.accessUnavailable ||
                r.state.status == CacheRefreshStatus.paused) {
              return false;
            }
            if (_attempts[s.id]?.isAfter(now) ?? false) return false;
            return _manual.contains(s.id) ||
                (_recovered.contains(s.agentId) &&
                    r.state.status == CacheRefreshStatus.waitingAgent) ||
                r.state.nextAttempt == null ||
                !r.state.nextAttempt!.isAfter(now);
          }).toList()..sort((a, b) {
            if (a.schedule.agentId == _lastAgent &&
                b.schedule.agentId != _lastAgent) {
              return 1;
            }
            if (b.schedule.agentId == _lastAgent &&
                a.schedule.agentId != _lastAgent) {
              return -1;
            }
            return (a.state.nextAttempt ??
                    DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  b.state.nextAttempt ?? DateTime.fromMillisecondsSinceEpoch(0),
                );
          });
      for (final record in eligible) {
        if (_running.length >= 2) break;
        final schedule = record.schedule;
        if (_running.containsKey(schedule.agentId)) continue;
        if (!online() || (_networkRetry?.isAfter(now) ?? false)) {
          await repository.commit(
            record,
            CacheRefreshState(
              status: CacheRefreshStatus.waitingConnection,
              lastSuccess: record.state.lastSuccess,
              nextAttempt:
                  _networkRetry ?? now.add(const Duration(seconds: 30)),
              failures: record.state.failures,
            ),
          );
          continue;
        }
        final scope = AgentQueriesCancelScope();
        _running[schedule.agentId] = (id: schedule.id, scope: scope);
        final epoch = _epoch;
        final manual = _manual.remove(schedule.id);
        final recovered = _recovered.remove(schedule.agentId);
        unawaited(
          _run(record, scope, epoch, manual: manual, recovered: recovered),
        );
      }
      _emit();
    } on Object catch (error, stack) {
      AppLogger.warning(
        'cache.refresh.dispatch_failed',
        error: error,
        stackTrace: stack,
      );
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(
    CacheRefreshRecord candidate,
    AgentQueriesCancelScope scope,
    int epoch, {
    required bool manual,
    required bool recovered,
  }) async {
    final schedule = candidate.schedule;
    _unpersistedStates.remove(schedule.id);
    final started = Stopwatch()..start();
    var published = false;
    var workStarted = false;
    try {
      onWorkStarted?.call();
      workStarted = true;
      await lock.run('agent-${schedule.userId}-${schedule.agentId}', () async {
        final acquired = await _withCapacity(schedule.userId, () async {
          if (!_current(schedule.userId, epoch, scope)) return;
          final current = await repository.read(
            schedule.userId,
            schedule.id,
            includeSnapshot: false,
          );
          if (current == null ||
              current.revision != candidate.revision ||
              !current.schedule.enabled) {
            return;
          }
          final now = _clock().toUtc();
          if (!manual &&
              !recovered &&
              (current.state.nextAttempt?.isAfter(now) ?? false)) {
            return;
          }
          try {
            final available = await presence.reconcile(
              schedule.userId,
              schedule.agentId,
            );
            if (!_current(schedule.userId, epoch, scope)) return;
            if (available == RefreshAgentAvailability.denied) {
              throw const AuthorizationFailure(message: 'agent_access_revoked');
            }
            if (available != RefreshAgentAvailability.online) {
              final failures = current.state.failures + 1;
              final seconds = min(
                900,
                30 * pow(2, min(failures - 1, 5)),
              ).toInt();
              final delay = Duration(
                milliseconds: (seconds * 1000 * (0.8 + _random() * 0.4))
                    .round(),
              );
              await repository.commit(
                current,
                CacheRefreshState(
                  status: CacheRefreshStatus.waitingAgent,
                  lastSuccess: current.state.lastSuccess,
                  nextAttempt: now.add(delay),
                  failures: failures,
                  reason: 'agent_unavailable',
                ),
              );
              AppLogger.info(
                'cache.refresh.deferred',
                context: {
                  'reason': 'agent_unavailable',
                  'report': schedule.reportId,
                },
              );
              return;
            }
            schedule.validate(_clock());
            final period = schedule.resolvePeriod(_clock());
            final data = await executor.execute(schedule, period, scope);
            if (!_current(schedule.userId, epoch, scope)) return;
            final confirmed = await presence.reconcile(
              schedule.userId,
              schedule.agentId,
            );
            if (confirmed == RefreshAgentAvailability.denied) {
              throw const AuthorizationFailure(message: 'agent_access_revoked');
            }
            if (confirmed != RefreshAgentAvailability.online) {
              throw const NetworkFailure(
                message: 'agent_confirmation_unavailable',
              );
            }
            if (!_current(schedule.userId, epoch, scope)) return;
            final collected = _clock().toUtc();
            published = await repository.commit(
              current,
              CacheRefreshState(
                lastSuccess: collected,
                durationMs: started.elapsedMilliseconds,
                nextAttempt: collected.add(schedule.interval),
              ),
              snapshot: {
                'formatVersion': schedule.reportVersion,
                'agentId': schedule.agentId,
                'userId': schedule.userId,
                'reportId': schedule.reportId,
                'filters': schedule.filters,
                'periodStart': period.start.toIso8601String(),
                'periodEnd': period.end.toIso8601String(),
                'collectedAt': collected.toIso8601String(),
                'complete': true,
                'currentDayPartial': !period.end.isBefore(
                  DateTime(_clock().year, _clock().month, _clock().day),
                ),
                'data': data,
              },
            );
          } on Object catch (error, stack) {
            if (!_current(schedule.userId, epoch, scope)) return;
            final failure = error is AppFailure
                ? error
                : mapToAppFailure(error, stackTrace: stack);
            if (failure is SessionFailure) {
              stop();
              await repository.clearUser(schedule.userId);
              onSessionRejected?.call();
              return;
            }
            final denied =
                failure is AuthorizationFailure || failure is SessionFailure;
            final invalid = failure is ValidationFailure;
            final count = current.state.failures + 1;
            final seconds = min(900, 30 * pow(2, min(count - 1, 5))).toInt();
            var delay = Duration(
              milliseconds: (seconds * 1000 * (0.8 + _random() * 0.4)).round(),
            );
            final retryAfter = failure is NetworkFailure
                ? failure.retryAfter
                : failure is RpcFailure
                ? failure.retryAfter
                : null;
            if (retryAfter != null && retryAfter > delay) delay = retryAfter;
            final retry = _clock().toUtc().add(delay);
            _attempts[schedule.id] = retry;
            // Query timeouts are local to this job; transport outages are global.
            if (failure is NetworkFailure &&
                failure.context['refreshHubUnavailable'] == true) {
              _networkRetry = retry;
            }
            final offline =
                failure is RpcFailure &&
                (failure.reason == 'agent_disconnected_at_dispatch' ||
                    failure.reason == 'agent_offline');
            await repository.commit(
              current,
              CacheRefreshState(
                status: denied
                    ? CacheRefreshStatus.accessUnavailable
                    : invalid
                    ? CacheRefreshStatus.paused
                    : offline
                    ? CacheRefreshStatus.waitingAgent
                    : CacheRefreshStatus.deferred,
                lastSuccess: current.state.lastSuccess,
                nextAttempt: retry,
                failures: count,
                durationMs: started.elapsedMilliseconds,
                reason: denied
                    ? 'access_denied'
                    : invalid
                    ? 'invalid_filters'
                    : failure is StorageFailure
                    ? 'storage_unavailable'
                    : 'refresh_failed',
              ),
              discardSnapshot: denied,
            );
            if (denied) {
              for (final other in await repository.list(schedule.userId)) {
                if (other.schedule.agentId == schedule.agentId) {
                  await repository.commit(
                    other,
                    CacheRefreshState(
                      status: CacheRefreshStatus.accessUnavailable,
                      lastSuccess: other.state.lastSuccess,
                      reason: 'access_denied',
                    ),
                    discardSnapshot: true,
                  );
                }
              }
              await onRevoked?.call(schedule.userId, schedule.agentId);
            }
            AppLogger.warning(
              'cache.refresh.failed',
              context: {
                'report': schedule.reportId,
                'failureType': failure.runtimeType.toString(),
              },
            );
          }
        });
        if (!acquired && _current(schedule.userId, epoch, scope)) {
          final retry = _clock().toUtc().add(const Duration(seconds: 5));
          _attempts[schedule.id] = retry;
          await repository.commit(
            candidate,
            CacheRefreshState(
              status: CacheRefreshStatus.deferred,
              lastSuccess: candidate.state.lastSuccess,
              durationMs: candidate.state.durationMs,
              failures: candidate.state.failures,
              nextAttempt: retry,
              reason: 'capacity_busy',
            ),
          );
        }
      });
    } on Object catch (error, stack) {
      if (_current(schedule.userId, epoch, scope)) {
        _attempts[schedule.id] = _clock().toUtc().add(
          const Duration(minutes: 1),
        );
        _unpersistedStates[schedule.id] = CacheRefreshState(
          status: CacheRefreshStatus.deferred,
          lastSuccess: candidate.state.lastSuccess,
          nextAttempt: _attempts[schedule.id],
          durationMs: started.elapsedMilliseconds,
          reason: error is StorageFailure
              ? 'storage_unavailable'
              : 'refresh_failed',
        );
      }
      AppLogger.warning(
        'cache.refresh.storage_or_lock_failed',
        error: error,
        stackTrace: stack,
      );
    } finally {
      if (workStarted) onWorkFinished?.call();
      if (identical(_running[schedule.agentId]?.scope, scope)) {
        _running.remove(schedule.agentId);
      }
      _lastAgent = schedule.agentId;
      AppLogger.info(
        'cache.refresh.finished',
        context: {
          'report': schedule.reportId,
          'published': published,
          'durationMs': started.elapsedMilliseconds,
        },
      );
      _emit();
      if (!_disposed) unawaited(tick());
    }
  }

  Future<bool> _withCapacity(
    String user,
    Future<void> Function() action,
  ) async {
    for (var slot = 0; slot < 2; slot++) {
      if (await lock.runIfAvailable(
        'capacity-${Uri.encodeComponent(user)}-$slot',
        action,
      )) {
        return true;
      }
    }
    return false;
  }

  Future<void> dispose() async {
    stop();
    _disposed = true;
    await _events.close();
  }
}
