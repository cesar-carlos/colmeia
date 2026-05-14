import 'package:checks/checks.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/hybrid_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockBaseDatasource extends Mock
    implements AgentQueriesRemoteDataSource {}

class _MockRelayDispatcher extends Mock implements RelayCommandDispatcher {}

final class _LogEvent {
  const _LogEvent({
    required this.level,
    required this.message,
    required this.context,
  });

  final AppLogLevel level;
  final String message;
  final Map<String, Object?> context;
}

final class _RecordingLogSink implements AppLogSink {
  final events = <_LogEvent>[];

  @override
  void onLog({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      _LogEvent(
        level: level,
        message: message,
        context: Map<String, Object?>.of(context),
      ),
    );
  }
}

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

AgentSqlExecuteBatchRequest _batchRequest({
  bool useRelay = false,
}) {
  return AgentSqlExecuteBatchRequest(
    agentId: 'agent-1',
    commands: const <AgentSqlExecuteBatchCommand>[
      AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
    ],
    useRelay: useRelay,
  );
}

void main() {
  late Level previousLogLevel;

  setUpAll(() {
    registerFallbackValue(_request());
    registerFallbackValue(_batchRequest());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(RelayPayloadFrameCompression.auto);
  });

  setUp(() {
    previousLogLevel = AppLogger.minimumLevel;
    AppLogger.minimumLevel = Level.off;
  });

  tearDown(() {
    AppLogger.minimumLevel = previousLogLevel;
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

    test('routes batch useRelay=true through the relay dispatcher', () async {
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
      ).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as Map<dynamic, dynamic>;
        final command = body['command']! as Map<dynamic, dynamic>;
        return <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{
              'success': true,
              'method': command['method'],
            },
          },
        };
      });

      final hybrid = HybridAgentQueriesRemoteDataSource(
        baseDelegate: base,
        relayDelegate: relay,
      );

      await hybrid.postSqlExecuteBatch(_batchRequest(useRelay: true));

      verify(
        () => dispatcher.sendUnary(
          agentId: 'agent-1',
          body: any(named: 'body'),
          clientRequestId: any(named: 'clientRequestId'),
          timeout: any(named: 'timeout'),
          compression: any(named: 'compression'),
        ),
      ).called(1);
      verifyNever(() => base.postSqlExecuteBatch(any()));
    });

    test('emits route telemetry for base, relay and relay bypass', () async {
      final previousSink = AppLogger.sink;
      final previousLevel = AppLogger.minimumLevel;
      final sink = _RecordingLogSink();
      AppLogger.sink = sink;
      AppLogger.minimumLevel = Level.off;
      addTearDown(() {
        AppLogger.sink = previousSink;
        AppLogger.minimumLevel = previousLevel;
      });

      final base = _MockBaseDatasource();
      final dispatcher = _MockRelayDispatcher();
      final relay = RelayAgentQueriesRemoteDataSource(dispatcher: dispatcher);
      when(() => base.postSqlExecute(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{'success': true},
          },
        },
      );
      when(() => base.postSqlExecuteBatch(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{'success': true},
          },
        },
      );
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
      final missingRelayHybrid = HybridAgentQueriesRemoteDataSource(
        baseDelegate: base,
      );

      await hybrid.postSqlExecute(_request());
      await hybrid.postSqlExecute(_request(useRelay: true));
      await hybrid.postSqlExecuteBatch(_batchRequest(useRelay: true));
      await missingRelayHybrid.postSqlExecute(_request(useRelay: true));

      final routeContexts = sink.events
          .map((event) => event.context)
          .where((context) => context.containsKey('transportRoute'))
          .toList(growable: false);

      check(
        routeContexts.map((context) => context['transportMethod']),
      ).deepEquals(
        <Object?>[
          'sql.execute',
          'sql.execute',
          'sql.executeBatch',
          'sql.execute',
        ],
      );
      check(
        routeContexts.map((context) => context['transportRoute']),
      ).deepEquals(<Object?>['base', 'relay', 'relay', 'base']);
      check(
        routeContexts.map((context) => context['relayRequested']),
      ).deepEquals(<Object?>[false, true, true, true]);
      check(routeContexts.last['reason']).equals('relay_datasource_missing');
    });
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
