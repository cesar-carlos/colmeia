// Smoke e2e for the relay channel (PR-L unary path).
//
// Validates that `RelayConversation.start()` →
// `RelayCommandDispatcher.sendUnary(...)` round-trips a `SELECT 1`
// against the real `plug_server` declared in `API_BASE_URL`.
//
// This test is **double opt-in**:
//
// 1. The standard `E2E_*` env keys must be set (same as
//    `socket_consumer_smoke_e2e_test.dart`).
// 2. The hub side must accept relay traffic for the test agent. We do
//    NOT require `SOCKET_RELAY_ENABLED=true` to be set globally — the
//    bundle wires the relay dispatcher directly so the smoke can run
//    on builds whose default transport stays on `agents:command`.
//
// Run locally:
//
// ```bash
// flutter test test/integration/e2e/socket_relay_smoke_e2e_test.dart \
//   --tags=e2e
// ```

import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;
import 'package:uuid/uuid.dart';

import 'support/e2e_socket_bootstrap.dart';

void main() {
  group(
    'Relay socket smoke (e2e)',
    () {
      test(
        'sendUnary round-trips a SELECT 1 through relay:rpc.request',
        () async {
          final missingKeys = missingE2eSocketKeys();
          if (missingKeys.isNotEmpty) {
            // Console hint when dart-defines are absent. Tests under
            // `test/integration/e2e` are excluded from `flutter test`
            // by default, so this print only fires when developers run
            // the smoke explicitly.
            // ignore: avoid_print
            print(
              'SKIP socket_relay_smoke_e2e: missing '
              '${missingKeys.join(', ')}. Set them in assets/env/local.env, '
              'process env, or --dart-define.',
            );
            return;
          }

          final bundle = await setupE2eSocketBundle(withRelay: true);
          addTearDown(bundle.dispose);

          final relayDispatcher = bundle.relayDispatcher;
          expect(
            relayDispatcher,
            isNotNull,
            reason: 'Bundle was built with `withRelay: true`.',
          );

          // ConsumerSocketConnection.connect() is implicit inside
          // RelayConversationManager.obtain(...), but warming it here
          // keeps the test failure messages closer to the real cause
          // (handshake vs relay rejection).
          await bundle.connection.connect();

          const bodyMapper = AgentSqlExecuteRequestToBridgeBody();
          final clientRequestId = const Uuid().v4();
          const agentId = String.fromEnvironment('E2E_AGENT_ID');
          const clientToken = String.fromEnvironment('E2E_CLIENT_TOKEN');
          final body = bodyMapper.build(
            request: const AgentSqlExecuteRequest(
              agentId: agentId,
              clientToken: clientToken,
              sql: 'SELECT 1',
              bridgeTimeoutMs: 10000,
            ),
            rpcId: clientRequestId,
          );

          final response = await relayDispatcher!.sendUnary(
            agentId: agentId,
            body: body,
            clientRequestId: clientRequestId,
          );

          expect(response, isNotEmpty);
          final envelope = response['response'];
          expect(
            envelope,
            isA<Map<dynamic, dynamic>>(),
            reason:
                'Expected hub bridge envelope `response.{type,item}` from '
                'relay:rpc.response. Raw payload: $response',
          );
          if (envelope is Map) {
            final item = envelope['item'];
            expect(item, isA<Map<dynamic, dynamic>>());
            if (item is Map) {
              expect(
                item['error'],
                isNull,
                reason:
                    'Relay sendUnary returned a JSON-RPC error: ${item['error']}',
              );
            }
          }
        },
        // Realistic budget: REST login + handshake + conversation.start +
        // relay.request → response.
        timeout: const Timeout(Duration(seconds: 45)),
      );
    },
    tags: <String>['e2e'],
  );
}
