/// Stable code allowlists used by `AgentQueriesRepositoryImpl` when
/// classifying transport-level failures (Socket `app:error`, relay
/// `relay:rpc.accepted` rejections, …) into the right `AppFailure` variant.
///
/// Kept in a dedicated file so the matching is testable and easy to extend
/// without touching the repository's catch chain.
library;

/// Server `app:error` / relay rejection codes that mean **"authenticated but
/// not authorized"** and should surface as `AuthorizationFailure` (with a
/// PT-BR user message) instead of being mistaken for a generic network error.
///
/// Comparison is case-insensitive.
const Set<String> kSocketAuthorizationDeniedCodes = <String>{
  'AGENT_ACCESS_DENIED',
  'ACCESS_DENIED',
  'PERMISSION_DENIED',
  'FORBIDDEN',
  'INSUFFICIENT_SCOPE',
  'INSUFFICIENT_PRIVILEGES',
  'NOT_AUTHORIZED',
};

/// Server `app:error` / relay rejection codes that mean **"the JWT itself
/// is invalid / expired / not accepted"**. These should surface as
/// `SessionFailure` so the UX prompts the user to log in again.
///
/// Comparison is case-insensitive.
const Set<String> kSocketAuthenticationFailedCodes = <String>{
  'UNAUTHORIZED',
  'UNAUTHENTICATED',
  'INVALID_TOKEN',
  'TOKEN_EXPIRED',
  'TOKEN_INVALID',
};

/// Returns true when [code] (case-insensitive) is in
/// [kSocketAuthorizationDeniedCodes].
bool isSocketAuthorizationDeniedCode(String code) {
  return kSocketAuthorizationDeniedCodes.contains(code.toUpperCase());
}

/// Returns true when [code] (case-insensitive) is in
/// [kSocketAuthenticationFailedCodes].
bool isSocketAuthenticationFailedCode(String code) {
  return kSocketAuthenticationFailedCodes.contains(code.toUpperCase());
}

/// Socket / relay / HTTP envelope codes that mean **query rate limit** (hub
/// window, per-socket inflight, or REST `TOO_MANY_REQUESTS` on commands).
///
/// Comparison is case-insensitive.
const Set<String> kSocketRateLimitedCodes = <String>{
  'RATE_LIMITED',
  'TOO_MANY_REQUESTS',
};

/// Returns true when [code] (case-insensitive) is in [kSocketRateLimitedCodes].
bool isSocketRateLimitedCode(String code) {
  return kSocketRateLimitedCodes.contains(code.toUpperCase());
}

/// Stable context fields produced by the repository for downstream
/// consumers (controllers, telemetry, UI gating).
abstract final class AgentQueriesFailureContext {
  /// `true` when the failure originated from a deliberate cancellation
  /// (controller `dispose()`, navigation away, explicit cancel token). UI
  /// layers should skip surfacing an error message for these.
  static const String cancelledField = 'cancelled';

  /// Stable identifier of the transport that produced the failure
  /// (`socket`, `relay`, `rest`).
  static const String transportField = 'transport';

  /// Stable code from the underlying transport (e.g. `AGENT_ACCESS_DENIED`,
  /// `timeout`, `disconnected`, `conversation_lost`).
  static const String transportCodeField = 'transportCode';
}

/// True when [failure context] indicates the failure was a deliberate
/// cancellation. Controllers can use this to skip surfacing an error UI
/// (the user already navigated away or disposed the screen).
bool isCancelledAgentQueryFailure(Map<String, Object?> context) {
  return context[AgentQueriesFailureContext.cancelledField] == true;
}
