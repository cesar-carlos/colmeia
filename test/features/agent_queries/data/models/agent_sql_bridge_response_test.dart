import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should parse rows and pagination from bridge success payload', () {
    final result = AgentSqlBridgeResponse.parseSuccess(<String, dynamic>{
      'response': <String, dynamic>{
        'success': true,
        'item': <String, dynamic>{
          'success': true,
          'result': <String, dynamic>{
            'execution_id': 'exec-1',
            'rows': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'name': 'Alice'},
            ],
            'row_count': 1,
            'affected_rows': 0,
            'pagination': <String, dynamic>{
              'page': 2,
              'page_size': 50,
              'returned_rows': 1,
              'has_next_page': true,
              'has_previous_page': true,
              'current_cursor': 'cursor-2',
              'next_cursor': 'cursor-3',
            },
          },
        },
      },
    });

    check(result.executionId).equals('exec-1');
    check(result.rowCount).equals(1);
    check(result.rows.single['id']).equals(1);
    check(result.rows.single['name']).equals('Alice');
    check(result.pagination).isNotNull();
    check(result.pagination!.page).equals(2);
    check(result.pagination!.pageSize).equals(50);
    check(result.pagination!.returnedRows).equals(1);
    check(result.pagination!.hasNextPage).equals(true);
    check(result.pagination!.hasPreviousPage).equals(true);
    check(result.pagination!.currentCursor).equals('cursor-2');
    check(result.pagination!.nextCursor).equals('cursor-3');
  });

  test('should expose full error.data on RPC item failure', () {
    expect(
      () => AgentSqlBridgeResponse.parseSuccess(<String, dynamic>{
        'response': <String, dynamic>{
          'success': true,
          'item': <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{
              'code': -32101,
              'message': 'bad sql',
              'data': <String, dynamic>{
                'reason': 'validation',
                'retryable': false,
                'vendor_hint': 'use LIMIT',
              },
            },
          },
        },
      }),
      throwsA(
        isA<AgentSqlRpcException>()
            .having(
              (e) => e.details.errorData,
              'errorData',
              isNotNull,
            )
            .having(
              (e) => e.details.errorData!['vendor_hint'],
              'vendor_hint',
              'use LIMIT',
            ),
      ),
    );
  });
}
