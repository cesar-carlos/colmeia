import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/socket_auth_token_provider.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/socket_io_client_factory.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';

import 'e2e_dependency_bootstrap.dart' show primeE2eEnvironment;

/// Lightweight runtime stack the socket smoke e2e plugs into.
///
/// Built by [setupE2eSocketBundle] so tests do not need the full app DI
/// (Hive, secure storage, route observers, presentation controllers).
/// Every component matches the one wired in production by
/// `injector_socket.dart` — this is the same code path validated against
/// the real `plug_server`, just without the persistence layers.
class E2eSocketBundle {
  E2eSocketBundle({
    required this.accessToken,
    required this.connection,
    required this.dispatcher,
    required this.correlator,
    this.relayManager,
    this.relayDispatcher,
  });

  final String accessToken;
  final ConsumerSocketConnection connection;
  final SocketCommandDispatcher dispatcher;
  final SocketRequestCorrelator correlator;

  /// PR-L: only present when [setupE2eSocketBundle] was called with
  /// `withRelay: true` (and the env opted into the relay). Lets the
  /// relay smoke test issue `relay:rpc.request` without rebuilding the
  /// whole stack from scratch.
  final RelayConversationManager? relayManager;
  final RelayCommandDispatcher? relayDispatcher;

  Future<void> dispose() async {
    await relayDispatcher?.dispose();
    await relayManager?.dispose();
    await dispatcher.dispose();
    await connection.dispose();
    await correlator.dispose();
  }
}

/// Creates a bundle with a real socket pointed at `AppEnvironment.apiBaseUrl`.
/// Performs the REST `/client-auth/login` synchronously so the socket
/// handshake has a valid bearer.
///
/// Throws [StateError] when env is missing the auth credentials. Callers
/// should call `missingE2eSocketKeys` first to skip cleanly in CI.
///
/// Set [withRelay] to `true` to also build [E2eSocketBundle.relayManager]
/// and [E2eSocketBundle.relayDispatcher] for the relay smoke test.
Future<E2eSocketBundle> setupE2eSocketBundle({bool withRelay = false}) async {
  primeE2eEnvironment();

  final loginDio = Dio(AppDioClient.createBaseOptions());
  final session = await ApiAuthRemoteDataSource(loginDio).login(
    email: AppEnvironment.e2eClientEmail,
    password: AppEnvironment.e2eClientPassword,
  );

  final tokenProvider = _StaticTokenProvider(session.accessToken);
  final urlResolver = AppSocketUrlResolver(
    rawApiBaseUrl: AppEnvironment.apiBaseUrl,
    namespace: AppEnvironment.socketNamespace,
  );
  final connection = ConsumerSocketConnection(
    urlResolver: urlResolver,
    tokenProvider: tokenProvider,
    factory: const DefaultSocketIoClientFactory(),
    readyDecoder: _buildReadyDecoder(),
    handshakeTimeout: Duration(
      milliseconds: AppEnvironment.socketHandshakeTimeoutMs,
    ),
    maxReconnectAttempts: 1,
    reconnectInitialDelay: const Duration(milliseconds: 250),
    reconnectMaxDelay: const Duration(seconds: 1),
  );
  final correlator = SocketRequestCorrelator();
  final dispatcher = SocketCommandDispatcherImpl(
    connection: connection,
    correlator: correlator,
    defaultTimeout: Duration(
      milliseconds: AppEnvironment.socketRequestTimeoutMs,
    ),
  );

  RelayConversationManager? relayManager;
  RelayCommandDispatcher? relayDispatcher;
  if (withRelay) {
    relayManager = RelayConversationManager(
      connection: connection,
      startTimeout: Duration(
        milliseconds: AppEnvironment.socketRelayConversationStartTimeoutMs,
      ),
      endTimeout: Duration(
        milliseconds: AppEnvironment.socketRelayConversationEndTimeoutMs,
      ),
    );
    relayDispatcher = RelayCommandDispatcherImpl(
      connection: connection,
      conversationManager: relayManager,
      defaultTimeout: Duration(
        milliseconds: AppEnvironment.socketRelayRequestTimeoutMs,
      ),
      defaultCompression: AppEnvironment.socketRelayPayloadFrameCompression,
      defaultStreamInitialWindow: AppEnvironment.socketRelayStreamInitialWindow,
      defaultStreamRefillThreshold:
          AppEnvironment.socketRelayStreamRefillThreshold,
    );
  }

  return E2eSocketBundle(
    accessToken: session.accessToken,
    connection: connection,
    dispatcher: dispatcher,
    correlator: correlator,
    relayManager: relayManager,
    relayDispatcher: relayDispatcher,
  );
}

/// Returns the env keys missing for the socket smoke e2e. Empty list
/// means we are good to go.
List<String> missingE2eSocketKeys() {
  primeE2eEnvironment();
  final missing = <String>[];
  if (AppEnvironment.apiBaseUrl.isEmpty) {
    missing.add(EnvKeys.apiBaseUrl);
  }
  if (AppEnvironment.e2eClientEmail.isEmpty) {
    missing.add(EnvKeys.e2eClientEmail);
  }
  if (AppEnvironment.e2eClientPassword.isEmpty) {
    missing.add(EnvKeys.e2eClientPassword);
  }
  if (AppEnvironment.e2eAgentId.isEmpty) {
    missing.add(EnvKeys.e2eAgentId);
  }
  if (AppEnvironment.e2eClientToken.isEmpty) {
    missing.add(EnvKeys.e2eClientToken);
  }
  return missing;
}

ConnectionReadyDecoder _buildReadyDecoder() {
  // Match the production default (`compat`): try PayloadFrame first,
  // fall back to raw JSON. Removes the need to twist the env when the
  // hub is mid-migration.
  return CompatConnectionReadyDecoder();
}

/// Stub provider that always returns the post-login token. The smoke
/// test does not exercise refresh — the dedicated REST e2e covers that.
class _StaticTokenProvider implements SocketAuthTokenProvider {
  _StaticTokenProvider(this._token)
    : _events = StreamController<void>.broadcast();

  final String _token;
  final StreamController<void> _events;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<String?> refreshAccessToken() async {
    // Smoke does not exercise refresh: returning the same token reuses
    // the bearer for the in-test reconnect window.
    return _token;
  }

  @override
  Stream<void> sessionInvalidations() => _events.stream;
}
