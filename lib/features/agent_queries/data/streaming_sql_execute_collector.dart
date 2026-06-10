import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_relay_response_adapter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

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
  Future<Map<String, dynamic>> collect(
    Stream<Map<String, dynamic>> chunks, {
    AgentQueriesCancelScope? cancelScope,
  });
}

/// Default collector that materialises the canonical bridge envelope
/// described in the class docs.
///
/// A chunked stream must finish with a `relay:rpc.complete` payload. Empty,
/// incomplete, or unknown stream items fail fast so transport loss cannot be
/// misreported as a successful empty SQL result.
///
/// When [maxBufferedRows] is set, buffered row count across chunks must
/// not exceed it — otherwise [collect] throws [StateError] to cap
/// client memory for very large result sets (prefer true streaming in
/// the domain when this trips).
class BridgeShapedSqlExecuteCollector implements StreamingSqlExecuteCollector {
  const BridgeShapedSqlExecuteCollector({this.maxBufferedRows});

  /// Maximum rows buffered from chunk `rows` arrays. `null` = unlimited.
  final int? maxBufferedRows;

  @override
  Future<Map<String, dynamic>> collect(
    Stream<Map<String, dynamic>> chunks, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final rows = <Object?>[];
    String? executionId;
    String? startedAt;
    String? finishedAt;
    int? totalRowsFromComplete;
    int? affectedRows;
    String? requestId;
    List<Object?>? columnMetadata;
    var sawItem = false;
    var sawChunk = false;
    var sawComplete = false;

    await for (final chunk in chunks) {
      if (cancelScope?.isCancelled ?? false) {
        throw const RelayRequestCancelled(
          message: 'Relay streaming collect aborted by AgentQueriesCancelScope',
        );
      }
      sawItem = true;
      if (isRelayJsonRpcResponse(chunk)) {
        return relayJsonRpcToBridgeEnvelope(chunk, responseType: 'single');
      }

      // Capture envelope-level metadata.
      requestId ??= _readString(chunk, 'request_id', 'requestId');

      // Chunk: append rows + grab column_metadata once.
      if (chunk.containsKey('rows')) {
        final maybeRows = chunk['rows'];
        if (maybeRows is! List) {
          throw const FormatException(
            'Relay streaming chunk rows must be an array',
          );
        }
        sawChunk = true;
        rows.addAll(maybeRows);
        final cap = maxBufferedRows;
        if (cap != null && rows.length > cap) {
          // FormatException is consistent with the other protocol failures
          // surfaced by this collector. The repository layer should map this
          // to a user-visible "result set too large" message rather than a
          // generic technical error — see canvas finding T1.
          throw FormatException(
            'Relay streaming buffered row cap exceeded '
            '(maxBufferedRows=$cap, currentRows=${rows.length})',
          );
        }
        final cols = chunk['column_metadata'];
        if (cols is List && columnMetadata == null) {
          columnMetadata = List<Object?>.from(cols);
        }
        continue;
      }

      if (!_isCompletePayload(chunk)) {
        throw const FormatException(
          'Relay streaming item is neither row chunk nor complete payload',
        );
      }

      final terminalStatus = _readString(
        chunk,
        'terminal_status',
        'terminalStatus',
      );
      if (terminalStatus != null && !_isHealthyTerminal(terminalStatus)) {
        throw FormatException(
          'Relay streaming complete terminal_status=$terminalStatus',
        );
      }

      sawComplete = true;
      final maybeTotalRows = _readNum(chunk, 'total_rows', 'totalRows');
      if (maybeTotalRows != null) {
        totalRowsFromComplete = maybeTotalRows.toInt();
      }
      final maybeAffected = _readNum(chunk, 'affected_rows', 'affectedRows');
      if (maybeAffected != null) {
        affectedRows = maybeAffected.toInt();
      }
      executionId ??= _readString(chunk, 'execution_id', 'executionId');
      startedAt ??= _readString(chunk, 'started_at', 'startedAt');
      finishedAt ??= _readString(chunk, 'finished_at', 'finishedAt');
    }

    if (!sawItem) {
      throw const FormatException('Relay streaming response was empty');
    }
    if (!sawComplete) {
      final reason = sawChunk ? 'missing complete payload' : 'no result';
      throw FormatException('Relay streaming response incomplete: $reason');
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
        'success': true,
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

bool _isCompletePayload(Map<String, dynamic> chunk) {
  const keys = <String>{
    'total_rows',
    'totalRows',
    'affected_rows',
    'affectedRows',
    'execution_id',
    'executionId',
    'started_at',
    'startedAt',
    'finished_at',
    'finishedAt',
    'terminal_status',
    'terminalStatus',
  };
  return keys.any(chunk.containsKey);
}

bool _isHealthyTerminal(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'completed' || normalized == 'success';
}

String? _readString(Map<String, dynamic> map, String first, String second) {
  final value = map[first] ?? map[second];
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

num? _readNum(Map<String, dynamic> map, String first, String second) {
  final value = map[first] ?? map[second];
  return value is num ? value : null;
}
