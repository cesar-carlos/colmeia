import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:flutter/foundation.dart';

const int _kDebugStackTraceMaxChars = 4096;

/// Plain-text bundle for clipboard / share (environment + diagnostic).
String formatAgentQueryFailureClipboard({
  required String diagnosticBody,
  AgentQueryFailureSupportContext? supportContext,
  AppFailure? failure,
}) {
  final lines = <String>[
    '--- Colmeia support bundle ---',
    'capturedAt: ${DateTime.now().toUtc().toIso8601String()}',
  ];

  final context = supportContext;
  if (context != null && context.lines.isNotEmpty) {
    final sortedKeys = context.lines.keys.toList()..sort();
    for (final key in sortedKeys) {
      final value = context.lines[key]?.trim();
      if (value != null && value.isNotEmpty) {
        lines.add('$key: $value');
      }
    }
  }

  lines
    ..add('--- diagnostic ---')
    ..add(diagnosticBody.trim());

  if (kDebugMode && failure?.stackTrace != null) {
    lines
      ..add('--- stackTrace (debug build only) ---')
      ..add(_truncateDebugStackTrace(failure!.stackTrace!));
  }

  return lines.join('\n');
}

String _truncateDebugStackTrace(StackTrace stackTrace) {
  final text = stackTrace.toString().trim();
  if (text.length <= _kDebugStackTraceMaxChars) {
    return text;
  }
  return '${text.substring(0, _kDebugStackTraceMaxChars)}…(truncated)';
}
