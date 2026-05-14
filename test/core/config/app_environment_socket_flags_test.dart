import 'package:checks/checks.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    dotenv.loadFromString(
      envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_RELAY_ENABLED=false
SOCKET_PRESENCE_LISTENER_ENABLED=false
''',
    );
  });

  group('AppEnvironment socket flags', () {
    test('socket transport implies relay and presence stacks', () {
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=socket
SOCKET_RELAY_ENABLED=false
SOCKET_PRESENCE_LISTENER_ENABLED=false
''',
      );

      check(AppEnvironment.agentBridgeTransport).equals(
        AgentBridgeTransport.socket,
      );
      check(AppEnvironment.socketRelayEnabled).isTrue();
      check(AppEnvironment.socketPresenceListenerEnabled).isTrue();
      check(AppEnvironment.consumerSocketLifecycleEnabled).isTrue();
    });

    test('rest transport keeps relay and presence disabled by default', () {
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=rest
''',
      );

      check(AppEnvironment.agentBridgeTransport).equals(
        AgentBridgeTransport.rest,
      );
      check(AppEnvironment.socketRelayEnabled).isFalse();
      check(AppEnvironment.socketPresenceListenerEnabled).isFalse();
      check(AppEnvironment.consumerSocketLifecycleEnabled).isFalse();
    });

    test('rest transport can opt into relay and presence independently', () {
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_RELAY_ENABLED=true
SOCKET_PRESENCE_LISTENER_ENABLED=true
''',
      );

      check(AppEnvironment.agentBridgeTransport).equals(
        AgentBridgeTransport.rest,
      );
      check(AppEnvironment.socketRelayEnabled).isTrue();
      check(AppEnvironment.socketPresenceListenerEnabled).isTrue();
      check(AppEnvironment.consumerSocketLifecycleEnabled).isTrue();
    });

    test('rest transport with presence only still needs socket lifecycle', () {
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_RELAY_ENABLED=false
SOCKET_PRESENCE_LISTENER_ENABLED=true
''',
      );

      check(AppEnvironment.socketRelayEnabled).isFalse();
      check(AppEnvironment.socketPresenceListenerEnabled).isTrue();
      check(AppEnvironment.consumerSocketLifecycleEnabled).isTrue();
    });

    test('numeric socket flags are clamped to safe runtime values', () {
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_RECONNECT_ATTEMPTS=0
SOCKET_RECONNECT_INITIAL_DELAY_MS=-1
SOCKET_RECONNECT_MAX_DELAY_MS=0
SOCKET_REQUEST_TIMEOUT_MS=-20
SOCKET_HANDSHAKE_TIMEOUT_MS=0
SOCKET_BATCH_WINDOW_MS=-5
SOCKET_BATCH_MAX_SIZE=99
SOCKET_BATCH_MIN_SIZE=40
SOCKET_RELAY_REQUEST_TIMEOUT_MS=0
SOCKET_RELAY_CONVERSATION_START_TIMEOUT_MS=-1
SOCKET_RELAY_CONVERSATION_END_TIMEOUT_MS=0
SOCKET_RELAY_STREAM_INITIAL_WINDOW=-8
SOCKET_RELAY_STREAM_REFILL_THRESHOLD=99
''',
      );

      check(AppEnvironment.socketReconnectAttempts).equals(
        AppEnvironment.defaultSocketReconnectAttempts,
      );
      check(AppEnvironment.socketReconnectInitialDelayMs).equals(
        AppEnvironment.defaultSocketReconnectInitialDelayMs,
      );
      check(AppEnvironment.socketReconnectMaxDelayMs).equals(
        AppEnvironment.defaultSocketReconnectMaxDelayMs,
      );
      check(AppEnvironment.socketRequestTimeoutMs).equals(
        AppEnvironment.defaultSocketRequestTimeoutMs,
      );
      check(AppEnvironment.socketHandshakeTimeoutMs).equals(
        AppEnvironment.defaultSocketHandshakeTimeoutMs,
      );
      check(AppEnvironment.socketBatchWindowMs).equals(
        AppEnvironment.defaultSocketBatchWindowMs,
      );
      check(AppEnvironment.socketBatchMaxSize).equals(32);
      check(AppEnvironment.socketBatchMinSize).equals(32);
      check(AppEnvironment.socketRelayRequestTimeoutMs).equals(
        AppEnvironment.defaultSocketRelayRequestTimeoutMs,
      );
      check(AppEnvironment.socketRelayConversationStartTimeoutMs).equals(
        AppEnvironment.defaultSocketRelayConversationStartTimeoutMs,
      );
      check(AppEnvironment.socketRelayConversationEndTimeoutMs).equals(
        AppEnvironment.defaultSocketRelayConversationEndTimeoutMs,
      );
      check(AppEnvironment.socketRelayStreamInitialWindow).equals(
        AppEnvironment.defaultSocketRelayStreamInitialWindow,
      );
      check(AppEnvironment.socketRelayStreamRefillThreshold).equals(
        AppEnvironment.defaultSocketRelayStreamInitialWindow,
      );
    });
  });
}
