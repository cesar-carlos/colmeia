/// Read snapshot of the per-(client, agent) bearer token currently stored on
/// the server (and mirrored locally).
///
/// Wraps a nullable [token] so it can flow through `AppResult<S>` (which
/// requires `S extends Object`). [hasToken] is the boolean clients usually
/// care about — it matches the `hasClientToken` flag exposed by the listing
/// endpoints.
///
/// Equality is intentionally identity-based: snapshots are short-lived and
/// re-created on every repository call, and value equality on a secret token
/// would invite accidental leaks through `==` checks in widget rebuild paths.
class ClientAgentTokenSnapshot {
  const ClientAgentTokenSnapshot({required this.token});

  /// Convenience for "no token configured".
  const ClientAgentTokenSnapshot.empty() : token = null;

  /// Server-stored token, or `null` when no token is currently configured for
  /// this `(client, agent)` pair. Whitespace-only strings are treated as
  /// absent and normalized to `null` upstream.
  final String? token;

  bool get hasToken {
    final value = token;
    return value != null && value.isNotEmpty;
  }

  @override
  String toString() {
    return hasToken
        ? 'ClientAgentTokenSnapshot(hasToken: true)'
        : 'ClientAgentTokenSnapshot.empty()';
  }
}
