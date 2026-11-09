import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_cache_store_factory.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/cache_refresh_lock.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/local_cache_refresh_schedule_repository.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_report.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:colmeia/features/agent_queries/presentation/controllers/cache_refresh_controller.dart';
import 'package:colmeia/features/agent_queries/presentation/pages/cache_refresh_page.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

@JS('cacheRefreshSmoke')
external set _smoke(JSFunction value);

class _Presence implements CacheRefreshPresence {
  final offline = <String>{};
  @override
  Future<RefreshAgentAvailability> reconcile(String user, String agent) async =>
      offline.contains(agent)
      ? RefreshAgentAvailability.offline
      : RefreshAgentAvailability.online;
}

class _Executor implements ScheduledReportRefreshExecutor {
  _Executor(this.cache);
  final AppCacheStore cache;
  @override
  Future<Map<String, dynamic>> execute(
    CacheRefreshSchedule schedule,
    ({DateTime start, DateTime end}) period,
    AgentQueriesCancelScope scope,
  ) async {
    final key = 'smoke-count-${schedule.agentId}';
    final count = int.parse(await cache.getString(key) ?? '0');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!scope.isCancelled) {
      await cache.putString(key: key, value: '${count + 1}');
    }
    return {'count': count + 1};
  }
}

class _UnusedCatalog implements ClientApprovedAgentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Smoke uses persisted agents only');
}

/// Browser integration harness: real storage, coordinator, locks and page.
/// Agent queries are deterministic; this does not replace live repository E2E.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final cache = await createAppCacheStore();
  final lock = createCacheRefreshLock();
  final store = LocalCacheRefreshScheduleRepository(cache, lock);
  final presence = _Presence();
  var now = DateTime.now();
  final coordinator = CacheRefreshCoordinator(
    repository: store,
    executor: _Executor(cache),
    presence: presence,
    lock: lock,
    online: () => true,
    clock: () => now,
  );
  final controller = CacheRefreshController(
    coordinator,
    [const CacheRefreshReport('report', 'Vendas por loja')],
    _UnusedCatalog(),
    () => 'smoke',
  );
  _smoke = ((JSString encoded) {
    Future<JSString> execute() async {
      final input = jsonDecode(encoded.toDart) as Map<String, dynamic>;
      Object? result;
      switch (input['operation']) {
        case 'seed':
          for (final agent in ['A', 'B']) {
            await store.save(
              CacheRefreshSchedule(
                id: agent,
                userId: 'smoke',
                agentId: agent,
                reportId: 'report',
              ),
            );
          }
          await controller.load();
        case 'start':
          coordinator.start('smoke');
        case 'offline':
          presence.offline.add(input['agent'] as String);
        case 'recover':
          presence.offline.remove(input['agent']);
          coordinator.presenceChanged(input['agent'] as String, now.toUtc());
        case 'advance':
          now = now.add(const Duration(days: 1));
          coordinator.resume();
        case 'advanceSeconds':
          now = now.add(const Duration(seconds: 6));
          coordinator.resume();
        case 'state':
          result = {
            'records': (await store.list('smoke'))
                .map((r) => r.toJson())
                .toList(),
            'A': await cache.getString('smoke-count-A'),
            'B': await cache.getString('smoke-count-B'),
            'running': coordinator.runningIds.toList(),
          };
        case 'logout':
          await coordinator.logout();
      }
      return jsonEncode({'value': result}).toJS;
    }

    return execute().toJS;
  }).toJS;
  await controller.load();
  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const CacheRefreshPage(),
      ),
    ),
  );
}
