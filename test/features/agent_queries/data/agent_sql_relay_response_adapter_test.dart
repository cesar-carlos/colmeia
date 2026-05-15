import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_relay_response_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('relayJsonRpcToBridgeEnvelope', () {
    test('wraps JSON-RPC result as bridge success item', () {
      final envelope = relayJsonRpcToBridgeEnvelope(
        <String, dynamic>{
          'jsonrpc': '2.0',
          'id': 'rpc-1',
          'result': <String, dynamic>{
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1},
            ],
            'row_count': 1,
          },
        },
        responseType: 'single',
      );

      final response = envelope['response']! as Map<String, dynamic>;
      check(response['success']).equals(true);
      check(response['type']).equals('single');
      final item = response['item']! as Map<String, dynamic>;
      check(item['id']).equals('rpc-1');
      check(item['success']).equals(true);
      final result = item['result']! as Map<String, dynamic>;
      check(result['row_count']).equals(1);
    });

    test('wraps JSON-RPC error as bridge item failure', () {
      final envelope = relayJsonRpcToBridgeEnvelope(
        <String, dynamic>{
          'jsonrpc': '2.0',
          'id': 'rpc-1',
          'error': <String, dynamic>{
            'code': -32000,
            'message': 'bad sql',
          },
        },
        responseType: 'single',
      );

      final response = envelope['response']! as Map<String, dynamic>;
      check(response['success']).equals(true);
      final item = response['item']! as Map<String, dynamic>;
      check(item['success']).equals(false);
      final error = item['error']! as Map<String, dynamic>;
      check(error['message']).equals('bad sql');
    });

    test('keeps bridge-shaped payloads and fills missing response success', () {
      final envelope = relayJsonRpcToBridgeEnvelope(
        <String, dynamic>{
          'response': <String, dynamic>{
            'type': 'single',
            'item': <String, dynamic>{'success': true},
          },
        },
        responseType: 'single',
      );

      final response = envelope['response']! as Map<String, dynamic>;
      check(response['success']).equals(true);
      check(response['type']).equals('single');
    });

    test('rejects unknown response shapes instead of masking them', () {
      expect(
        () => relayJsonRpcToBridgeEnvelope(
          <String, dynamic>{},
          responseType: 'single',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-object JSON-RPC results for SQL responses', () {
      expect(
        () => relayJsonRpcToBridgeEnvelope(
          <String, dynamic>{
            'jsonrpc': '2.0',
            'id': 'rpc-1',
            'result': 'ok',
          },
          responseType: 'single',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-object JSON-RPC errors', () {
      expect(
        () => relayJsonRpcToBridgeEnvelope(
          <String, dynamic>{
            'jsonrpc': '2.0',
            'id': 'rpc-1',
            'error': 'bad sql',
          },
          responseType: 'single',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
