/// Visible state of the per-(client, agent) bearer token stored on the
/// server. The detail page renders different copy/chips for each branch.
enum ClientAgentTokenStatus {
  /// Server snapshot has not been fetched yet (initial load or refresh in
  /// flight). Treat the field value as the local cache fallback.
  unknown,

  /// Server confirmed there is no token stored for this `(client, agent)`.
  missing,

  /// Server confirmed a non-empty token is stored.
  configured,
}
