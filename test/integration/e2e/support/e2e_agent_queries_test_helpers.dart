import 'package:colmeia/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_dependency_bootstrap.dart';

const String _sessionFailureReason =
    'Unexpected HTTP 401 after client login '
    '— check E2E_* values.';

const String _acceptableFailureSuffix =
    'should return rows, invalid_policy / '
    'missing_permission RPC, or transient bridge HTTP 5xx.';

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
