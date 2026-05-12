import 'package:colmeia/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_dependency_bootstrap.dart';
export 'e2e_dependency_bootstrap.dart'
    show
        registerE2eAgentQueriesSuiteHooks,
        runE2eAppResult,
        runE2eAppResultWithHubRetry;

const String _sessionFailureReason =
    'Unexpected HTTP 401 after client login '
    '— check E2E_* values.';

const String _acceptableFailureSuffix =
    'should return rows, invalid_policy / '
    'missing_permission RPC, transient bridge HTTP 5xx / socket / relay '
    'transport overload, or circuit breaker open.';

bool shouldSkipE2eRepositoryTest(String testLabel) {
  final missingKeys = missingE2eRepositoryKeys();
  if (missingKeys.isEmpty) {
    return false;
  }

  // E2E skip hint; `print` is intentional for local diagnostics.
  // ignore: avoid_print
  print(
    'SKIP $testLabel: missing ${missingKeys.join(', ')}. '
    'Set them in assets/env/local.env, process env, or --dart-define.',
  );
  return true;
}

/// Prefer [registerE2eAgentQueriesSuiteHooks] on the enclosing [group] so the
/// suite logs in once; keep this for one-off tests outside a shared group.
Future<void> setupE2eDependenciesWithTearDown() async {
  await e2eSetupDependencies();
  addTearDown(e2eTeardownDependencies);
}

void expectAcceptableAgentQueriesE2eFailure(
  AppFailure failure, {
  required String failureScope,
}) {
  expect(
    failure,
    isNot(isA<SessionFailure>()),
    reason: _sessionFailureReason,
  );
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason: '$failureScope $_acceptableFailureSuffix',
  );
}
