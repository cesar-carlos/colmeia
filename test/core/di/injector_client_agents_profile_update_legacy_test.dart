import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/di/injector_client_agents.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _MockConnection extends Mock implements ConsumerSocketConnection {}

class _MockSocket extends Mock implements io.Socket {}

class _SocketWiring {
  final Map<String, List<Function>> handlers = <String, List<Function>>{};

  void register(_MockSocket socket) {
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1] as Function;
      handlers.putIfAbsent(name, () => <Function>[]).add(handler);
      return () {};
    });
    when(() => socket.off(any())).thenAnswer((invocation) {
      handlers[invocation.positionalArguments[0] as String]?.clear();
    });
    when(() => socket.off(any(), any())).thenAnswer((invocation) {
      final name = invocation.positionalArguments[0] as String;
      final handler = invocation.positionalArguments[1];
      handlers[name]?.remove(handler);
      if (handlers[name]?.isEmpty ?? false) {
        handlers.remove(name);
      }
    });
  }

  void fire(String event, Object? payload) {
    final list = handlers[event];
    if (list == null) {
      return;
    }
    for (final handler in List<Function>.of(list)) {
      Function.apply(handler, <Object?>[payload]);
    }
  }
}

class _FakeSocketCommandDispatcher implements SocketCommandDispatcher {
  @override
  void cancel(String rpcId, {String reason = 'cancelled'}) {}

  @override
  Future<void> dispose() async {}

  @override
  Stream<AgentCommandOutcome> outcomes() {
    return const Stream<AgentCommandOutcome>.empty();
  }

  @override
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
    bool coalesce = true,
  }) {
    throw StateError('sendAgentsCommand is not used by this DI test');
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(() {});
  });

  tearDown(() {
    dotenv.loadFromString(
      envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_PRESENCE_LISTENER_ENABLED=false
SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED=false
''',
    );
  });

  test(
    'injects profile update listener with explicit legacy raw JSON mode',
    () async {
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_PRESENCE_LISTENER_ENABLED=true
SOCKET_PROFILE_UPDATED_LEGACY_RAW_JSON_ENABLED=true
''',
      );
      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      final connection = _MockConnection();
      final socket = _MockSocket();
      final states =
          StreamController<ConsumerSocketConnectionState>.broadcast();
      Stream<ConsumerSocketConnectionState> answerStates(Invocation _) {
        return states.stream;
      }

      final wiring = _SocketWiring()..register(socket);
      addTearDown(states.close);
      when(() => connection.raw).thenReturn(socket);
      when(() => connection.isConnected).thenReturn(true);
      when(connection.states).thenAnswer(answerStates);
      getIt
        ..registerLazySingleton<ConsumerSocketConnection>(() => connection)
        ..registerLazySingleton<SocketCommandDispatcher>(
          _FakeSocketCommandDispatcher.new,
        );

      registerInjectorClientAgents(getIt);

      final presence = getIt<AgentPresenceStream>();
      final emitted = presence.events().take(1).toList();
      wiring.fire(
        ClientAgentProfileUpdatedListener.eventName,
        <String, Object?>{
          'agent_id': 'agent-di-legacy',
          'profile_version': 3,
          'changed_fields': <String>['name'],
          'profileUpdatedAt': '2026-04-17T15:30:00Z',
          'source': 'legacy-hub',
        },
      );

      final list = await emitted.timeout(const Duration(seconds: 1));
      check(list.length).equals(1);
      final event = list.single as AgentPresenceCatalogUpdated;
      check(event.agentId).equals('agent-di-legacy');
      check(event.profileVersion).equals(3);
      check(event.changedFields).deepEquals(const <String>{'name'});
      check(event.source).equals('legacy-hub');
    },
  );
}
