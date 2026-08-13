import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/agent_sql_open_stream.dart';
import 'package:colmeia/core/socket/relay/relay_batch_item.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _RecordingAgentCommandSender implements AgentCommandSender {
  int calls = 0;

  @override
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    calls++;
    return <String, dynamic>{
      'response': <String, dynamic>{
        'success': true,
        'type': 'single',
        'item': <String, dynamic>{
          'success': true,
          'result': <String, dynamic>{
            'rows': <Map<String, Object?>>[
              <String, Object?>{'value': 1},
            ],
            'row_count': 1,
          },
        },
      },
    };
  }
}

class _ThrowingAgentCommandSender implements AgentCommandSender {
  int calls = 0;

  @override
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    calls++;
    throw StateError('base socket sender should not be used for relay request');
  }
}

class _FakeRelayCommandDispatcher implements RelayCommandDispatcher {
  _FakeRelayCommandDispatcher({this.unaryError});

  final Exception? unaryError;
  int unaryCalls = 0;
  int streamingCalls = 0;

  @override
  Stream<RelayRpcOutcome> outcomes() => const Stream<RelayRpcOutcome>.empty();

  @override
  Future<void> dispose() async {}

  @override
  void cancel(String clientRequestId, {String reason = 'caller_cancelled'}) {}

  @override
  List<AgentSqlOpenStream> cancelAllPending({
    String reason = 'caller_cancelled',
  }) => const <AgentSqlOpenStream>[];

  @override
  Future<Map<String, dynamic>> sendUnary({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    unaryCalls++;
    final error = unaryError;
    if (error != null) {
      throw error;
    }
    return <String, dynamic>{
      'jsonrpc': '2.0',
      'id': clientRequestId,
      'result': <String, dynamic>{
        'rows': <Map<String, Object?>>[
          <String, Object?>{'value': 1},
        ],
        'row_count': 1,
        'affected_rows': 0,
        'execution_id': 'exec-unary-1',
      },
    };
  }

  @override
  Future<List<Map<String, dynamic>>> sendBatch({
    required String agentId,
    required List<RelayBatchItem> items,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) async {
    // Tests in this file exercise the relay datasource via `sendUnary`
    // only; batch is not expected to fire here. If it ever does, fail
    // loudly so we can audit the call site.
    throw StateError('fake relay dispatcher does not implement sendBatch');
  }

  @override
  Stream<Map<String, dynamic>> sendStreaming({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    int? initialWindowSize,
    int? refillThreshold,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) {
    streamingCalls++;
    return Stream<Map<String, dynamic>>.fromIterable(<Map<String, dynamic>>[
      <String, dynamic>{
        'request_id': clientRequestId,
        'rows': <Map<String, Object?>>[
          <String, Object?>{'value': 1},
        ],
      },
      <String, dynamic>{
        'request_id': clientRequestId,
        'total_rows': 1,
        'affected_rows': 0,
        'execution_id': 'exec-1',
      },
    ]);
  }
}

class _RestAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{'response': 'ok-from-rest'}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString: '''
API_BASE_URL=http://localhost
USE_FAKE_BACKEND=false
AGENT_BRIDGE_TRANSPORT=socket
''',
    );
  });

  tearDown(() {
    dotenv.loadFromString(
      envString: '''
API_BASE_URL=http://localhost
USE_FAKE_BACKEND=false
AGENT_BRIDGE_TRANSPORT=rest
''',
    );
  });

  test(
    'socket transport routes useRelay=false through agents:command base '
    'when relay is registered',
    () async {
      final getIt = GetIt.asNewInstance();
      final sender = _RecordingAgentCommandSender();
      final relay = _FakeRelayCommandDispatcher();
      getIt
        ..registerLazySingleton<Dio>(Dio.new)
        ..registerLazySingleton<AgentCommandSender>(() => sender)
        ..registerLazySingleton<RelayCommandDispatcher>(() => relay);

      registerInjectorAgentQueries(getIt);

      final datasource = getIt<AgentQueriesRemoteDataSource>();
      await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
        ),
      );

      check(sender.calls).equals(1);
      check(relay.unaryCalls).equals(0);
      check(relay.streamingCalls).equals(0);

      await getIt.reset();
    },
  );

  test(
    'registers useRelay requests through the unary relay path by default',
    () async {
      final getIt = GetIt.asNewInstance();
      final sender = _ThrowingAgentCommandSender();
      final relay = _FakeRelayCommandDispatcher();
      getIt
        ..registerLazySingleton<Dio>(Dio.new)
        ..registerLazySingleton<AgentCommandSender>(() => sender)
        ..registerLazySingleton<RelayCommandDispatcher>(() => relay);

      registerInjectorAgentQueries(getIt);

      final datasource = getIt<AgentQueriesRemoteDataSource>();
      final result = await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          useRelay: true,
        ),
      );

      final response = result['response']! as Map<String, dynamic>;
      final item = response['item']! as Map<String, dynamic>;
      final sqlResult = item['result']! as Map<String, dynamic>;
      final rows = sqlResult['rows']! as List<dynamic>;

      check(relay.streamingCalls).equals(0);
      check(relay.unaryCalls).equals(1);
      check(sender.calls).equals(0);
      check(rows).deepEquals(<Map<String, Object?>>[
        <String, Object?>{'value': 1},
      ]);
      check(sqlResult['row_count']).equals(1);

      await getIt.reset();
    },
  );

  test(
    'registers relayMode.streaming requests through the collected stream path',
    () async {
      final getIt = GetIt.asNewInstance();
      final sender = _ThrowingAgentCommandSender();
      final relay = _FakeRelayCommandDispatcher();
      getIt
        ..registerLazySingleton<Dio>(Dio.new)
        ..registerLazySingleton<AgentCommandSender>(() => sender)
        ..registerLazySingleton<RelayCommandDispatcher>(() => relay);

      registerInjectorAgentQueries(getIt);

      final datasource = getIt<AgentQueriesRemoteDataSource>();
      final result = await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          useRelay: true,
          relayMode: AgentSqlRelayMode.streaming,
        ),
      );

      final response = result['response']! as Map<String, dynamic>;
      final item = response['item']! as Map<String, dynamic>;
      final sqlResult = item['result']! as Map<String, dynamic>;
      final rows = sqlResult['rows']! as List<dynamic>;

      check(relay.streamingCalls).equals(1);
      check(relay.unaryCalls).equals(0);
      check(sender.calls).equals(0);
      check(rows).deepEquals(<Map<String, Object?>>[
        <String, Object?>{'value': 1},
      ]);

      await getIt.reset();
    },
  );

  test('latches relay permanent socket failure to REST fallback', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final sender = _ThrowingAgentCommandSender();
    final relay = _FakeRelayCommandDispatcher(
      unaryError: const SocketDispatchNamespaceForbidden(
        message: 'forbidden',
        role: 'client',
        namespace: '/consumers',
      ),
    );
    final restAdapter = _RestAdapter();
    final dio = Dio()..httpClientAdapter = restAdapter;
    getIt
      ..registerLazySingleton<Dio>(() => dio)
      ..registerLazySingleton<AgentCommandSender>(() => sender)
      ..registerLazySingleton<RelayCommandDispatcher>(() => relay);

    registerInjectorAgentQueries(getIt);

    final datasource = getIt<AgentQueriesRemoteDataSource>();
    final first = await datasource.postSqlExecute(
      const AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        useRelay: true,
      ),
    );
    final second = await datasource.postSqlExecute(
      const AgentSqlExecuteRequest(
        agentId: 'agent-1',
        sql: 'SELECT 1',
        useRelay: true,
      ),
    );

    check(first['response']).equals('ok-from-rest');
    check(second['response']).equals('ok-from-rest');
    check(relay.unaryCalls).equals(1);
    check(restAdapter.calls).equals(2);
    check(sender.calls).equals(0);
  });

  test(
    'REST transport with relay still wraps relay with REST latch on '
    'permanent socket failure',
    () async {
      dotenv.loadFromString(
        envString: '''
API_BASE_URL=http://localhost
USE_FAKE_BACKEND=false
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_RELAY_ENABLED=true
''',
      );
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      final sender = _ThrowingAgentCommandSender();
      final relay = _FakeRelayCommandDispatcher(
        unaryError: const SocketDispatchNamespaceForbidden(
          message: 'forbidden',
          role: 'client',
          namespace: '/consumers',
        ),
      );
      final restAdapter = _RestAdapter();
      final dio = Dio()..httpClientAdapter = restAdapter;
      getIt
        ..registerLazySingleton<Dio>(() => dio)
        ..registerLazySingleton<AgentCommandSender>(() => sender)
        ..registerLazySingleton<RelayCommandDispatcher>(() => relay);

      registerInjectorAgentQueries(getIt);

      final datasource = getIt<AgentQueriesRemoteDataSource>();
      await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          useRelay: true,
        ),
      );
      await datasource.postSqlExecute(
        const AgentSqlExecuteRequest(
          agentId: 'agent-1',
          sql: 'SELECT 1',
          useRelay: true,
        ),
      );

      check(relay.unaryCalls).equals(1);
      check(restAdapter.calls).equals(2);
      check(sender.calls).equals(0);
    },
  );
}
