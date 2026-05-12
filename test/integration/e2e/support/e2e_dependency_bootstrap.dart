import 'dart:io';

import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/di/injector_socket.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/network/dio_transient_hub_error.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:result_dart/result_dart.dart';

import 'e2e_refreshing_auth_interceptor.dart';
import 'e2e_stub_client_agents_for_agent_queries.dart';

/// Prints once per VM so skipped E2E tests still show which agent id is configured.
bool _e2eAnnouncedConfiguredAgentId = false;

bool _e2eLogTransientHubErrors() {
  final raw = Platform.environment['E2E_LOG_TRANSIENT']?.toLowerCase().trim();
  return raw == '1' || raw == 'true' || raw == 'yes';
}

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

  // Full `flutter test` runs many E2E workers; each test calls setup and
  // `POST /client-auth/login` again. Hub 503 on login must reset DI and
  // retry — it is outside [runE2eAppResult], which only wraps repository calls.
  const maxSetupAttempts = 3;
  for (var setupAttempt = 0; setupAttempt < maxSetupAttempts; setupAttempt++) {
    if (setupAttempt > 0) {
      await Future<void>.delayed(
        Duration(milliseconds: 500 * setupAttempt),
      );
    }
    await resetDependenciesForTesting();
    try {
      await _e2eSetupDependenciesBody();
      return;
    } on DioException catch (e, st) {
      if (!isTransientHubDioException(e) ||
          setupAttempt == maxSetupAttempts - 1) {
        Error.throwWithStackTrace(e, st);
      }
    }
  }
  throw StateError('e2eSetupDependencies exhausted transient setup retries');
}

Future<void> _e2eSetupDependenciesBody() async {
  final dio = AppDioClient.create();
  final sessionHolder = E2eAuthSessionHolder();

  if (AppEnvironment.hasE2eClientLoginCredentials) {
    final loginDio = Dio(AppDioClient.createBaseOptions());
    final authRemote = ApiAuthRemoteDataSource(loginDio);
    final session = await _e2eClientLoginWithHubTransientRetries(
      authRemote,
      email: AppEnvironment.e2eClientEmail,
      password: AppEnvironment.e2eClientPassword,
    );
    sessionHolder.value = session;
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
  if (AppEnvironment.agentBridgeTransport == AgentBridgeTransport.socket) {
    _registerE2eSocketStack(sessionHolder);
  }
  registerInjectorAgentQueries(getIt);
  await _e2eWarmConsumerSocketAfterQueriesRegistered();

  // Visible in `flutter test` stdout so runs clearly target this agent for sql.execute.
  // E2E_CLIENT_TOKEN is not printed (secret); only whether it was loaded from env.
  // ignore: avoid_print
  print(
    'E2E agent-queries: E2E_AGENT_ID=${AppEnvironment.e2eAgentId} '
    'client_token_loaded=${AppEnvironment.e2eClientToken.isNotEmpty} '
    'api=${AppEnvironment.apiBaseUrl} '
    'bearer=${AppEnvironment.hasE2eClientLoginCredentials} '
    'transport=${AppEnvironment.agentBridgeTransport.name} '
    'relay_dispatch_disabled=${AppEnvironment.e2eDisableRelayDispatch}',
  );
}

void _registerE2eSocketStack(E2eAuthSessionHolder sessionHolder) {
  final sessionEvents = AuthSessionEvents();
  final sessionAccessor = _E2eAuthSessionAccessor(sessionHolder);
  getIt
    ..registerSingleton<AuthSessionEvents>(
      sessionEvents,
      dispose: (events) => events.dispose(),
    )
    ..registerSingleton<AuthSessionAccessor>(sessionAccessor)
    ..registerSingleton<AuthRefreshCoordinator>(
      AuthRefreshCoordinator(
        refreshDio: Dio(AppDioClient.createBaseOptions()),
        sessionAccessor: sessionAccessor,
        sessionEvents: sessionEvents,
      ),
    );
  registerInjectorSocket(getIt);
}

/// Mirrors the app post-login consumer-socket warm-up when
/// [AppEnvironment.socketWarmUpAfterLogin] is true (default): connects once
/// so the first repository call does not pay handshake alone.
Future<void> _e2eWarmConsumerSocketAfterQueriesRegistered() async {
  if (AppEnvironment.agentBridgeTransport != AgentBridgeTransport.socket) {
    return;
  }
  if (!AppEnvironment.socketWarmUpAfterLogin) {
    return;
  }
  if (!getIt.isRegistered<ConsumerSocketConnection>()) {
    return;
  }
  const maxAttempts = 3;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }
    try {
      await getIt<ConsumerSocketConnection>().connect();
      return;
      // ConsumerSocketConnection uses StateError with stable message prefixes
      // for connect outcomes (see consumer_socket_connection.dart).
      // ignore: avoid_catching_errors
    } on StateError catch (e, st) {
      final msg = e.message;
      if (msg.startsWith('Consumer socket namespace forbidden:') ||
          msg.startsWith('Consumer socket unauthorized:')) {
        Error.throwWithStackTrace(e, st);
      }
      final retryable =
          msg.startsWith('Consumer socket connect cancelled:') ||
          msg.startsWith('Consumer socket reconnect exhausted:');
      if (!retryable || attempt == maxAttempts - 1) {
        Error.throwWithStackTrace(e, st);
      }
    }
  }
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
  return isTransientHubDioException(cause);
}

bool _e2eIsTransientHubOverloadAppErrorCode(String code) {
  switch (code.toUpperCase()) {
    case 'SERVICE_UNAVAILABLE':
    case 'OVERLOADED':
    case 'HUB_OVERLOAD':
    case 'RATE_LIMITED':
    case 'TEMPORARILY_UNAVAILABLE':
      return true;
    default:
      return false;
  }
}

/// True for hub overload / transport blips on **either** REST (503 / timeouts
/// on the underlying [DioException]) **or** socket/relay paths where the
/// repository surfaced a [NetworkFailure] whose [AppFailure.cause] is a
/// dispatch exception (timeouts, disconnect, `app:error` overload codes).
///
/// Used by [runE2eAppResultWithHubRetry] and [isAcceptableE2eAgentSqlRepositoryFailure].
/// See also [isTransientAgentSqlBridgeHttpFailure] (HTTP-only subset).
bool isTransientE2eAgentSqlBridgeTransportFailure(AppFailure failure) {
  if (isTransientAgentSqlBridgeHttpFailure(failure)) {
    return true;
  }
  if (failure is! NetworkFailure) {
    return false;
  }
  final cause = failure.cause;
  if (cause is SocketDispatchTimeout) {
    return true;
  }
  if (cause is SocketDispatchDisconnected) {
    return true;
  }
  if (cause is SocketDispatchAppError &&
      _e2eIsTransientHubOverloadAppErrorCode(cause.code)) {
    return true;
  }
  if (cause is RelayRequestTimeout ||
      cause is RelayConversationLost ||
      cause is RelayDecodeFailure) {
    return true;
  }
  if (cause is RelayRequestRejected &&
      _e2eIsTransientHubOverloadAppErrorCode(cause.code)) {
    return true;
  }
  return false;
}

Future<AuthSessionModel> _e2eClientLoginWithHubTransientRetries(
  ApiAuthRemoteDataSource authRemote, {
  required String email,
  required String password,
}) async {
  const maxAttempts = 6;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      final backoffMs = (250 * (1 << (attempt - 1))).clamp(250, 4000);
      await Future<void>.delayed(Duration(milliseconds: backoffMs));
    }
    try {
      return await authRemote.login(email: email, password: password);
    } on DioException catch (e, st) {
      if (!isTransientHubDioException(e) || attempt == maxAttempts - 1) {
        Error.throwWithStackTrace(e, st);
      }
    }
  }
  throw StateError('E2E login retry loop exited without result');
}

/// Wraps repository / use-case calls so uncaught [DioException] from HTTP 5xx
/// or transport timeouts become an [AppResult] failure that
/// [isTransientE2eAgentSqlBridgeTransportFailure] /
/// [isAcceptableE2eAgentSqlRepositoryFailure] recognise (full `flutter test`
/// runs E2E in parallel with other suites and can hit hub 503s).
///
/// Set `E2E_LOG_TRANSIENT=1` in the process environment to print one line per
/// transient mapping (HTTP status, Dio type, optional action label).
Future<AppResult<T>> runE2eAppResult<T extends Object>(
  Future<AppResult<T>> Function() action, {
  String? actionLabel,
}) async {
  try {
    return await action();
  } on DioException catch (e, st) {
    if (isTransientHubDioException(e)) {
      if (_e2eLogTransientHubErrors()) {
        final label = actionLabel ?? 'unspecified';
        // E2E diagnostics only when E2E_LOG_TRANSIENT is set; stdout is intentional.
        // ignore: avoid_print -- E2E diagnostics should appear in CI logs.
        print(
          'E2E transient hub: action=$label '
          'http=${e.response?.statusCode} dioType=${e.type.name}',
        );
      }
      final status = e.response?.statusCode;
      final suffix = actionLabel != null ? ' ($actionLabel)' : '';
      return Failure<T, AppFailure>(
        NetworkFailure(
          message: 'E2E transient HTTP transport$suffix',
          userMessage: status != null ? 'Hub HTTP $status' : null,
          cause: e,
          stackTrace: st,
        ),
      );
    }
    rethrow;
  }
}

/// Retries when the first attempt returns a hub transient [NetworkFailure]
/// (503 / timeouts) wrapped by [runE2eAppResult], e.g. a second repository page
/// after a successful first page.
///
/// Also retries when the repository returned a transient **socket or relay**
/// [NetworkFailure] (see [isTransientE2eAgentSqlBridgeTransportFailure]), not
/// only HTTP [DioException] causes.
Future<AppResult<T>> runE2eAppResultWithHubRetry<T extends Object>(
  Future<AppResult<T>> Function() action, {
  String? actionLabel,
  int maxAttempts = 3,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
    }
    final attemptLabel = actionLabel == null
        ? null
        : attempt == 0
        ? actionLabel
        : '${actionLabel}_attempt_${attempt + 1}';
    final result = await runE2eAppResult(
      action,
      actionLabel: attemptLabel,
    );
    if (result.isSuccess()) {
      return result;
    }
    final failure = result.exceptionOrNull();
    if (failure == null) {
      return result;
    }
    if (!isTransientE2eAgentSqlBridgeTransportFailure(failure) ||
        attempt == maxAttempts - 1) {
      return result;
    }
  }
  throw StateError('runE2eAppResultWithHubRetry exhausted attempts');
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

/// Plug agent dropped off the hub between SQL dispatch and response (common
/// during long sequential E2E runs against a single dev agent).
bool isKnownE2eAgentDisconnectedAtDispatchFailure(AppFailure failure) {
  if (failure is! RpcFailure) {
    return false;
  }
  return failure.reason == 'agent_disconnected_at_dispatch';
}

/// Fail-fast while the agent-queries circuit breaker is open (overload
/// protection): [NetworkFailure] without an underlying Dio cause, but still
/// an environmental hub-overload signal for E2E smoke runs.
bool isKnownE2eAgentSqlCircuitBreakerOpenFailure(AppFailure failure) {
  if (failure is! NetworkFailure) {
    return false;
  }
  final state = failure.context['circuitBreakerState']
      ?.toString()
      .trim()
      .toLowerCase();
  return state == 'open';
}

/// Known policy rejection, missing table permission RPC, transient bridge
/// HTTP 5xx or socket/relay transport overload, HTTP 403 forbidden on agent
/// SQL, queue saturation, circuit breaker open after hub overload, or plug
/// agent disconnected at dispatch (environment / hub access).
bool isAcceptableE2eAgentSqlRepositoryFailure(AppFailure failure) {
  return isKnownInvalidPolicyFailure(failure) ||
      isKnownAgentSqlMissingPermissionFailure(failure) ||
      isTransientE2eAgentSqlBridgeTransportFailure(failure) ||
      isKnownE2eAgentSqlHttpForbiddenFailure(failure) ||
      isKnownE2eAgentSqlBridgeNamedParameterLimitFailure(failure) ||
      isKnownE2eAgentSqlQueueSaturationFailure(failure) ||
      isKnownE2eAgentSqlCircuitBreakerOpenFailure(failure) ||
      isKnownE2eAgentDisconnectedAtDispatchFailure(failure);
}

String e2eAgentSqlFailureDiagnostic(AppFailure failure) {
  final context = failure.context;
  final parts = <String>[
    'type=${failure.runtimeType}',
    'message=${failure.displayMessage}',
  ];
  final httpStatus = context['httpStatusCode'];
  if (httpStatus != null) {
    parts.add('httpStatus=$httpStatus');
  }
  if (failure is RpcFailure) {
    parts
      ..add('rpcCode=${failure.rpcCode}')
      ..add('reason=${failure.reason}')
      ..add('category=${failure.category}');
  }
  final uiKey = context[AgentSqlRpcFailureUiKey.field];
  if (uiKey != null) {
    parts.add('uiKey=$uiKey');
  }
  final responseBody =
      context[DioHttpFailureContext.responseBodyField] ??
      context[AgentSqlRpcFailureUiKey.errorDataField];
  if (responseBody != null) {
    parts.add('response=${_e2eDiagnosticValue(responseBody)}');
  }
  return parts.join(' ');
}

String _e2eDiagnosticValue(Object? value) {
  final raw = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  const maxLen = 1200;
  if (raw.length <= maxLen) {
    return raw;
  }
  return '${raw.substring(0, maxLen)}...';
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
    EnvKeys.agentBridgeTransport,
    EnvKeys.socketNamespace,
    EnvKeys.socketReconnectAttempts,
    EnvKeys.socketReconnectInitialDelayMs,
    EnvKeys.socketReconnectMaxDelayMs,
    EnvKeys.socketRequestTimeoutMs,
    EnvKeys.socketHandshakeTimeoutMs,
    EnvKeys.socketWarmUpAfterLogin,
    EnvKeys.socketMaxInflightPerAgent,
    EnvKeys.socketMaxInflightWaitersPerAgent,
    EnvKeys.socketMaxInflightAcquireWaitMs,
    EnvKeys.socketStreamSqlCollectorMaxBufferedRows,
    EnvKeys.socketCoalescingEnabled,
    EnvKeys.socketTimeoutAdaptiveEnabled,
    EnvKeys.socketBatchEnabled,
    EnvKeys.socketBatchWindowMs,
    EnvKeys.socketBatchMaxSize,
    EnvKeys.socketBatchMinSize,
    EnvKeys.socketRelayEnabled,
    EnvKeys.socketRelayRequestTimeoutMs,
    EnvKeys.socketRelayConversationStartTimeoutMs,
    EnvKeys.socketRelayConversationEndTimeoutMs,
    EnvKeys.socketRelayPayloadFrameCompression,
    EnvKeys.socketRelayStreamInitialWindow,
    EnvKeys.socketRelayStreamRefillThreshold,
    EnvKeys.socketPresenceListenerEnabled,
    EnvKeys.socketConnectionReadyCompatMode,
    EnvKeys.socketPayloadSigningKey,
    EnvKeys.socketPayloadSigningKeyId,
    EnvKeys.socketPayloadRequireSignature,
    EnvKeys.e2eAgentId,
    EnvKeys.e2eClientToken,
    EnvKeys.e2eClientEmail,
    EnvKeys.e2eClientPassword,
    EnvKeys.e2eDisableRelayDispatch,
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

final class _E2eAuthSessionAccessor implements AuthSessionAccessor {
  _E2eAuthSessionAccessor(this._sessionHolder);

  final E2eAuthSessionHolder _sessionHolder;

  @override
  Future<AuthSessionModel?> read() async => _sessionHolder.value;

  @override
  Future<void> save(AuthSessionModel session) async {
    _sessionHolder.value = session;
  }

  @override
  Future<void> clear() async {
    _sessionHolder.value = null;
  }
}
