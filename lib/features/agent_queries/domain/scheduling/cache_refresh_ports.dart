import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';

// Platform-specific lock port, injected into persistence and coordination.
abstract interface class CacheRefreshLock {
  Future<T> run<T>(String name, Future<T> Function() action);
  Future<bool> runIfAvailable(String name, Future<void> Function() action);
}

abstract interface class CacheRefreshScheduleRepository {
  Future<List<CacheRefreshRecord>> list(String user);
  Future<CacheRefreshRecord?> read(
    String user,
    String id, {
    bool includeSnapshot = true,
  });
  Future<void> save(CacheRefreshSchedule schedule);
  Future<bool> commit(
    CacheRefreshRecord previous,
    CacheRefreshState state, {
    Map<String, dynamic>? snapshot,
    bool discardSnapshot = false,
  });
  Future<void> remove(String user, String id);
  Future<void> clearUser(String user);
}

enum RefreshAgentAvailability { online, offline, unknown, denied }

// Authorization-aware presence port, independent of transport.
// ignore: one_member_abstracts
abstract interface class CacheRefreshPresence {
  Future<RefreshAgentAvailability> reconcile(String user, String agent);
}

// Report dispatch port, replaced by a deterministic executor in tests.
// ignore: one_member_abstracts
abstract interface class ScheduledReportRefreshExecutor {
  Future<Map<String, dynamic>> execute(
    CacheRefreshSchedule schedule,
    ({DateTime start, DateTime end}) period,
    AgentQueriesCancelScope cancelScope,
  );
}
