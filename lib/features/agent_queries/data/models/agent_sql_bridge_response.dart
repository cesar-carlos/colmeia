import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_pagination_result.dart';

/// Matches `agentSqlErrorGeneric` in `lib/l10n/app_en.arb` (keep in sync).
const String _kAgentSqlRpcGenericUserMessageEn =
    'The query could not be completed on the agent.';

class AgentSqlRpcErrorDetails {
  const AgentSqlRpcErrorDetails({
    required this.userMessage,
    required this.message,
    this.code,
    this.reason,
    this.category,
    this.retryable = false,
    this.technicalMessage,
    this.correlationId,
    this.timestamp,
    this.errorData,
  });

  final String userMessage;
  final String message;
  final int? code;
  final String? reason;
  final String? category;
  final bool retryable;
  final String? technicalMessage;
  final String? correlationId;
  final DateTime? timestamp;

  /// Unmodifiable copy of JSON-RPC `error.data` when present.
  final Map<String, dynamic>? errorData;
}

/// Thrown when the hub returns HTTP 200 but the bridge reports an RPC failure
/// (`response.success == false`).
final class AgentSqlRpcException implements Exception {
  AgentSqlRpcException(this.details);

  final AgentSqlRpcErrorDetails details;

  @override
  String toString() => details.userMessage;
}

/// Parses the JSON body of `POST /agents/commands` for a single `sql.execute`.
abstract final class AgentSqlBridgeResponse {
  static AgentSqlExecutionResult parseSuccess(Map<String, dynamic> json) {
    final response = json['response'];
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Bridge response missing "response" object');
    }

    if (response['success'] != true) {
      throw AgentSqlRpcException(_readRpcErrorDetails(response));
    }

    final item = response['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Bridge response missing "item" object');
    }

    if (item['success'] != true) {
      throw AgentSqlRpcException(_readItemErrorDetails(item));
    }

    final result = item['result'];
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Bridge item missing "result" object');
    }

    final rawRows = result['rows'];
    final rows = <Map<String, dynamic>>[];
    if (rawRows is List<dynamic>) {
      for (final row in rawRows) {
        if (row is Map<String, dynamic>) {
          rows.add(row);
        } else if (row is Map) {
          rows.add(Map<String, dynamic>.from(row));
        }
      }
    }

    final rowCount = _readInt(result['row_count']) ?? rows.length;
    final executionId = result['execution_id']?.toString();
    final affectedRows = _readInt(result['affected_rows']);
    final pagination = _parsePagination(result['pagination']);

    return AgentSqlExecutionResult(
      rows: rows,
      rowCount: rowCount,
      executionId: executionId,
      affectedRows: affectedRows,
      pagination: pagination,
    );
  }

  static AgentSqlBatchExecutionResult parseBatchSuccess(
    Map<String, dynamic> json,
  ) {
    final response = json['response'];
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Bridge response missing "response" object');
    }

    if (response['success'] != true) {
      throw AgentSqlRpcException(_readRpcErrorDetails(response));
    }

    final item = response['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Bridge response missing "item" object');
    }

    if (item['success'] != true) {
      throw AgentSqlRpcException(_readItemErrorDetails(item));
    }

    final result = item['result'];
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Bridge item missing "result" object');
    }

    final rawItems = result['items'];
    if (rawItems is! List<dynamic>) {
      throw const FormatException('Batch result missing "items" array');
    }

    final items = <AgentSqlBatchExecutionItem>[
      for (final rawItem in rawItems) _parseBatchItem(rawItem),
    ];
    final derivedSuccessfulCommands = items.where((item) => item.ok).length;
    final derivedFailedCommands = items.length - derivedSuccessfulCommands;

    return AgentSqlBatchExecutionResult(
      executionId: result['execution_id']?.toString(),
      totalCommands: _readInt(result['total_commands']) ?? rawItems.length,
      successfulCommands:
          _readInt(result['successful_commands']) ?? derivedSuccessfulCommands,
      failedCommands:
          _readInt(result['failed_commands']) ?? derivedFailedCommands,
      items: items,
    );
  }

  static AgentSqlBatchExecutionItem _parseBatchItem(Object? rawItem) {
    if (rawItem is! Map) {
      throw const FormatException('Batch item must be an object');
    }
    final item = Map<String, dynamic>.from(rawItem);
    final rawRows = item['rows'];
    final rows = <Map<String, dynamic>>[];
    if (rawRows is List<dynamic>) {
      for (final row in rawRows) {
        if (row is Map<String, dynamic>) {
          rows.add(row);
        } else if (row is Map) {
          rows.add(Map<String, dynamic>.from(row));
        }
      }
    }

    final rawMetadata = item['column_metadata'];
    final metadata = <Map<String, dynamic>>[];
    if (rawMetadata is List<dynamic>) {
      for (final column in rawMetadata) {
        if (column is Map<String, dynamic>) {
          metadata.add(column);
        } else if (column is Map) {
          metadata.add(Map<String, dynamic>.from(column));
        }
      }
    }

    return AgentSqlBatchExecutionItem(
      index: _readInt(item['index']) ?? 0,
      ok: item['ok'] == true,
      rows: rows,
      rowCount: _readInt(item['row_count']) ?? rows.length,
      affectedRows: _readInt(item['affected_rows']),
      error: item['error']?.toString(),
      columnMetadata: metadata,
    );
  }

  static AgentSqlPaginationResult? _parsePagination(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    bool? readBool(String a, String b) {
      final v = map[a] ?? map[b];
      if (v is bool) {
        return v;
      }
      return null;
    }

    String? readString(String a, String b) {
      final v = map[a] ?? map[b];
      if (v is String && v.isNotEmpty) {
        return v;
      }
      return null;
    }

    final parsed = AgentSqlPaginationResult(
      page: _readInt(map['page']),
      pageSize: _readInt(map['page_size'] ?? map['pageSize']),
      returnedRows: _readInt(map['returned_rows'] ?? map['returnedRows']),
      hasNextPage: readBool('has_next_page', 'hasNextPage'),
      hasPreviousPage: readBool('has_previous_page', 'hasPreviousPage'),
      currentCursor: readString('current_cursor', 'currentCursor'),
      nextCursor: readString('next_cursor', 'nextCursor'),
    );
    if (parsed.page == null &&
        parsed.pageSize == null &&
        parsed.returnedRows == null &&
        parsed.hasNextPage == null &&
        parsed.hasPreviousPage == null &&
        parsed.currentCursor == null &&
        parsed.nextCursor == null) {
      return null;
    }
    return parsed;
  }

  static AgentSqlRpcErrorDetails _readRpcErrorDetails(
    Map<String, dynamic> response,
  ) {
    final item = response['item'];
    if (item is Map<String, dynamic>) {
      return _readItemErrorDetails(item);
    }
    return const AgentSqlRpcErrorDetails(
      userMessage: _kAgentSqlRpcGenericUserMessageEn,
      message: 'Agent SQL RPC failed without item payload',
    );
  }

  static AgentSqlRpcErrorDetails _readItemErrorDetails(
    Map<String, dynamic> item,
  ) {
    final error = item['error'];
    if (error is! Map) {
      return const AgentSqlRpcErrorDetails(
        userMessage: _kAgentSqlRpcGenericUserMessageEn,
        message: 'Agent SQL RPC failed without error payload',
      );
    }
    final errorMap = Map<String, dynamic>.from(error);
    final data = errorMap['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
    final errorDataPayload = dataMap != null && dataMap.isNotEmpty
        ? Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(dataMap),
          )
        : null;
    final userMessage =
        _readNonEmptyString(
          dataMap,
          const <String>['user_message', 'userMessage'],
        ) ??
        _readNonEmptyString(errorMap, const <String>['message']) ??
        _kAgentSqlRpcGenericUserMessageEn;
    final message =
        _readNonEmptyString(errorMap, const <String>['message']) ?? userMessage;

    return AgentSqlRpcErrorDetails(
      userMessage: userMessage,
      message: message,
      code: _readInt(errorMap['code']),
      reason: _readNonEmptyString(dataMap, const <String>['reason']),
      category: _readNonEmptyString(dataMap, const <String>['category']),
      retryable: _readBool(dataMap, const <String>['retryable']) ?? false,
      technicalMessage: _readNonEmptyString(
        dataMap,
        const <String>['technical_message', 'technicalMessage'],
      ),
      correlationId: _readNonEmptyString(
        dataMap,
        const <String>['correlation_id', 'correlationId'],
      ),
      timestamp: _readDateTime(
        _readNonEmptyString(dataMap, const <String>['timestamp']),
      ),
      errorData: errorDataPayload,
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) {
      return null;
    }
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
    }
    return null;
  }

  static String? _readNonEmptyString(
    Map<String, dynamic>? json,
    List<String> keys,
  ) {
    if (json == null) {
      return null;
    }
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static DateTime? _readDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
