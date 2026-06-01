import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';

const int _agentQueryDiagnosticFieldMaxChars = 512;
const int _agentQueryDiagnosticBodyMaxChars = 8192;

/// Plain-text diagnostic for support / clipboard (no stack traces).
///
/// Includes wire [AppFailure.message], optional [AppFailure.userMessage] from
/// the hub, transport context and RPC metadata — not localized copy.
String agentQueryFailureDiagnosticBody(AppFailure failure) {
  final lines = <String>[
    'failureType: ${failure.runtimeType}',
    'message: ${failure.message}',
  ];

  final userMessage = failure.userMessage?.trim();
  if (userMessage != null && userMessage.isNotEmpty) {
    lines.add('userMessage: $userMessage');
  }

  final retryAfter = appFailureRetryAfter(failure);
  if (retryAfter != null) {
    lines.add('retryAfterSeconds: ${retryAfter.inSeconds}');
  }

  if (failure is RpcFailure) {
    lines
      ..add('rpcCode: ${failure.rpcCode}')
      ..add('reason: ${_truncateDiagnosticField(failure.reason)}')
      ..add('correlationId: ${_truncateDiagnosticField(failure.correlationId)}')
      ..add('retryable: ${failure.retryable}');
    final technical = failure.technicalMessage?.trim();
    if (technical != null &&
        technical.isNotEmpty &&
        technical != failure.message.trim()) {
      lines.add('technicalMessage: ${_truncateDiagnosticField(technical)}');
    }
  }

  final contextLines = _formatContextLines(failure.context);
  if (contextLines.isNotEmpty) {
    lines
      ..add('context:')
      ..addAll(contextLines.map((line) => '  $line'));
  }

  var body = lines.join('\n');
  if (body.length > _agentQueryDiagnosticBodyMaxChars) {
    body =
        '${body.substring(0, _agentQueryDiagnosticBodyMaxChars)}…(truncated)';
  }
  return body;
}

List<String> _formatContextLines(Map<String, Object?> context) {
  if (context.isEmpty) {
    return const <String>[];
  }
  final keys = context.keys.toList()..sort();
  final lines = <String>[];
  for (final key in keys) {
    if (key == AgentSqlRpcFailureUiKey.errorDataField) {
      continue;
    }
    final value = context[key];
    if (value == null) {
      continue;
    }
    lines.add('$key: ${_truncateDiagnosticField(value.toString())}');
  }
  return lines;
}

/// Truncates a single diagnostic field for UI / one-line summaries.
String truncateAgentQueryDiagnosticField(String? value) {
  return _truncateDiagnosticField(value);
}

String _truncateDiagnosticField(String? value) {
  if (value == null || value.isEmpty) {
    return '';
  }
  final trimmed = value.trim();
  if (trimmed.length <= _agentQueryDiagnosticFieldMaxChars) {
    return trimmed;
  }
  return '${trimmed.substring(0, _agentQueryDiagnosticFieldMaxChars)}…'
      '(${trimmed.length} chars)';
}

/// Short diagnostic for "copy summary" (type, message, key RPC ids).
String agentQueryFailureDiagnosticSummary(AppFailure failure) {
  final lines = <String>[
    'failureType: ${failure.runtimeType}',
    'message: ${failure.message}',
  ];
  if (failure is RpcFailure) {
    lines
      ..add('rpcCode: ${failure.rpcCode}')
      ..add('reason: ${truncateAgentQueryDiagnosticField(failure.reason)}')
      ..add(
        'correlationId: ${truncateAgentQueryDiagnosticField(failure.correlationId)}',
      );
  }
  return lines.join('\n');
}

/// Overview load banner: friendly line first, then wire diagnostic block.
String overviewAppFailureDiagnosticBody(
  AppFailure failure, {
  String? localizedUserMessage,
}) {
  final friendly = localizedUserMessage?.trim();
  final technical = agentQueryFailureDiagnosticBody(failure);
  if (friendly == null || friendly.isEmpty) {
    return technical;
  }
  return <String>[
    'userFacingMessage: $friendly',
    ...technical.split('\n'),
  ].join('\n');
}
