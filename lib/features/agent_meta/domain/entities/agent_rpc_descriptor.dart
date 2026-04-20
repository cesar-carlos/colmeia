/// Catalogue of RPC methods an agent declares via `rpc.discover`.
///
/// The result follows the OpenRPC document — we keep a tiny abstraction so
/// the rest of the app does not depend on the full OpenRPC schema. Use
/// [supportsMethod] to gate UI features that depend on a specific RPC.
class AgentRpcDescriptor {
  const AgentRpcDescriptor({
    required this.methods,
    this.openRpcVersion,
    this.title,
    this.version,
    this.raw = const <String, Object?>{},
  });

  const AgentRpcDescriptor.empty()
      : methods = const <String>{},
        openRpcVersion = null,
        title = null,
        version = null,
        raw = const <String, Object?>{};

  /// Set of method names supported by the agent (e.g. `sql.execute`,
  /// `client_token.getPolicy`).
  final Set<String> methods;

  /// `openrpc` field of the document (`1.x`).
  final String? openRpcVersion;

  /// `info.title` of the OpenRPC document.
  final String? title;

  /// `info.version` of the OpenRPC document — useful to detect agents on
  /// older profile versions.
  final String? version;

  /// Original payload, preserved for diagnostics.
  final Map<String, Object?> raw;

  bool supportsMethod(String method) => methods.contains(method);

  bool get isEmpty => methods.isEmpty;
}
