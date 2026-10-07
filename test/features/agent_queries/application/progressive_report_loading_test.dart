import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/progressive_report_loading.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/progressive_report_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

class _Progressive implements ProgressiveReportRepository<int, int> {
  AgentQueryLoadPolicy? policy;
  AgentQueriesCancelScope? scope;

  @override
  Stream<AppResult<AgentQueryProgress<int>>> loadProgressively({
    required String userId,
    required String agentId,
    required int filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async* {
    policy = cachePolicy;
    scope = cancelScope;
    yield Success(
      AgentQueryProgress(
        rows: [filter],
        isComplete: false,
        receivedRowCount: 1,
      ),
    );
    yield Success(
      AgentQueryProgress(
        rows: [filter, 2],
        isComplete: true,
        receivedRowCount: 2,
      ),
    );
  }
}

void main() {
  setUp(
    () => dotenv.loadFromString(envString: 'AGENT_QUERY_PROGRESSIVE_REPORTS='),
  );
  tearDown(
    () => dotenv.loadFromString(envString: 'AGENT_QUERY_PROGRESSIVE_REPORTS='),
  );

  test(
    'progressive activation is empty by default and scoped by report id',
    () {
      expect(AppEnvironment.progressiveReportIds, isEmpty);
      dotenv.loadFromString(
        envString: 'AGENT_QUERY_PROGRESSIVE_REPORTS=first, second, first',
      );
      expect(AppEnvironment.progressiveReportIds, {'first', 'second'});
    },
  );

  test(
    'disabled report loads lazily and cancels abandoned complete work',
    () async {
      final pending = Completer<AppResult<List<int>>>();
      final parent = AgentQueriesCancelScope();
      AgentQueriesCancelScope? owned;
      var calls = 0;
      final stream = ProgressiveReportLoading.watch<int, int>(
        reportId: 'disabled',
        repository: Object(),
        userId: 'u',
        agentId: 'a',
        filter: 1,
        cancelScope: parent,
        loadComplete: (scope) {
          calls++;
          owned = scope;
          return pending.future;
        },
      );
      expect(calls, 0);
      final subscription = stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      await subscription.cancel();
      expect(owned!.isCancelled, true);
      expect(parent.isCancelled, false);
      pending.complete(const Success([1]));
    },
  );

  test(
    'enabled port preserves scope and cache policy without a duplicate load',
    () async {
      dotenv.loadFromString(
        envString: 'AGENT_QUERY_PROGRESSIVE_REPORTS=enabled',
      );
      final repository = _Progressive();
      final parent = AgentQueriesCancelScope();
      final events = await ProgressiveReportLoading.watch<int, int>(
        reportId: 'enabled',
        repository: repository,
        userId: 'u',
        agentId: 'a',
        filter: 1,
        cancelScope: parent,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
        loadComplete: (_) => throw StateError('duplicate full query'),
      ).toList();
      expect(events.map((event) => event.getOrThrow().isComplete), [
        false,
        true,
      ]);
      expect(repository.policy, AgentQueryLoadPolicy.forceRefresh);
      expect(repository.scope, same(parent));
    },
  );

  test('disabled successful stream has only a complete snapshot', () async {
    final parent = AgentQueriesCancelScope();
    AgentQueriesCancelScope? owned;
    final events = await ProgressiveReportLoading.watch<int, int>(
      reportId: 'disabled',
      repository: _Progressive(),
      userId: 'u',
      agentId: 'a',
      filter: 1,
      cancelScope: parent,
      loadComplete: (scope) async {
        owned = scope;
        return const Success([1, 2]);
      },
    ).toList();
    expect(events.single.getOrThrow().isComplete, true);
    expect(events.single.getOrThrow().rows, [1, 2]);
    expect(owned!.isCancelled, false);
  });
}
