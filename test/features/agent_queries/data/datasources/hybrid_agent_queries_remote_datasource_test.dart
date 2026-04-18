import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/hybrid_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBaseDatasource extends Mock implements AgentQueriesRemoteDataSource {
}

class _MockRelayDispatcher extends Mock implements RelayCommandDispatcher {}

AgentSqlExecuteRequest _request({
  String agentId = 'agent-1',
  String sql = 'SELECT 1',
  bool useRelay = false,
}) {
  return AgentSqlExecuteRequest(
    agentId: agentId,
    sql: sql,
    useRelay: useRelay,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_request());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(RelayPayloadFrameCompression.auto);
  });

  group('HybridAgentQueriesRemoteDataSource', () {
    test('routes useRelay=false through the base datasource', () async {
      final base = _MockBaseDatasource();
      final dispatcher = _MockRelayDispatcher();
      final relay = RelayAgentQueriesRemoteDataSource(dispatcher: dispatcher);

      final captured = <Map<String, dynamic>>[];
      when(() => base.postSqlExecute(any())).thenAnswer((invocation) async {
        captured.add(<String, dynamic>{
          'kind': 'base',
          'agentId':
              (invocation.positionalArguments.first as AgentSqlExecuteRequest)
                  .trimmedAgentId,
        });
        return <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{'success': true},
          },
        };
      });

      final hybrid = HybridAgentQueriesRemoteDataSource(
        baseDelegate: base,
        relayDelegate: relay,
      );

      // Explicit `false` documents the route under test even though it
      // matches the entity default.
      // ignore: avoid_redundant_argument_values
      await hybrid.postSqlExecute(_request(useRelay: false));

      verify(() => base.postSqlExecute(any())).called(1);
      verifyNever(
        () => dispatcher.sendUnary(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      );
      check(captured.single['kind']).equals('base');
    });

    test('routes useRelay=true through the relay dispatcher', () async {
      final base = _MockBaseDatasource();
      final dispatcher = _MockRelayDispatcher();
      final relay = RelayAgentQueriesRemoteDataSource(dispatcher: dispatcher);

      when(
        () => dispatcher.sendUnary(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{'success': true},
          },
        },
      );

      final hybrid = HybridAgentQueriesRemoteDataSource(
        baseDelegate: base,
        relayDelegate: relay,
      );

      await hybrid.postSqlExecute(_request(useRelay: true));

      verify(
        () => dispatcher.sendUnary(
          agentId: 'agent-1',
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).called(1);
      verifyNever(() => base.postSqlExecute(any()));
    });

    test(
      'falls back to base when useRelay=true but relay datasource is missing',
      () async {
        final base = _MockBaseDatasource();
        when(() => base.postSqlExecute(any())).thenAnswer(
          (_) async => <String, dynamic>{
            'response': <String, dynamic>{
              'type': 'single',
              'item': <String, dynamic>{'success': true, 'fallback': true},
            },
          },
        );

        final hybrid = HybridAgentQueriesRemoteDataSource(baseDelegate: base);

        await hybrid.postSqlExecute(_request(useRelay: true));

        verify(() => base.postSqlExecute(any())).called(1);
      },
    );
  });

  group('AgentSqlExecuteRequest.useRelay', () {
    test('defaults to false to keep existing call sites unchanged', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
      );
      check(request.useRelay).isFalse();
    });

    test('explicit true is preserved on the entity', () {
      const request = AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        useRelay: true,
      );
      check(request.useRelay).isTrue();
    });
  });
}
