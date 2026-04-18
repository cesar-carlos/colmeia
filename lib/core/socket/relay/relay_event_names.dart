/// Stable string constants for every Socket.IO event consumed by the relay
/// channel (`/consumers` namespace).
///
/// Centralising the names here avoids typos scattered across the dispatcher,
/// the conversation manager and the test mocks, and gives a single place to
/// audit when the hub renames an event (see
/// `plug_server/docs/socket_relay_protocol.md`).
abstract final class RelayEventNames {
  // Conversation lifecycle (JSON envelope, no PayloadFrame).
  static const String conversationStart = 'relay:conversation.start';
  static const String conversationStarted = 'relay:conversation.started';
  static const String conversationEnd = 'relay:conversation.end';
  static const String conversationEnded = 'relay:conversation.ended';

  // RPC request / response (PayloadFrame except `accepted`/`pull_response`).
  static const String rpcRequest = 'relay:rpc.request';
  static const String rpcAccepted = 'relay:rpc.accepted';
  static const String rpcResponse = 'relay:rpc.response';
  static const String rpcChunk = 'relay:rpc.chunk';
  static const String rpcComplete = 'relay:rpc.complete';
  static const String rpcRequestAck = 'relay:rpc.request_ack';
  static const String rpcBatchAck = 'relay:rpc.batch_ack';

  // Stream backpressure.
  static const String rpcStreamPull = 'relay:rpc.stream.pull';
  static const String rpcStreamPullResponse = 'relay:rpc.stream.pull_response';

  // Server-side error envelope (shared with the legacy `agents:command`).
  static const String appError = 'app:error';
}

/// Strategy hint forwarded to the hub so it can decide whether to gzip the
/// re-encoded `rpc:request` it emits to the agent. The consumer-side frame is
/// always decoded by the hub regardless of this value.
///
/// Mirrors `payloadFrameCompression` in `plug_server/docs/socket_client_sdk.md`
/// (`agents:command` and `relay:rpc.request`).
enum RelayPayloadFrameCompression {
  /// `default` — auto compression: hub gzips only when it strictly reduces the
  /// JSON size (`PAYLOAD_FRAME_AUTO_GZIP_MIN_SAVINGS_BYTES`).
  auto,

  /// `none` — never gzip the hub→agent frame even when above threshold.
  none,

  /// `always` — gzip every elegible frame, mirroring agents that prefer
  /// "always GZIP" mode.
  always;

  /// Wire string sent in the envelope.
  String get wireValue => switch (this) {
    RelayPayloadFrameCompression.auto => 'default',
    RelayPayloadFrameCompression.none => 'none',
    RelayPayloadFrameCompression.always => 'always',
  };

  /// Parses a string from `--dart-define` / dotenv. Unknown / empty inputs
  /// fall back to [RelayPayloadFrameCompression.auto].
  static RelayPayloadFrameCompression parse(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      'always' => RelayPayloadFrameCompression.always,
      'none' => RelayPayloadFrameCompression.none,
      _ => RelayPayloadFrameCompression.auto,
    };
  }
}
