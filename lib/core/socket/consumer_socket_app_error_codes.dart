/// Hub `app:error` codes that forcibly end the `/consumers` session.
///
/// Source: `docs/plug_server/socket/socket_client_sdk.md` ("Desconexoes
/// forçadas pelo servidor"). Clients must invalidate local socket state,
/// avoid naive reconnect loops, and re-bootstrap (REST / re-auth) before
/// opening a new `/consumers` session.
abstract final class ConsumerSocketAppErrorCodes {
  static const String accountBlocked = 'ACCOUNT_BLOCKED';
  static const String agentAccessRevoked = 'AGENT_ACCESS_REVOKED';
  static const String consumerIdleTimeout = 'CONSUMER_IDLE_TIMEOUT';
  static const String consumerSocketInitializationFailed =
      'CONSUMER_SOCKET_INITIALIZATION_FAILED';

  static const Set<String> terminalCodes = <String>{
    accountBlocked,
    agentAccessRevoked,
    consumerIdleTimeout,
    consumerSocketInitializationFailed,
  };

  /// Whether [code] is a hub-forced terminal disconnect.
  static bool isTerminal(String? code) {
    if (code == null || code.isEmpty) {
      return false;
    }
    return terminalCodes.contains(code);
  }

  /// Disconnect reason stored on `ConsumerSocketDisconnected` so
  /// `SocketLifecycleObserver` treats the teardown as intentional.
  static String disconnectReasonFor(String code) => 'hub_forced_$code';

  /// Whether [reason] is a hub-forced intentional disconnect.
  static bool isHubForcedDisconnectReason(String? reason) {
    if (reason == null || reason.isEmpty) {
      return false;
    }
    return reason.startsWith('hub_forced_');
  }

  /// `ACCOUNT_BLOCKED` requires full session invalidation (re-login).
  /// Other terminal codes only tear down the socket session.
  static bool requiresAuthSessionInvalidation(String code) {
    return code == accountBlocked;
  }
}
