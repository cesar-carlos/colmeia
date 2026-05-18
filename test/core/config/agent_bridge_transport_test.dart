import 'package:checks/checks.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentBridgeTransport.tryParse', () {
    test('returns null for null', () {
      check(AgentBridgeTransport.tryParse(null)).isNull();
    });

    test('returns null for empty / whitespace', () {
      check(AgentBridgeTransport.tryParse('')).isNull();
      check(AgentBridgeTransport.tryParse('   ')).isNull();
    });

    test('parses socket case-insensitively', () {
      check(
        AgentBridgeTransport.tryParse('socket'),
      ).equals(AgentBridgeTransport.socket);
      check(
        AgentBridgeTransport.tryParse('SOCKET'),
      ).equals(AgentBridgeTransport.socket);
      check(
        AgentBridgeTransport.tryParse('  Socket  '),
      ).equals(AgentBridgeTransport.socket);
    });

    test('parses rest explicitly', () {
      check(
        AgentBridgeTransport.tryParse('rest'),
      ).equals(AgentBridgeTransport.rest);
    });

    test('returns null for unknown values', () {
      check(AgentBridgeTransport.tryParse('grpc')).isNull();
    });
  });

  group('AgentBridgeTransport.parse', () {
    test('returns rest by default for null', () {
      check(AgentBridgeTransport.parse(null)).equals(AgentBridgeTransport.rest);
    });

    test('returns rest for empty / whitespace', () {
      check(AgentBridgeTransport.parse('')).equals(AgentBridgeTransport.rest);
      check(
        AgentBridgeTransport.parse('   '),
      ).equals(AgentBridgeTransport.rest);
    });

    test('parses socket case-insensitively', () {
      check(
        AgentBridgeTransport.parse('socket'),
      ).equals(AgentBridgeTransport.socket);
      check(
        AgentBridgeTransport.parse('SOCKET'),
      ).equals(AgentBridgeTransport.socket);
      check(
        AgentBridgeTransport.parse('  Socket  '),
      ).equals(AgentBridgeTransport.socket);
    });

    test('parses rest explicitly', () {
      check(
        AgentBridgeTransport.parse('rest'),
      ).equals(AgentBridgeTransport.rest);
    });

    test('falls back for unknown values', () {
      check(
        AgentBridgeTransport.parse('grpc'),
      ).equals(AgentBridgeTransport.rest);
    });

    test('honors fallback override', () {
      check(
        AgentBridgeTransport.parse(
          'something-weird',
          fallback: AgentBridgeTransport.socket,
        ),
      ).equals(AgentBridgeTransport.socket);
    });
  });

  group('AgentBridgeTransport.wireValue', () {
    test('returns canonical transport values', () {
      check(AgentBridgeTransport.rest.wireValue).equals('rest');
      check(AgentBridgeTransport.socket.wireValue).equals('socket');
    });
  });
}
