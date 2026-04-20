/// Aggregates the chunked output of
/// `AgentQueriesStreamingRemoteDataSource.streamSqlExecute(...)` into a
/// single bridge-shaped `Map<String, dynamic>` — the same envelope
/// `AgentSqlBridgeResponse.parseSuccess` understands.
///
/// PR-L+ part 3.5: this is the bridge between the streaming wire and
/// repositories that still expect the unary `Future<Map>` shape. Use it
/// to swap a unary REST/`agents:command` datasource for the streaming
/// relay path **without** touching the repository or the executor.
///
/// Shape contract (from `plug_agente/docs/communication/schemas`):
///
/// - Each `relay:rpc.chunk` carries:
///   `{ stream_id, request_id, chunk_index, rows: [...], total_chunks?,
///      column_metadata? }`.
/// - The `relay:rpc.complete` payload (forwarded as the final stream
///   item by `RelayCommandDispatcherImpl` since p3.5) carries:
///   `{ stream_id, request_id, total_rows, affected_rows?,
///      execution_id?, started_at?, finished_at?, terminal_status? }`.
///
/// The bridge envelope produced by [collect] mirrors what the unary
/// `agents:command_response` returns:
///
/// ```json
/// {
///   "response": {
///     "type": "single",
///     "item": {
///       "id": "<requestId>",
///       "success": true,
///       "result": {
///         "execution_id": "...",
///         "started_at": "...",
///         "finished_at": "...",
///         "rows": [...],
///         "row_count": ...,
///         "affected_rows": ...
///       }
///     }
///   }
/// }
/// ```
// PR-L+ p3.5 keeps a single method; future variants (chunk-time
// callbacks, partial-result snapshots) may add more, at which point
// this ignore goes.
// ignore: one_member_abstracts
abstract interface class StreamingSqlExecuteCollector {
  Future<Map<String, dynamic>> collect(Stream<Map<String, dynamic>> chunks);
}

/// Default collector that materialises the canonical bridge envelope
/// described in the class docs. Built to be **forgiving** of partial
/// payloads: if a `complete` event never arrives (older agent or hub
/// drop) the result still contains the accumulated rows; if no chunks
/// arrive, the result is an empty success envelope so callers can
/// distinguish "agent ran but found nothing" from "transport failure"
/// (the latter surfaces as a stream error and never reaches `collect`).
class BridgeShapedSqlExecuteCollector implements StreamingSqlExecuteCollector {
  const BridgeShapedSqlExecuteCollector();

  @override
  Future<Map<String, dynamic>> collect(
    Stream<Map<String, dynamic>> chunks,
  ) async {
    final rows = <Object?>[];
    String? executionId;
    String? startedAt;
    String? finishedAt;
    int? totalRowsFromComplete;
    int? affectedRows;
    String? requestId;
    List<Object?>? columnMetadata;

    await for (final chunk in chunks) {
      // Capture envelope-level metadata.
      requestId ??= chunk['request_id']?.toString();

      // Chunk: append rows + grab column_metadata once.
      final maybeRows = chunk['rows'];
      if (maybeRows is List) {
        rows.addAll(maybeRows);
        final cols = chunk['column_metadata'];
        if (cols is List && columnMetadata == null) {
          columnMetadata = List<Object?>.from(cols);
        }
        continue;
      }

      // Complete payload.
      final maybeTotalRows = chunk['total_rows'];
      if (maybeTotalRows is num) {
        totalRowsFromComplete = maybeTotalRows.toInt();
      }
      final maybeAffected = chunk['affected_rows'];
      if (maybeAffected is num) {
        affectedRows = maybeAffected.toInt();
      }
      executionId ??= chunk['execution_id']?.toString();
      startedAt ??= chunk['started_at']?.toString();
      finishedAt ??= chunk['finished_at']?.toString();
    }

    final rowCount = totalRowsFromComplete ?? rows.length;

    final result = <String, dynamic>{
      'rows': rows,
      'row_count': rowCount,
      'affected_rows': ?affectedRows,
      'execution_id': ?executionId,
      'started_at': ?startedAt,
      'finished_at': ?finishedAt,
      'column_metadata': ?columnMetadata,
    };

    return <String, dynamic>{
      'response': <String, dynamic>{
        'type': 'single',
        'item': <String, dynamic>{
          'id': ?requestId,
          'success': true,
          'result': result,
        },
      },
    };
  }
}
