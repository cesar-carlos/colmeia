import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_agents_command_response_adapter.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('agentsCommandResponseToBridgeEnvelope', () {
    test('decodes PayloadFrame-wrapped JSON-RPC sql.execute', () {
      const codec = PayloadFrameCodec();
      final encoded = codec.encodeJson(
        <String, dynamic>{
          'jsonrpc': '2.0',
          'id': 'rpc-frame-1',
          'result': <String, dynamic>{
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{'CodCliente': 42},
            ],
            'row_count': 1,
          },
        },
        requestId: 'rpc-frame-1',
      );

      final envelope = agentsCommandResponseToBridgeEnvelope(
        encoded.frame.toMap(),
        responseType: 'single',
      );

      final parsed = AgentSqlBridgeResponse.parseSuccess(envelope);
      check(parsed.rows.single['CodCliente']).equals(42);
    });

    test('wraps JSON-RPC sql.execute result for parseSuccess', () {
      final envelope = agentsCommandResponseToBridgeEnvelope(
        <String, dynamic>{
          'jsonrpc': '2.0',
          'id': 'rpc-1',
          'result': <String, dynamic>{
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{'CodCliente': 1},
            ],
            'row_count': 1,
          },
        },
        responseType: 'single',
      );

      final parsed = AgentSqlBridgeResponse.parseSuccess(envelope);
      check(parsed.rowCount).equals(1);
      check(parsed.rows.single['CodCliente']).equals(1);
    });

    test('wraps JSON-RPC sql.executeBatch result for parseBatchSuccess', () {
      final envelope = agentsCommandResponseToBridgeEnvelope(
        <String, dynamic>{
          'jsonrpc': '2.0',
          'id': 'rpc-batch-1',
          'result': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'index': 0,
                'ok': true,
                'rows': <Map<String, dynamic>>[
                  <String, dynamic>{'CodCliente': 1},
                ],
                'row_count': 1,
              },
              <String, dynamic>{
                'index': 1,
                'ok': true,
                'rows': <Map<String, dynamic>>[
                  <String, dynamic>{'Nome': 'A'},
                ],
                'row_count': 1,
              },
            ],
            'total_commands': 2,
            'successful_commands': 2,
            'failed_commands': 0,
          },
        },
        responseType: 'batch',
      );

      final parsed = AgentSqlBridgeResponse.parseBatchSuccess(envelope);
      check(parsed.totalCommands).equals(2);
      check(parsed.items.every((item) => item.ok)).isTrue();
    });

    test('maps coordinator batch items into REST parity envelope', () {
      final envelope = agentsCommandResponseToBridgeEnvelope(
        <String, dynamic>{
          'mode': 'bridge',
          'response': <String, dynamic>{
            'type': 'batch',
            'success': true,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'index': 0,
                'ok': true,
                'rows': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 1},
                ],
                'row_count': 1,
              },
            ],
          },
        },
        responseType: 'batch',
      );

      final parsed = AgentSqlBridgeResponse.parseBatchSuccess(envelope);
      check(parsed.items.single.ok).isTrue();
      check(parsed.items.single.rows.single['id']).equals(1);
    });

    test('maps flat response.items batch shape into REST parity envelope', () {
      final envelope = agentsCommandResponseToBridgeEnvelope(
        <String, dynamic>{
          'response': <String, dynamic>{
            'success': true,
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'index': 0,
                'ok': true,
                'rows': <Map<String, dynamic>>[],
                'row_count': 0,
              },
            ],
          },
        },
        responseType: 'batch',
      );

      final parsed = AgentSqlBridgeResponse.parseBatchSuccess(envelope);
      check(parsed.items.length).equals(1);
    });

    test('keeps REST parity single envelope and fills missing success', () {
      final envelope = agentsCommandResponseToBridgeEnvelope(
        <String, dynamic>{
          'response': <String, dynamic>{
            'item': <String, dynamic>{
              'success': true,
              'result': <String, dynamic>{
                'rows': <Map<String, dynamic>>[],
                'row_count': 0,
              },
            },
          },
        },
        responseType: 'single',
      );

      final response = envelope['response']! as Map<String, dynamic>;
      check(response['success']).equals(true);
      AgentSqlBridgeResponse.parseSuccess(envelope);
    });
  });
}
