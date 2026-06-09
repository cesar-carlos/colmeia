import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_synchronizer.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClientAgentsLocalDataSource extends Mock
    implements ClientAgentsLocalDataSource {}

class _MockClientAgentsRemoteDataSource extends Mock
    implements ClientAgentsRemoteDataSource {}

void main() {
  late _MockClientAgentsLocalDataSource local;
  late _MockClientAgentsRemoteDataSource remote;
  late PendingClientAgentActionsSynchronizer synchronizer;
  final now = DateTime.utc(2026, 6, 9, 12);

  setUpAll(() {
    registerFallbackValue(<PendingAgentAction>[]);
    registerFallbackValue(
      const ClientRequestAccessResponseDto(requested: <String>['fb']),
    );
  });

  setUp(() {
    local = _MockClientAgentsLocalDataSource();
    remote = _MockClientAgentsRemoteDataSource();
    synchronizer = PendingClientAgentActionsSynchronizer(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  test('returns empty result when no queued actions exist', () async {
    when(
      () => local.readPendingActions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const <PendingAgentAction>[]);

    final result = await synchronizer.synchronize(userId: 'user-1');

    expect(result.successfulActionCount, 0);
    expect(result.failedActionCount, 0);
    verifyNever(
      () => remote.requestAccess(agentIds: any(named: 'agentIds')),
    );
  });

  test(
    'propagates retryAfter when request-access batch fails with rate limit',
    () async {
      var storedActions = <PendingAgentAction>[
        PendingAgentAction(
          id: 'requestAccess_agent-1',
          agentId: 'agent-1',
          type: PendingAgentActionType.requestAccess,
          state: PendingAgentActionState.queued,
          createdAt: now,
          attemptCount: 0,
        ),
      ];

      when(
        () => local.readPendingActions(userId: any(named: 'userId')),
      ).thenAnswer((_) async => storedActions);
      when(
        () => local.savePendingActions(
          userId: any(named: 'userId'),
          actions: any(named: 'actions'),
        ),
      ).thenAnswer((invocation) async {
        storedActions = List<PendingAgentAction>.from(
          invocation.namedArguments[#actions]! as List<PendingAgentAction>,
        );
      });
      when(
        () => remote.requestAccess(agentIds: any(named: 'agentIds')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/client/me/agents'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/client/me/agents'),
            statusCode: 429,
            headers: Headers.fromMap(<String, List<String>>{
              'retry-after': <String>['12'],
            }),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await synchronizer.synchronize(userId: 'user-1');

      check(result.failedActionCount).equals(1);
      check(result.retryAfter).isNotNull();
      check(result.retryAfter!.inSeconds).equals(12);
      check(storedActions.single.state).equals(PendingAgentActionState.failed);
    },
  );
}
