part of 'relay_command_dispatcher_impl.dart';

final class _PendingRelayFrameRoute {
  const _PendingRelayFrameRoute({
    required this.pending,
    required this.parseResult,
  });

  final _PendingRelay pending;
  final PayloadFrameParseResult parseResult;
}

/// Common state shared by both unitary and streaming pendings.
sealed class _PendingRelay {
  _PendingRelay({
    required this.agentId,
    required this.conversationId,
    required this.clientRequestId,
    required this.method,
    required this.stopwatch,
  });

  final String agentId;
  final String conversationId;
  final String clientRequestId;
  String? method;
  final Stopwatch stopwatch;

  String? requestId;
  bool deduplicated = false;
  bool replayed = false;

  /// Hub `relay:rpc.accepted` flagged this `client_request_id` as still
  /// in flight on another waiter. The pending stays open until response;
  /// callers must not resend.
  bool inFlight = false;
  Timer? timeoutTimer;

  /// [Stopwatch.elapsed] right after `relay:rpc.request` was successfully
  /// emitted (post encode + socket emit). Used to bound the
  /// request→accepted phase metric without including local encode work.
  Duration? requestEmittedAtElapsed;

  /// [Stopwatch.elapsed] when `relay:rpc.accepted` arrived for **unary**
  /// pendings. Streaming uses [_PendingStream.streamAcceptedAtElapsed]
  /// instead, because its semantics (first chunk vs final response)
  /// differ.
  Duration? unaryAcceptedAtElapsed;

  /// Serializes async frame handling and initial pull emission per request.
  Future<void> frameRoutingChain = Future<void>.value();

  /// Invoked once when the per-agent relay slot is finished.
  void Function()? relayPerAgentSlotRelease;

  /// Populated while [PerAgentConcurrencyGate.acquire] is awaiting a slot.
  Completer<void>? gateQueueWaitCompleter;

  /// Reports an external failure to the consumer (Future or Stream).
  /// Returns `true` when the failure was actually delivered (i.e. the
  /// underlying completer/controller was still open). Callers use the
  /// return value to decide whether to emit an outcome event.
  bool failExternally(RelayDispatchException exception);
}

class _PendingUnary extends _PendingRelay {
  _PendingUnary({
    required super.agentId,
    required super.conversationId,
    required super.clientRequestId,
    required super.method,
    required super.stopwatch,
  });

  final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();

  /// Diagnostic counter for chunks observed on a unary request (the
  /// dispatcher does not forward them, but the count helps spot agents
  /// that ignore the unary contract).
  int receivedChunkCount = 0;

  @override
  bool failExternally(RelayDispatchException exception) {
    if (completer.isCompleted) {
      return false;
    }
    completer.completeError(exception);
    return true;
  }
}

class _PendingStream extends _PendingRelay {
  _PendingStream({
    required super.agentId,
    required super.conversationId,
    required super.clientRequestId,
    required super.method,
    required super.stopwatch,
    required this.controller,
    required this.initialWindow,
    required this.refillThreshold,
  });

  final StreamController<Map<String, dynamic>> controller;

  /// Maximum number of in-flight chunks the dispatcher tolerates. Reset
  /// after every refill emission.
  final int initialWindow;

  /// Granularity for refilling the window: when [outstandingCredits]
  /// drops to or below this value the dispatcher tops the window back to
  /// [initialWindow] with a single `relay:rpc.stream.pull`.
  final int refillThreshold;

  /// Outstanding credits the hub still has authorised to send. Decremented
  /// per chunk received and replenished when `_grantPull` succeeds.
  int outstandingCredits = 0;

  /// Server stream identifier returned by pull acks or chunk payloads.
  /// Included on subsequent pull frames when present.
  String? streamId;

  /// [Stopwatch.elapsed] when `relay:rpc.accepted` succeeded (streaming only).
  Duration? streamAcceptedAtElapsed;

  bool streamFirstChunkMetricRecorded = false;

  @override
  bool failExternally(RelayDispatchException exception) {
    if (controller.isClosed) {
      return false;
    }
    controller.addError(exception);
    // close() completes once subscribers drained the error; the dispatcher
    // just signals failure here, callers receive it via the stream.
    unawaited(controller.close());
    return true;
  }
}
