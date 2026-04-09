import 'dart:io';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads bundled env and registers `Dio` plus the agent-queries stack only.
///
/// Avoids full app DI setup so VM tests do not need `path_provider` / Hive
/// (plugins unavailable in `flutter test` without a device).
///
/// When `AppEnvironment.hasE2eClientLoginCredentials` is true, performs
/// `POST /client-auth/login` with a separate `Dio`, then attaches a lightweight
/// Bearer interceptor on the shared `Dio` used for `sql.execute` (same pattern
/// as production auth, without persistent session storage or refresh).
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
    _addBearerInterceptor(dio, session.accessToken);
  }

  getIt.registerSingleton<Dio>(dio);
  registerInjectorAgentQueries(getIt);
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
  return missing;
}

void _addBearerInterceptor(Dio dio, String accessToken) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        const header = 'Authorization';
        if (!options.headers.containsKey(header)) {
          options.headers[header] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
    ),
  );
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
