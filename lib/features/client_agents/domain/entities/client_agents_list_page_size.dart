/// Page size for client agent list APIs and Hive cache keys.
///
/// Use this value for approved agents, access requests, post-sync snapshots,
/// UI refresh, and agent-query target resolution pagination so the same cache
/// entry is reused across flows.
const int kClientAgentsListPageSize = 50;

/// Upper bound for agent ids bundled into one `POST /client/me/agents` or
/// `DELETE /client/me/agents` while syncing queued offline actions.
const int kClientAgentsRequestAccessSyncBatchSize = 50;

/// Max parallel per-id `DELETE /client/me/agents/{id}` calls used only as
/// fallback when bulk `DELETE /client/me/agents` fails for a chunk.
const int kClientAgentsRemoveAccessSyncConcurrency = 6;
