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
        final stream = Stream<Map<String, dynamic>>.fromIterable(<
          Map<String, dynamic>
        >[
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
          // The dispatcher (PR-L+ p3.5) forwards the complete payload
          // as the FINAL stream item before closing.
          <String, dynamic>{
            'stream_id': 'stream-1',
            'request_id': 'rpc-1',
            'total_rows': 3,
            'affected_rows': 0,
            'execution_id': 'exec-42',
            'started_at': '2026-04-17T15:00:00Z',
            'finished_at': '2026-04-17T15:00:01Z',
          },
        ]);

        final envelope = await collector.collect(stream);
        final response = envelope['response']! as Map<String, dynamic>;
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
        final stream = Stream<Map<String, dynamic>>.fromIterable(<
          Map<String, dynamic>
        >[
          <String, dynamic>{
            'request_id': 'rpc-2',
            'chunk_index': 0,
            'rows': <Object?>[
              <String, Object?>{'x': 1},
              <String, Object?>{'x': 2},
            ],
          },
          // No complete payload — agent disconnected gracefully or
          // hub forwarded only chunks. Collector still wraps a valid
          // response so the repository parser succeeds.
        ]);

        final envelope = await collector.collect(stream);
        final result =
            (envelope['response']! as Map)['item']! as Map<String, dynamic>;
        final innerResult = result['result']! as Map<String, dynamic>;
        check((innerResult['rows']! as List).length).equals(2);
        check(innerResult['row_count']).equals(2);
        check(innerResult.containsKey('execution_id')).isFalse();
      },
    );

    test('empty stream yields empty success envelope', () async {
      final envelope = await collector.collect(
        const Stream<Map<String, dynamic>>.empty(),
      );
      final item = (envelope['response']! as Map)['item']!
          as Map<String, dynamic>;
      check(item['success']).equals(true);
      final result = item['result']! as Map<String, dynamic>;
      check(result['rows']! as List).isEmpty();
      check(result['row_count']).equals(0);
    });

    test('errors on the stream propagate to the caller', () async {
      final stream = streamOf(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'rows': <Object?>[<String, Object?>{}],
          },
          <String, dynamic>{'rows': <Object?>[]}, // last item triggers error
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
