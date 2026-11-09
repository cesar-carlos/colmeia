import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_request_key.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_query_snapshots.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_report_refresh_executor.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_report.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class Queries extends Mock implements AgentQueriesRepository {}

class Store extends Mock implements CacheRefreshScheduleRepository {}

class Presence extends Mock implements CacheRefreshPresence {}

void main() {
  const request = AgentSqlExecuteRequest(
    agentId: 'agent',
    requestingUserId: 'user',
    sql: 'SELECT value FROM report',
  );
  const response = AgentSqlExecutionResult(
    rows: [
      {'value': 12},
    ],
    rowCount: 1,
  );
  setUpAll(() {
    registerFallbackValue(request);
  });
  late Queries queries;
  late Store store;
  late Presence presence;
  late ScheduledQuerySnapshots repository;
  late CacheRefreshSchedule schedule;
  setUp(() {
    queries = Queries();
    store = Store();
    presence = Presence();
    repository = ScheduledQuerySnapshots(queries, store, presence, () => true);
    schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'report',
    );
    when(() => store.list(any())).thenAnswer((_) async => []);
    when(
      () => queries.executeSql(any(), cancelScope: any(named: 'cancelScope')),
    ).thenAnswer((_) async => const Success(response));
    when(() => presence.reconcile('user', 'agent'))
        .thenAnswer((_) async => RefreshAgentAvailability.online);
  });
  test(
    'capture forces transport refresh and propagates cancellation',
    () async {
      final scope = AgentQueriesCancelScope();
      final capture = ScheduledQueryCapture(cancelScope: scope);
      await capture.run(() => repository.executeSql(request));
      final call =
          verify(() => queries.executeSql(captureAny(), cancelScope: scope))
                  .captured
                  .single
              as AgentSqlExecuteRequest;
      expect(call.skipTransportCache, isTrue);
      expect(capture.queries, hasLength(1));
      expect(capture.queries.toString(), isNot(contains('SELECT')));
    },
  );
  test('inconsistent row counts reject complete publication', () async {
    when(
      () => queries.executeSql(any(), cancelScope: any(named: 'cancelScope')),
    ).thenAnswer(
      (_) async =>
          const Success(AgentSqlExecutionResult(rows: [], rowCount: 10)),
    );
    final executor = RegisteredReportRefreshExecutor(
      [const CacheRefreshReport('report', 'Report')],
      {
        'report': (s, p, c) async {
          (await repository.executeSql(request)).getOrThrow();
        },
      },
    );
    await expectLater(
      executor.execute(
        schedule,
        schedule.resolvePeriod(DateTime.now()),
        AgentQueriesCancelScope(),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });
  test('hitting the row limit is conservatively incomplete', () async {
    final capture = ScheduledQueryCapture();
    await capture.run(
      () => repository.executeSql(
        const AgentSqlExecuteRequest(
          agentId: 'agent',
          sql: 'SELECT value FROM report',
          executeOptions: AgentSqlExecuteOptions(maxRows: 1),
        ),
      ),
    );
    expect(capture.incomplete, isTrue);
  });
  Future<void> seed() async {
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final record = CacheRefreshRecord(
      schedule: schedule,
      revision: 'revision',
      state: CacheRefreshState(lastSuccess: now.toUtc()),
      snapshot: {
        'complete': true,
        'periodStart': period.start.toIso8601String(),
        'periodEnd': period.end.toIso8601String(),
        'data': {
          'queries': {
            AgentQueriesRequestKey.build(request): {
              'kind': 'sql',
              'rows': response.rows,
              'rowCount': 1,
            },
          },
        },
      },
    );
    when(() => store.list('user')).thenAnswer((_) async => [record]);
    when(() => store.read('user', 'job', includeSnapshot: false))
        .thenAnswer((_) async => record);
  }

  test(
    'compatible snapshots avoid SQL after permission revalidation',
    () async {
      await seed();
      expect(
        (await repository.executeSql(request)).getOrThrow().rows,
        response.rows,
      );
      verifyNever(
        () => queries.executeSql(any(), cancelScope: any(named: 'cancelScope')),
      );
      verify(() => presence.reconcile('user', 'agent')).called(1);
    },
  );
  test('manual refresh bypasses snapshots', () async {
    await seed();
    await repository.executeSql(request.copyWith(skipTransportCache: true));
    verify(
      () => queries.executeSql(any(), cancelScope: any(named: 'cancelScope')),
    ).called(1);
  });
  test('logout during validation prevents a snapshot read', () async {
    await seed();
    when(() => store.read('user', 'job', includeSnapshot: false))
        .thenAnswer((_) async => null);
    await repository.executeSql(request);
    verify(
      () => queries.executeSql(any(), cancelScope: any(named: 'cancelScope')),
    ).called(1);
  });
  test('a different user cannot reuse another user snapshot', () async {
    await seed();
    await repository.executeSql(request.copyWith(requestingUserId: 'other'));
    verify(
      () => queries.executeSql(any(), cancelScope: any(named: 'cancelScope')),
    ).called(1);
  });
}
