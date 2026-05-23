import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';

/// Top-level entry for [compute] — unary bridge success parse.
AgentSqlExecutionResult agentSqlBridgeResponseParseSuccessIsolate(
  Map<String, dynamic> json,
) {
  return AgentSqlBridgeResponse.parseSuccess(json);
}

/// Top-level entry for [compute] — batch bridge success parse.
AgentSqlBatchExecutionResult agentSqlBridgeResponseParseBatchSuccessIsolate(
  Map<String, dynamic> json,
) {
  return AgentSqlBridgeResponse.parseBatchSuccess(json);
}

/// Estimates row volume before a full parse (used for isolate threshold).
int agentSqlBridgeResponseEstimateRowCount(Map<String, dynamic> json) {
  final response = json['response'];
  if (response is! Map) {
    return 0;
  }
  final item = response['item'];
  if (item is! Map) {
    return 0;
  }
  final result = item['result'];
  if (result is! Map) {
    return 0;
  }

  final rawItems = result['items'];
  if (rawItems is List) {
    var total = 0;
    for (final rawItem in rawItems) {
      if (rawItem is Map) {
        final rows = rawItem['rows'];
        if (rows is List) {
          total += rows.length;
        }
      }
    }
    return total;
  }

  final rawRows = result['rows'];
  if (rawRows is List) {
    return rawRows.length;
  }
  return 0;
}
