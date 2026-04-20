// Smoke e2e for the realtime presence stack (PR-M).
//
// Validates `SocketAgentPresenceStream` against a real `plug_server`
// using the **command-hint** path (Camada 2): we issue an
// `agents:command` SELECT 1, which `AgentCommandPresenceHinter`
// converts into an `AgentPresenceHint(online: true)` on the stream.
//
// This is the deterministic half of the design — the catalog push
// path (`client:agent.profile.updated`) is event-driven by the hub
// (admin updates / heartbeats) and cannot be coerced from the client.
// Verifying it requires either a mock hub or a manual broadcast; both
// are out of scope for the smoke.
//
// Run locally:
//
// ```bash
// flutter test test/integration/e2e/socket_presence_smoke_e2e_test.dart \
//   --tags=e2e
// ```

import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/data/socket/socket_agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;
import 'package:uuid/uuid.dart';

import 'support/e2e_socket_bootstrap.dart';

void main() {
  group(
    'Presence socket smoke (e2e)',
    () {
      test(
        'AgentPresenceHint(online) lands after a successful agents:command',
        () async {
          final missingKeys = missingE2eSocketKeys();
          if (missingKeys.isNotEmpty) {
            // Console hint when dart-defines are absent. Tests under
            // `test/integration/e2e` are excluded from `flutter test`
            // by default, so this print only fires when developers run
            // the smoke explicitly.
            // ignore: avoid_print
            print(
              'SKIP socket_presence_smoke_e2e: missing '
              '${missingKeys.join(', ')}. Set them in assets/env/local.env, '
              'process env, or --dart-define.',
            );
            return;
          }

          final bundle = await setupE2eSocketBundle();
          addTearDown(bundle.dispose);

          // Build the presence stack the same way the production DI
          // does in `injector_client_agents`. We do it inline here
          // because the bundle is intentionally minimal.
          final presenceStream = SocketAgentPresenceStream.deferred(
            connection: bundle.connection,
          );
          addTearDown(presenceStream.dispose);
          final listener = ClientAgentProfileUpdatedListener(
            connection: bundle.connection,
            sink: presenceStream.sink,
          );
          final hinter = AgentCommandPresenceHinter(
            dispatcher: bundle.dispatcher,
            sink: presenceStream.sink,
          );
          presenceStream.bind(catalogListener: listener, commandHinter: hinter);

          // Connect first so the listener attaches via the state stream.
          await bundle.connection.connect();

          const agentId = String.fromEnvironment('E2E_AGENT_ID');
          final receivedHints = <AgentPresenceHint>[];
          final firstHintForAgent = presenceStream
              .events()
              .where(
                (event) => event is AgentPresenceHint && event.agentId == agentId,
              )
              .cast<AgentPresenceHint>()
              .first;
          final allEventsSub = presenceStream.events().listen((event) {
            if (event is AgentPresenceHint && event.agentId == agentId) {
              receivedHints.add(event);
            }
          });
          addTearDown(allEventsSub.cancel);

          // Trigger the hint by issuing a SELECT 1 against the test
          // agent. The dispatcher emits the outcome, the hinter
          // translates it to AgentPresenceHint(online: true), and the
          // composer fans it out on the stream.
          const bodyMapper = AgentSqlExecuteRequestToBridgeBody();
          final rpcId = const Uuid().v4();
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
          await bundle.dispatcher.sendAgentsCommand(
            agentId: agentId,
            body: body,
            rpcId: rpcId,
          );

          // Wait up to 10 seconds for the hint to land. In practice the
          // outcome stream completes inside the same microtask tick as
          // the command response, so this is just a safety net.
          final hint = await firstHintForAgent.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              fail(
                'No AgentPresenceHint arrived for $agentId within 10 s after '
                'a successful agents:command. Received hints: $receivedHints',
              );
            },
          );

          expect(hint.online, isTrue);
          expect(hint.source, equals('agents:command_success'));
        },
        timeout: const Timeout(Duration(seconds: 45)),
      );
    },
    tags: <String>['e2e'],
  );
}
