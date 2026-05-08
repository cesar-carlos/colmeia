/// Wrapper that lets `AppResult<S>` carry a nullable [ClientTokenPolicy].
///
/// `S extends Object` on `result_dart`; we cannot use
/// `AppResult<ClientTokenPolicy?>` directly. [supported] is `false` when
/// the agent reported the method as not implemented (older profile or
/// introspection disabled), so the UI can hide the "permissions" section
/// quietly instead of surfacing an error.
class ClientTokenPolicySnapshot {
  const ClientTokenPolicySnapshot({
    required this.policy,
    required this.supported,
  });

  /// Convenience for "agent does not implement client_token.getPolicy".
  const ClientTokenPolicySnapshot.unsupported()
    : policy = null,
      supported = false;

  /// Convenience for "agent answered with a policy".
  const ClientTokenPolicySnapshot.from(ClientTokenPolicy this.policy)
    : supported = true;

  final ClientTokenPolicy? policy;
  final bool supported;

  bool get hasPolicy => supported && policy != null;
}

/// Authorization policy resolved by the agent for a given client token.
///
/// Mirrors the result of `client_token.getPolicy` (plug-jsonrpc-profile 2.7+)
/// — the agent does NOT execute SQL when this method is invoked, it only
/// inspects which permissions / tables / views the token currently has.
///
/// Field shape follows the JSON Schema `rpc.result.client-token-get-policy`
/// from `plug_agente`. Sensitive values inside [payload] may be redacted by
/// the agent.
class ClientTokenPolicy {
  const ClientTokenPolicy({
    required this.tokenIdentifier,
    required this.allTables,
    required this.allViews,
    required this.allPermissions,
    required this.tableRules,
    required this.viewRules,
    required this.permissionRules,
    this.revoked = false,
    this.revokedAt,
    this.payload = const <String, Object?>{},
  });

  /// Convenience for missing/invalid responses (no introspection
  /// available on the agent or token still being resolved).
  const ClientTokenPolicy.unknown()
    : tokenIdentifier = '',
      allTables = false,
      allViews = false,
      allPermissions = false,
      tableRules = const <String>[],
      viewRules = const <String>[],
      permissionRules = const <String>[],
      revoked = false,
      revokedAt = null,
      payload = const <String, Object?>{};

  /// Stable identifier the agent assigned to the token (sha-256, jti…).
  /// Empty when the agent did not echo the field.
  final String tokenIdentifier;

  /// `true` when the token is allowed to query **any** table.
  final bool allTables;

  /// `true` when the token is allowed to query **any** view.
  final bool allViews;

  /// `true` when the token has **all** permissions (super-user-like).
  final bool allPermissions;

  /// Table allow-list when [allTables] is `false`.
  final List<String> tableRules;

  /// View allow-list when [allViews] is `false`.
  final List<String> viewRules;

  /// Permission flags granted to the token (read/write/admin/etc.).
  final List<String> permissionRules;

  /// `true` when the agent reports the token as revoked.
  final bool revoked;

  /// When the agent observed the revocation (ISO-8601 → `DateTime` UTC).
  final DateTime? revokedAt;

  /// Full payload returned by the agent — kept for diagnostics. Callers
  /// should NOT depend on these keys for business logic.
  final Map<String, Object?> payload;

  /// Fast UI hint — `true` when the policy effectively grants full SQL
  /// access (all tables AND all views AND all permissions).
  bool get hasFullAccess => allTables && allViews && allPermissions;

  bool get isEmpty =>
      tokenIdentifier.isEmpty &&
      tableRules.isEmpty &&
      viewRules.isEmpty &&
      permissionRules.isEmpty;
}
