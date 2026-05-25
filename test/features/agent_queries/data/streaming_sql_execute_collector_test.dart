import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/streaming_sql_execute_collector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const collector = BridgeShapedSqlExecuteCollector();

  Stream<Map<String, dynamic>> streamOf(
    List<Map<String, dynamic>> items, {
    Exception? error,
  }) {
    return Stream<Map<String, dynamic>>.fromIterable(items).asyncMap((e) {
      if (error != null && identical(e, items.last)) {
        throw error;
      }
      return e;
    });
  }

  group('BridgeShapedSqlExecuteCollector', () {
    test(
      'merges row chunks + complete payload into the bridge envelope',
      () async {
        final stream = Stream<Map<String, dynamic>>.fromIterable(
          <Map<String, dynamic>>[
            <String, dynamic>{
              'stream_id': 'stream-1',
              'request_id': 'rpc-1',
              'chunk_index': 0,
              'rows': <Object?>[
                <String, Object?>{'id': 1, 'name': 'a'},
                <String, Object?>{'id': 2, 'name': 'b'},
              ],
              'column_metadata': <Object?>[
                <String, Object?>{'name': 'id', 'type': 'int'},
                <String, Object?>{'name': 'name', 'type': 'string'},
              ],
            },
            <String, dynamic>{
              'stream_id': 'stream-1',
              'request_id': 'rpc-1',
              'chunk_index': 1,
              'rows': <Object?>[
                <String, Object?>{'id': 3, 'name': 'c'},
              ],
            },
            <String, dynamic>{
              'stream_id': 'stream-1',
              'request_id': 'rpc-1',
              'total_rows': 3,
              'affected_rows': 0,
              'execution_id': 'exec-42',
              'started_at': '2026-04-17T15:00:00Z',
              'finished_at': '2026-04-17T15:00:01Z',
            },
          ],
        );

        final envelope = await collector.collect(stream);
        final response = envelope['response']! as Map<String, dynamic>;
        check(response['success']).equals(true);
        check(response['type']).equals('single');
        final item = response['item']! as Map<String, dynamic>;
        check(item['id']).equals('rpc-1');
        check(item['success']).equals(true);

        final result = item['result']! as Map<String, dynamic>;
        final rows = result['rows']! as List<Object?>;
        check(rows.length).equals(3);
        check((rows[0]! as Map)['name']).equals('a');
        check((rows[2]! as Map)['name']).equals('c');
        check(result['row_count']).equals(3);
        check(result['affected_rows']).equals(0);
        check(result['execution_id']).equals('exec-42');
        check(result['started_at']).equals('2026-04-17T15:00:00Z');
        check(result['finished_at']).equals('2026-04-17T15:00:01Z');
        final cols = result['column_metadata']! as List<Object?>;
        check(cols.length).equals(2);
        check((cols.first! as Map)['name']).equals('id');
      },
    );

    test(
      'falls back to row count when complete.total_rows is absent',
      () async {
        final stream = Stream<Map<String, dynamic>>.fromIterable(
          <Map<String, dynamic>>[
            <String, dynamic>{
              'request_id': 'rpc-2',
              'chunk_index': 0,
              'rows': <Object?>[
                <String, Object?>{'x': 1},
                <String, Object?>{'x': 2},
              ],
            },
            <String, dynamic>{
              'request_id': 'rpc-2',
              'execution_id': 'exec-2',
            },
          ],
        );

        final envelope = await collector.collect(stream);
        final result =
            (envelope['response']! as Map)['item']! as Map<String, dynamic>;
        final innerResult = result['result']! as Map<String, dynamic>;
        check((innerResult['rows']! as List).length).equals(2);
        check(innerResult['row_count']).equals(2);
        check(innerResult['execution_id']).equals('exec-2');
      },
    );

    test('empty stream fails instead of becoming an empty success', () async {
      await expectLater(
        () => collector.collect(const Stream<Map<String, dynamic>>.empty()),
        throwsA(isA<FormatException>()),
      );
    });

    test('chunks without complete fail instead of partial success', () async {
      final stream = Stream<Map<String, dynamic>>.fromIterable(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'request_id': 'rpc-missing-complete',
            'rows': <Object?>[
              <String, Object?>{'x': 1},
            ],
          },
        ],
      );

      await expectLater(
        () => collector.collect(stream),
        throwsA(isA<FormatException>()),
      );
    });

    test('complete with total_rows zero succeeds with empty rows', () async {
      final envelope = await collector.collect(
        Stream<Map<String, dynamic>>.fromIterable(
          <Map<String, dynamic>>[
            <String, dynamic>{
              'request_id': 'rpc-empty',
              'total_rows': 0,
              'terminal_status': 'completed',
            },
          ],
        ),
      );
      final item =
          (envelope['response']! as Map)['item']! as Map<String, dynamic>;
      check(item['success']).equals(true);
      final result = item['result']! as Map<String, dynamic>;
      check(result['rows']! as List).isEmpty();
      check(result['row_count']).equals(0);
    });

    test('unknown stream item fails', () async {
      final stream = Stream<Map<String, dynamic>>.fromIterable(
        <Map<String, dynamic>>[
          <String, dynamic>{'request_id': 'rpc-unknown', 'ignored': true},
        ],
      );

      await expectLater(
        () => collector.collect(stream),
        throwsA(isA<FormatException>()),
      );
    });

    test('non-healthy complete terminal status fails', () async {
      final stream = Stream<Map<String, dynamic>>.fromIterable(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'request_id': 'rpc-aborted',
            'terminal_status': 'aborted',
          },
        ],
      );

      await expectLater(
        () => collector.collect(stream),
        throwsA(isA<FormatException>()),
      );
    });

    test('wraps non-streaming relay JSON-RPC response', () async {
      final envelope = await collector.collect(
        Stream<Map<String, dynamic>>.fromIterable(
          <Map<String, dynamic>>[
            <String, dynamic>{
              'jsonrpc': '2.0',
              'id': 'rpc-json',
              'result': <String, dynamic>{
                'rows': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 1},
                ],
                'row_count': 1,
              },
            },
          ],
        ),
      );

      final response = envelope['response']! as Map<String, dynamic>;
      check(response['success']).equals(true);
      final item = response['item']! as Map<String, dynamic>;
      check(item['id']).equals('rpc-json');
      final result = item['result']! as Map<String, dynamic>;
      final rows = result['rows']! as List<dynamic>;
      check(rows.length).equals(1);
    });

    test('throws when buffered rows exceed maxBufferedRows', () async {
      const capped = BridgeShapedSqlExecuteCollector(maxBufferedRows: 2);
      final stream = Stream<Map<String, dynamic>>.fromIterable(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'request_id': 'r',
            'rows': <Object?>[
              <String, Object?>{'a': 1},
              <String, Object?>{'a': 2},
              <String, Object?>{'a': 3},
            ],
          },
          <String, dynamic>{'total_rows': 3},
        ],
      );
      await expectLater(
        () => capped.collect(stream),
        throwsA(isA<FormatException>()),
      );
    });

    test('errors on the stream propagate to the caller', () async {
      final stream = streamOf(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'rows': <Object?>[<String, Object?>{}],
          },
          <String, dynamic>{
            'total_rows': 1,
          }, // last item triggers error
        ],
        error: const FormatException('chunk decode failed'),
      );

      await expectLater(
        () => collector.collect(stream),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
