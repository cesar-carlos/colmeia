/// Page size for client agent list APIs and Hive cache keys.
///
/// Use this value for approved agents, access requests, post-sync snapshots,
/// UI refresh, and agent-query target resolution pagination so the same cache
/// entry is reused across flows.
const int kClientAgentsListPageSize = 50;
