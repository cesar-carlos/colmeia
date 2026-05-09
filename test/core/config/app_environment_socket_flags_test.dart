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
    });
  });
}
