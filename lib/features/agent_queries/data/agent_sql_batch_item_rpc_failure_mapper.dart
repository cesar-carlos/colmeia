import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_rpc_user_message_resolver.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';

/// Builds an [RpcFailure] from a failed [AgentSqlBatchExecutionItem], preserving
/// JSON-RPC code/reason/retry hints when the bridge returns a structured error.
abstract final class AgentSqlBatchItemRpcFailureMapper {
  static RpcFailure missingItem({
    required int index,
    required String operation,
  }) {
    return RpcFailure(
      message: 'sql.executeBatch item $index is missing',
      userMessage: 'Nao foi possivel carregar esta consulta.',
      rpcCode: null,
      retryable: false,
      reason: 'missing_batch_item',
      context: <String, Object?>{
        'operation': operation,
        'batchItemIndex': index,
      },
    );
  }

  static RpcFailure fromFailedItem({
    required AgentSqlBatchExecutionItem item,
    required String operation,
  }) {
    final details = _readErrorDetails(item);
    if (details != null) {
      final resolution = resolveAgentSqlRpcUserMessage(details);
      final failureContext = <String, Object?>{
        'operation': operation,
        'batchItemIndex': item.index,
        'rpcCode': details.code,
        'reason': details.reason,
        'category': details.category,
        'correlationId': details.correlationId,
      };
      if (resolution.uiKey != null) {
        failureContext[AgentSqlRpcFailureUiKey.field] = resolution.uiKey;
      }
      if (resolution.preferBridgeUserMessage) {
        failureContext[AgentSqlRpcFailureUiKey.preferBridgeUserMessageField] =
            true;
      }
      final errorData = details.errorData;
      if (errorData != null) {
        failureContext[AgentSqlRpcFailureUiKey.errorDataField] = errorData;
      }
      final isRateLimited =
          details.code == -32013 ||
          resolution.uiKey == AgentSqlRpcFailureUiKey.rateLimited;
      return RpcFailure(
        message: details.message,
        userMessage: resolution.userMessage,
        rpcCode: details.code,
        retryable: isRateLimited || details.retryable,
        reason: details.reason,
        category: details.category,
        technicalMessage: details.technicalMessage,
        correlationId: details.correlationId,
        timestamp: details.timestamp,
        retryAfter: _readRetryAfterFromErrorData(errorData),
        context: failureContext,
      );
    }

    final message = item.error ?? 'sql.executeBatch item failed';
    return RpcFailure(
      message: message,
      userMessage: message,
      rpcCode: null,
      retryable: false,
      reason: 'batch_item_failed',
      context: <String, Object?>{
        'operation': operation,
        'batchItemIndex': item.index,
      },
    );
  }

  static AgentSqlRpcErrorDetails? _readErrorDetails(
    AgentSqlBatchExecutionItem item,
  ) {
    final payload = item.errorPayload;
    if (payload == null || payload.isEmpty) {
      return null;
    }
    final data = payload['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
    final errorDataPayload = dataMap != null && dataMap.isNotEmpty
        ? Map<String, dynamic>.unmodifiable(Map<String, dynamic>.from(dataMap))
        : null;
    final userMessage =
        _readNonEmptyString(
          dataMap,
          const <String>['user_message', 'userMessage'],
        ) ??
        _readNonEmptyString(payload, const <String>['message']) ??
        item.error ??
        'sql.executeBatch item failed';
    final message =
        _readNonEmptyString(payload, const <String>['message']) ?? userMessage;

    return AgentSqlRpcErrorDetails(
      userMessage: userMessage,
      message: message,
      code: _readInt(payload['code']),
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
      errorData: errorDataPayload,
    );
  }

  static Duration? _readRetryAfterFromErrorData(Map<String, dynamic>? errorData) {
    if (errorData == null || errorData.isEmpty) {
      return null;
    }
    final ms = errorData['retry_after_ms'] ?? errorData['retryAfterMs'];
    final fromMs = _durationFromMs(ms);
    if (fromMs != null) {
      return fromMs;
    }
    final resetAt = errorData['reset_at'] ?? errorData['resetAt'];
    if (resetAt is String) {
      final parsed = DateTime.tryParse(resetAt);
      if (parsed != null) {
        final delta = parsed.toUtc().difference(DateTime.now().toUtc());
        if (delta.isNegative) {
          return Duration.zero;
        }
        return delta;
      }
    }
    return null;
  }

  static Duration? _durationFromMs(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      final ms = raw.toInt();
      if (ms < 0) {
        return Duration.zero;
      }
      return Duration(milliseconds: ms);
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null) {
        return null;
      }
      if (parsed < 0) {
        return Duration.zero;
      }
      return Duration(milliseconds: parsed);
    }
    return null;
  }

  static String? _readNonEmptyString(
    Map<String, dynamic>? map,
    List<String> keys,
  ) {
    if (map == null) {
      return null;
    }
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
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
}
