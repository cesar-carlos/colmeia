/// How multi-agent SQL loads are orchestrated.
///
/// **Financial / consolidated KPIs:** use [mergeAll] (or [singleSource] when
/// exactly one agent is selected). **Do not** use [race] for totals that must
/// include every branch — [race] keeps only the first successful response.
enum AgentQueryExecutionStrategy {
  /// Exactly one approved agent with a client token.
  singleSource,

  /// Load every planned agent and merge rows (overview default for N>1 agents).
  mergeAll,

  /// First successful agent wins; others discarded. Not for summed KPIs.
  race,
}
