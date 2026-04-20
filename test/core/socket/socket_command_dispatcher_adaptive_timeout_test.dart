import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _RecordingCorrelator implements SocketRequestCorrelator {
  Duration? lastTimeout;

  @override
  int get pendingCount => 0;

  @override
  Future<Map<String, dynamic>> register(
    String rpcId, {
    required Duration timeout,
  }) {
    lastTimeout = timeout;
    final completer = Completer<Map<String, dynamic>>();
    scheduleMicrotask(() {
      completer.complete(<String, dynamic>{
        'response': <String, dynamic>{
          'type': 'single',
          'item': <String, dynamic>{'id': rpcId, 'success': true},
        },
      });
    });
    return completer.future;
  }

  @override
  void completeWith(String rpcId, Map<String, dynamic> response) {}

  @override
  void failWith(String rpcId, Object error, [StackTrace? stack]) {}

  @override
  void failAll(Object error, [StackTrace? stack]) {}

  @override
  Future<void> dispose() async {}
}

Map<String, Object?> _body({
  String agentId = 'agent-1',
  String rpcId = 'rpc-1',
  String method = 'sql.execute',
}) {
  return <String, Object?>{
    'agentId': agentId,
    'command': <String, Object?>{
      'jsonrpc': '2.0',
      'method': method,
      'id': rpcId,
      'params': <String, Object?>{'sql': 'SELECT 1'},
    },
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConsumerSocketDisconnected());
  });

  late _MockConnection connection;
  late _MockSocket rawSocket;
  late _RecordingCorrelator correlator;
  late StreamController<ConsumerSocketConnectionState> stateController;
  late SocketCommandDispatcherImpl dispatcher;

  setUp(() {
    connection = _MockConnection();
    rawSocket = _MockSocket();
    correlator = _RecordingCorrelator();
    stateController = StreamController<ConsumerSocketConnectionState>.broadcast();

    when(() => connection.states()).thenAnswer((_) => stateController.stream);
    when(connection.connect).thenAnswer(
      (_) async => ConsumerSocketConnected(
        socketId: 's',
        handshakeAt: DateTime.utc(2026),
      ),
    );
    when(() => connection.raw).thenReturn(rawSocket);
    when(() => rawSocket.on(any(), any())).thenReturn(() {});
  });

  tearDown(() async {
    await dispatcher.dispose();
    await stateController.close();
  });

  group('SocketCommandDispatcherImpl adaptive timeout', () {
    test(
      'uses defaultTimeout when caller passes none and no oracle',
      () async {
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          defaultTimeout: const Duration(seconds: 12),
        );

        await dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(),
          rpcId: 'rpc-1',
        );

        check(correlator.lastTimeout).equals(const Duration(seconds: 12));
      },
    );

    test(
      'caller-provided timeout always wins over the oracle',
      () async {
        final oracle = AgentLatencyOracle(warmUpSampleCount: 1);
        for (var i = 0; i < 20; i++) {
          oracle.record(
            agentId: 'agent-1',
            method: 'sql.execute',
            elapsed: const Duration(seconds: 10),
          );
        }
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          latencyOracle: oracle,
          defaultTimeout: const Duration(seconds: 12),
        );

        await dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(),
          rpcId: 'rpc-1',
          timeout: const Duration(seconds: 4),
        );

        check(correlator.lastTimeout).equals(const Duration(seconds: 4));
      },
    );

    test(
      'falls back to defaultTimeout while oracle is in warm-up',
      () async {
        final oracle = AgentLatencyOracle()
          // Only 2 samples; below the default warm-up threshold of 5.
          ..record(
            agentId: 'agent-1',
            method: 'sql.execute',
            elapsed: const Duration(milliseconds: 100),
          )
          ..record(
            agentId: 'agent-1',
            method: 'sql.execute',
            elapsed: const Duration(milliseconds: 110),
          );
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          latencyOracle: oracle,
          defaultTimeout: const Duration(seconds: 9),
        );

        await dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(),
          rpcId: 'rpc-1',
        );

        check(correlator.lastTimeout).equals(const Duration(seconds: 9));
      },
    );

    test(
      'consults the oracle once warmed up (different result from default)',
      () async {
        final oracle = AgentLatencyOracle();
        for (var i = 0; i < 30; i++) {
          // ~constant 7s latency → suggestion clamps to ceiling 10s
          // (mean ~7s + 0 stddev ≈ 7s, which is within [3s, 10s]).
          oracle.record(
            agentId: 'agent-1',
            method: 'sql.execute',
            elapsed: const Duration(seconds: 7),
          );
        }
        dispatcher = SocketCommandDispatcherImpl(
          connection: connection,
          correlator: correlator,
          latencyOracle: oracle,
          defaultTimeout: const Duration(seconds: 30),
        );

        await dispatcher.sendAgentsCommand(
          agentId: 'agent-1',
          body: _body(),
          rpcId: 'rpc-1',
        );

        // The dispatcher uses the oracle's clamp window (default
        // [3s, 60s]) — suggestion is around 7s, well below 30s default.
        check(correlator.lastTimeout!.inSeconds).isLessThan(30);
        check(correlator.lastTimeout!.inSeconds).isGreaterOrEqual(3);
      },
    );
  });
}
