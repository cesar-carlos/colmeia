import 'dart:io';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'e2e_refreshing_auth_interceptor.dart';
import 'e2e_stub_client_agents_for_agent_queries.dart';

/// Prints once per VM so skipped E2E tests still show which agent id is configured.
bool _e2eAnnouncedConfiguredAgentId = false;

/// Loads bundled env and registers `Dio` plus the agent-queries stack only.
///
/// Avoids full app DI setup so VM tests do not need `path_provider` / Hive
/// (plugins unavailable in `flutter test` without a device).
///
/// When `AppEnvironment.hasE2eClientLoginCredentials` is true, performs
/// `POST /client-auth/login` with a separate `Dio`, then attaches
/// [E2eRefreshingAuthInterceptor] on the shared `Dio` used for `sql.execute`
/// so access tokens are refreshed before expiry and on HTTP 401 (short-lived
/// JWTs, e.g. ~15 minutes, matching production proactive refresh + 401 retry).
Future<void> e2eSetupDependencies() async {
  primeE2eEnvironment();
  if (AppEnvironment.useFakeBackend) {
    throw StateError(
      'E2E agent SQL requires USE_FAKE_BACKEND=false '
      '(see bundled default.env).',
    );
  }
  if (AppEnvironment.apiBaseUrl.isEmpty) {
    throw StateError(
      'E2E requires API_BASE_URL (dart-define or bundled default.env).',
    );
  }
  await resetDependenciesForTesting();

  final dio = AppDioClient.create();

  if (AppEnvironment.hasE2eClientLoginCredentials) {
    final loginDio = Dio(AppDioClient.createBaseOptions());
    final authRemote = ApiAuthRemoteDataSource(loginDio);
    final session = await authRemote.login(
      email: AppEnvironment.e2eClientEmail,
      password: AppEnvironment.e2eClientPassword,
    );
    final sessionHolder = E2eAuthSessionHolder()..value = session;
    dio.interceptors.add(
      E2eRefreshingAuthInterceptor(
        dio: dio,
        refreshAuthApi: authRemote,
        sessionHolder: sessionHolder,
      ),
    );
  }

  getIt
    ..registerSingleton<Dio>(dio)
    ..registerSingleton<ClientAgentsRepository>(
      E2eStubClientAgentsRepository(),
    )
    ..registerSingleton<AgentClientTokenReader>(
      E2eStubAgentClientTokenReader(),
    );
  registerInjectorAgentQueries(getIt);

  // Visible in `flutter test` stdout so runs clearly target this agent for sql.execute.
  // E2E_CLIENT_TOKEN is not printed (secret); only whether it was loaded from env.
  // ignore: avoid_print
  print(
    'E2E agent-queries: E2E_AGENT_ID=${AppEnvironment.e2eAgentId} '
    'client_token_loaded=${AppEnvironment.e2eClientToken.isNotEmpty} '
    'api=${AppEnvironment.apiBaseUrl} '
    'bearer=${AppEnvironment.hasE2eClientLoginCredentials}',
  );
}

List<String> missingE2eBridgeKeys() {
  primeE2eEnvironment();
  final missing = <String>[];
  if (AppEnvironment.e2eAgentId.isEmpty) {
    missing.add(EnvKeys.e2eAgentId);
  }
  if (AppEnvironment.e2eClientToken.isEmpty) {
    missing.add(EnvKeys.e2eClientToken);
  }
  return missing;
}

List<String> missingE2eRepositoryKeys() {
  final missing = missingE2eBridgeKeys();
  if (AppEnvironment.e2eClientEmail.isEmpty) {
    missing.add(EnvKeys.e2eClientEmail);
  }
  if (AppEnvironment.e2eClientPassword.isEmpty) {
    missing.add(EnvKeys.e2eClientPassword);
  }
  if (!_e2eAnnouncedConfiguredAgentId &&
      missing.isNotEmpty &&
      AppEnvironment.e2eAgentId.isNotEmpty) {
    _e2eAnnouncedConfiguredAgentId = true;
    // E2E hint: agent id is loaded from env even when login or token keys block the run.
    // ignore: avoid_print
    print(
      'E2E: E2E_AGENT_ID=${AppEnvironment.e2eAgentId} '
      '(sql.execute will target this agent once all required E2E_* vars are set).',
    );
  }
  return missing;
}

Future<void> e2eTeardownDependencies() async {
  await resetDependenciesForTesting();
}

bool isKnownInvalidPolicyFailure(AppFailure failure) {
  if (failure is! RpcFailure) {
    return false;
  }

  final errorData = failure.context[AgentSqlRpcFailureUiKey.errorDataField];
  final odbcReason = switch (errorData) {
    Map<Object?, Object?>() =>
      errorData['odbc_reason']?.toString().trim().toLowerCase(),
    _ => null,
  };

  return failure.rpcCode == -32002 &&
      failure.reason == 'unauthorized' &&
      failure.category == 'auth' &&
      failure.context[AgentSqlRpcFailureUiKey.field] ==
          AgentSqlRpcFailureUiKey.sqlValidationFailed &&
      odbcReason == 'invalid_policy';
}

bool isTransientAgentSqlBridgeHttpFailure(AppFailure failure) {
  final cause = failure.cause;
  if (cause is! DioException) {
    return false;
  }
  final statusCode = cause.response?.statusCode;
  if (statusCode != null) {
    return statusCode >= 500 && statusCode < 600;
  }
  return switch (cause.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}

String? _agentSqlOdbcReason(AppFailure failure) {
  if (failure is! RpcFailure) {
    return null;
  }
  final errorData = failure.context[AgentSqlRpcFailureUiKey.errorDataField];
  return switch (errorData) {
    Map<Object?, Object?>() =>
      errorData['odbc_reason']?.toString().trim().toLowerCase(),
    _ => null,
  };
}

/// Client lacks bridge permission for a table touched by the SQL (E2E env).
bool isKnownAgentSqlMissingPermissionFailure(AppFailure failure) {
  if (failure is! RpcFailure) {
    return false;
  }
  if (failure.rpcCode != -32002 ||
      failure.reason != 'unauthorized' ||
      failure.category != 'auth') {
    return false;
  }
  if (failure.context[AgentSqlRpcFailureUiKey.field] !=
      AgentSqlRpcFailureUiKey.permissionDenied) {
    return false;
  }
  return _agentSqlOdbcReason(failure) == 'missing_permission';
}

/// Hub or bridge denied the call with HTTP 403 (e.g. client token cannot use
/// this agent). Same e2e run may hit this when credentials lack hub access.
bool isKnownE2eAgentSqlHttpForbiddenFailure(AppFailure failure) {
  if (failure is! AuthorizationFailure) {
    return false;
  }
  return failure.context['operation'] == 'executeAgentSql';
}

/// Some bridge runtimes cap named bind parameters (e.g. 5). Queries that add
/// optional dimension binds can exceed that until repositories split SQL like
/// `resumoParcelasMensal`.
bool isKnownE2eAgentSqlBridgeNamedParameterLimitFailure(AppFailure failure) {
  if (failure is! RpcFailure) {
    return false;
  }
  if (failure.rpcCode != -32602 || failure.reason != 'invalid_params') {
    return false;
  }
  final tech = failure.technicalMessage?.trim().toLowerCase() ?? '';
  if (tech.contains('named parameters') && tech.contains('supports up to')) {
    return true;
  }
  final errorData = failure.context[AgentSqlRpcFailureUiKey.errorDataField];
  if (errorData is Map) {
    final detail = errorData['detail']?.toString().toLowerCase() ?? '';
    if (detail.contains('named parameters') &&
        detail.contains('supports up to')) {
      return true;
    }
  }
  return false;
}

/// Bridge/agent queue saturated: request never reached workers (`retryable` is
/// often false but the condition is still environmental for E2E smoke runs).
bool isKnownE2eAgentSqlQueueSaturationFailure(AppFailure failure) {
  if (failure is! RpcFailure) {
    return false;
  }
  if (failure.reason != 'sql_execution_failed' || failure.category != 'sql') {
    return false;
  }
  final odbc = _agentSqlOdbcReason(failure);
  if (odbc == 'queue_wait_timeout') {
    return true;
  }
  final tech = failure.technicalMessage?.toLowerCase() ?? '';
  if (tech.contains('waiting in queue') ||
      (tech.contains('queue') && tech.contains('timeout'))) {
    return true;
  }
  final errorData = failure.context[AgentSqlRpcFailureUiKey.errorDataField];
  if (errorData is Map) {
    final detail = errorData['detail']?.toString().toLowerCase() ?? '';
    if (detail.contains('waiting in queue')) {
      return true;
    }
  }
  return false;
}

/// Known policy rejection, missing table permission RPC, transient bridge
/// HTTP 5xx, or HTTP 403 forbidden on agent SQL (environment / hub access).
bool isAcceptableE2eAgentSqlRepositoryFailure(AppFailure failure) {
  return isKnownInvalidPolicyFailure(failure) ||
      isKnownAgentSqlMissingPermissionFailure(failure) ||
      isTransientAgentSqlBridgeHttpFailure(failure) ||
      isKnownE2eAgentSqlHttpForbiddenFailure(failure) ||
      isKnownE2eAgentSqlBridgeNamedParameterLimitFailure(failure) ||
      isKnownE2eAgentSqlQueueSaturationFailure(failure);
}

void primeE2eEnvironment() {
  final defaultContent = _readRequiredEnvFile(EnvAssetPaths.bundledDefault);
  final localContent = _readOptionalEnvFile(EnvAssetPaths.bundledLocal);
  dotenv.loadFromString(
    envString: defaultContent,
    overrideWith: localContent == null ? const [] : [localContent],
    mergeWith: _processEnvironmentOverrides(),
  );
}

Map<String, String> _processEnvironmentOverrides() {
  final names = <String>[
    EnvKeys.apiBaseUrl,
    EnvKeys.useFakeBackend,
    EnvKeys.e2eAgentId,
    EnvKeys.e2eClientToken,
    EnvKeys.e2eClientEmail,
    EnvKeys.e2eClientPassword,
  ];
  final overrides = <String, String>{};
  for (final name in names) {
    final value = Platform.environment[name]?.trim();
    if (value != null && value.isNotEmpty) {
      overrides[name] = value;
    }
  }
  return overrides;
}

String _readRequiredEnvFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Missing required env file: $path');
  }
  return file.readAsStringSync();
}

String? _readOptionalEnvFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsStringSync();
}
