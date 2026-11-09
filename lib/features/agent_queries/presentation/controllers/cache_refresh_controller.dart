import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_report.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:flutter/foundation.dart';

class CacheRefreshController extends ChangeNotifier {
  CacheRefreshController(
    this.coordinator,
    this.reports,
    this._agents,
    this._user,
  ) {
    _subscription = coordinator.events.listen((_) => unawaited(load()));
  }
  final CacheRefreshCoordinator coordinator;
  final List<CacheRefreshReport> reports;
  final ClientApprovedAgentsRepository _agents;
  final String? Function() _user;
  late final StreamSubscription<void> _subscription;
  List<CacheRefreshRecord> records = [];
  List<ClientAgent> agents = [];
  String? error;
  bool busy = false;
  bool _disposed = false;
  int _loadGeneration = 0;
  String? get userId => _user();
  Future<void> load({bool catalog = false}) async {
    final user = _user();
    final generation = ++_loadGeneration;
    if (user == null) {
      records = [];
      agents = [];
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final next = await coordinator.repository.list(user);
      final options = <ClientAgent>[];
      if (catalog) {
        var page = 1;
        while (true) {
          final data = (await _agents.loadApprovedAgents(
            userId: user,
            query: PaginatedQuery(page: page, pageSize: 100),
            refresh: true,
          )).getOrThrow();
          options.addAll(data.items);
          if (data.items.isEmpty || page * data.pageSize >= data.total) break;
          page++;
        }
      }
      if (_disposed || _user() != user) return;
      if (catalog) agents = options;
      if (generation == _loadGeneration) records = next;
    } on Object catch (e) {
      if (!_disposed && _user() == user && generation == _loadGeneration) {
        error = e is AppFailure
            ? e.displayMessage
            : 'Não foi possível carregar os agendamentos.';
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<bool> save(CacheRefreshSchedule schedule) => _run(() async {
    if (_user() != schedule.userId) {
      throw const SessionFailure(message: 'session_changed');
    }
    reports
        .firstWhere((r) => r.id == schedule.reportId)
        .validate(schedule, DateTime.now());
    coordinator.cancel(schedule.id);
    final normalized = reports
        .firstWhere((r) => r.id == schedule.reportId)
        .normalizedFilters(schedule);
    await coordinator.repository.save(
      CacheRefreshSchedule(
        id: schedule.id,
        userId: schedule.userId,
        agentId: schedule.agentId,
        reportId: schedule.reportId,
        reportVersion: schedule.reportVersion,
        period: schedule.period,
        start: schedule.start,
        end: schedule.end,
        interval: schedule.interval,
        enabled: schedule.enabled,
        filters: normalized,
      ),
    );
    if (schedule.enabled) coordinator.requestNow(schedule.id);
  });
  Future<bool> remove(CacheRefreshRecord record) => _run(() async {
    if (_user() != record.schedule.userId) return;
    coordinator.cancel(record.schedule.id);
    await coordinator.repository.remove(
      record.schedule.userId,
      record.schedule.id,
    );
  });
  Future<bool> toggle(CacheRefreshRecord record) {
    final s = record.schedule;
    return save(
      CacheRefreshSchedule(
        id: s.id,
        userId: s.userId,
        agentId: s.agentId,
        reportId: s.reportId,
        period: s.period,
        start: s.start,
        end: s.end,
        interval: s.interval,
        enabled: !s.enabled,
        filters: s.filters,
      ),
    );
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    var success = false;
    try {
      await action();
      success = true;
    } on Object catch (e) {
      error = e is AppFailure
          ? e.displayMessage
          : 'Não foi possível salvar o agendamento.';
    } finally {
      busy = false;
      await load();
    }
    return success;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
