// Smoke e2e for the consumer Socket channel.
//
// Validates the full Phase 1 + PR-K + PR-L wire path — login REST →
// `ConsumerSocketConnection.connect()` → `agents:command` SELECT 1 —
// against the real `plug_server` declared in `API_BASE_URL`. The test
// is **opt-in**: it skips silently when the required `E2E_*` env keys
// are absent, so CI runs that exclude `e2e` pass untouched.
//
// How to run locally:
//
// ```bash
// flutter test test/integration/e2e/socket_consumer_smoke_e2e_test.dart \
//   --tags=e2e \
//   --dart-define=API_BASE_URL=https://plug-server.example.com/api/v1 \
//   --dart-define=E2E_CLIENT_EMAIL=... \
//   --dart-define=E2E_CLIENT_PASSWORD=... \
//   --dart-define=E2E_AGENT_ID=... \
//   --dart-define=E2E_CLIENT_TOKEN=...
// ```
//
// Or set the keys in `assets/env/local.env` and just:
//
// ```bash
// flutter test test/integration/e2e/socket_consumer_smoke_e2e_test.dart \
//   --tags=e2e
// ```

import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;
import 'package:uuid/uuid.dart';

import 'support/e2e_socket_bootstrap.dart';

void main() {
  group(
    'Consumer socket smoke (e2e)',
    () {
      test(
        'connects to /consumers and exchanges agents:command SELECT 1',
        () async {
          final missingKeys = missingE2eSocketKeys();
          if (missingKeys.isNotEmpty) {
            // Console hint when dart-defines are absent (integration runs only).
            // ignore: avoid_print
            print(
              'SKIP socket_consumer_smoke_e2e: missing '
              '${missingKeys.join(', ')}. Set them in assets/env/local.env, '
              'process env, or --dart-define.',
            );
            return;
          }

          final bundle = await setupE2eSocketBundle();
          addTearDown(bundle.dispose);

          // 1) Handshake: connect should reach `connection:ready` and
          //    transition the state stream to `Connected`.
          final connected = await bundle.connection.connect();
          expect(connected.socketId, isNotEmpty);
          expect(
            bundle.connection.state,
            isA<ConsumerSocketConnected>(),
          );

          // 2) RPC: send `agents:command` (SELECT 1) and assert the
          //    bridge envelope round-trips with `response.item.success`.
          const bodyMapper = AgentSqlExecuteRequestToBridgeBody();
          final rpcId = const Uuid().v4();
          const agentId = String.fromEnvironment('E2E_AGENT_ID');
          const clientToken = String.fromEnvironment('E2E_CLIENT_TOKEN');
          final body = bodyMapper.build(
            request: const AgentSqlExecuteRequest(
              agentId: agentId,
              clientToken: clientToken,
              sql: 'SELECT 1',
              bridgeTimeoutMs: 10000,
            ),
            rpcId: rpcId,
          );
          final response = await bundle.dispatcher.sendAgentsCommand(
            agentId: agentId,
            body: body,
            rpcId: rpcId,
          );

          expect(response, isNotEmpty);
          final envelope = response['response'];
          expect(
            envelope,
            isA<Map<dynamic, dynamic>>(),
            reason:
                'Expected hub bridge envelope `response.{type,item}`. '
                'Raw payload: $response',
          );
          if (envelope is Map) {
            final item = envelope['item'];
            expect(
              item,
              isA<Map<dynamic, dynamic>>(),
              reason: 'Expected `response.item` to be a JSON object.',
            );
            if (item is Map) {
              // The hub may wrap `success: true` either at the
              // bridge level or inside `result`. Both are fine — we
              // just want to verify the call did not return an
              // `error` block.
              expect(
                item['error'],
                isNull,
                reason:
                    'agents:command returned a JSON-RPC error: ${item['error']}',
              );
            }
          }
        },
        // Realistic budget: REST login + handshake + one bridge round-trip.
        timeout: const Timeout(Duration(seconds: 30)),
      );
    },
    tags: <String>['e2e'],
  );
}
