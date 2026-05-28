/// One JSON-RPC command participating in a `relay:rpc.request.batch`
/// envelope. The hub answers per item — the dispatcher correlates each
/// reply to the [clientRequestId] declared here.
///
/// `clientRequestId` MUST equal the `id` of the JSON-RPC object inside
/// [body] (the dispatcher injects it before wire encode). The hub
/// requires every batch item to carry an `id` (no notifications).
///
/// Streaming-capable items (`sql.executeBatch`, `sql.execute` with
/// `prefer_db_streaming` / `multi_result`) MUST be sent as unary
/// `relay:rpc.request` instead — the v1 batch protocol rejects them
/// with `BATCH_STREAMING_ITEM_REJECTED`. The
/// `RelayBatchCommandCoordinator` enforces this bypass before flushing.
class RelayBatchItem {
  const RelayBatchItem({
    required this.clientRequestId,
    required this.body,
    this.timeout,
  });

  /// JSON-RPC `id` for this item. Must be unique within the envelope
  /// (the hub rejects duplicates with `BATCH_DUPLICATE_ID`).
  final String clientRequestId;

  /// Full JSON-RPC body — `{ jsonrpc: '2.0', method, id, params }`.
  /// The dispatcher does not mutate it before encoding.
  final Map<String, Object?> body;

  /// Optional per-item deadline. The envelope timeout is the maximum of
  /// every item's timeout; items whose individual deadline elapsed
  /// before the response arrives are failed locally without waiting.
  final Duration? timeout;
}
