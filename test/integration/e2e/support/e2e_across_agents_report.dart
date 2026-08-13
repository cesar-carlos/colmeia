import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_transport_timeouts.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'e2e_agent_sql_cancel.dart';
import 'e2e_dependency_bootstrap.dart';

/// Single-report across-agents E2E timeout. Must stay well under the 5m e2e
/// tag so a hung agent SQL surfaces as a mapped transport failure, not a
/// package:test [TimeoutException].
const int e2eAcrossAgentsBridgeTimeoutMs = 90000;

/// Extra slack after bridge wait + transport receive buffer for the client
/// [Future.timeout] backstop in [runE2eAcrossAgentsResult].
const int e2eAcrossAgentsClientTimeoutSlackMs = 15000;

/// Client-side wait cap. Fires even if the socket/relay dispatcher timer
/// never completes the pending RPC.
const Duration e2eAcrossAgentsClientTimeout = Duration(
  milliseconds:
      e2eAcrossAgentsBridgeTimeoutMs +
      kAgentSqlTransportReceiveBufferMs +
      e2eAcrossAgentsClientTimeoutSlackMs,
);

const String e2eAcrossAgentsUserId = 'e2e-agent-query-user';

bool skipE2eWhenMissingRepositoryKeys(String testName) {
  final missingKeys = missingE2eRepositoryKeys();
  if (missingKeys.isEmpty) {
    return false;
  }
  // ignore: avoid_print -- E2E skip hints for local/CI diagnostics.
  print(
    'SKIP $testName: missing ${missingKeys.join(', ')}. '
    'Set them in assets/env/local.env, process env, or --dart-define.',
  );
  return true;
}

/// Short closed July window with known E2E-agent sales.
({DateTime start, DateTime end}) e2eKnownSalesPeriod() {
  return (start: DateTime(2026, 7, 10), end: DateTime(2026, 7, 11));
}

/// Wraps an across-agents use case so a hung dispatcher cannot burn the 5m
/// e2e tag. On client timeout, best-effort cancel abandoned SQL before
/// returning a transient [NetworkFailure].
Future<AppResult<T>> runE2eAcrossAgentsResult<T extends Object>(
  Future<AppResult<T>> Function() action, {
  String? actionLabel,
  Duration? clientTimeout,
}) async {
  final timeout = clientTimeout ?? e2eAcrossAgentsClientTimeout;
  try {
    return await runE2eAppResult(
      action,
      actionLabel: actionLabel,
    ).timeout(timeout);
  } on TimeoutException catch (e, st) {
    await e2eCancelAbandonedAgentSql();
    final suffix = actionLabel != null ? ' ($actionLabel)' : '';
    return Failure<T, AppFailure>(
      NetworkFailure(
        message:
            'E2E across-agents client timeout after ${timeout.inSeconds}s$suffix',
        userMessage: 'Agent SQL wait exceeded ${timeout.inSeconds}s',
        cause: SocketDispatchTimeout(
          message: e.message ?? 'across-agents client timeout',
        ),
        stackTrace: st,
      ),
    );
  }
}

void expectE2eAcrossAgentsReport<Row>(
  AppResult<AgentQueryExecutionReport<Row>> result,
  void Function(Row row) verifyRow,
) {
  result.fold(
    (report) => report.mergedRows.forEach(verifyRow),
    expectE2eAcrossAgentsAcceptableFailure,
  );
}

void expectE2eAcrossAgentsList<T>(
  AppResult<List<T>> result,
  void Function(T item) verifyItem,
) {
  result.fold(
    (items) => items.forEach(verifyItem),
    expectE2eAcrossAgentsAcceptableFailure,
  );
}

void expectE2eAcrossAgentsAcceptableFailure(AppFailure failure) {
  expect(
    failure,
    isNot(isA<SessionFailure>()),
    reason: 'Unexpected HTTP 401 after client login; check E2E_* values.',
  );
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason:
        'Across-agents e2e should return rows, invalid_policy / '
        'missing_permission RPC, transient transport, queue saturation, '
        'transient bridge HTTP 5xx, or cooperative cancel. '
        '${e2eAgentSqlFailureDiagnostic(failure)}',
  );
}
