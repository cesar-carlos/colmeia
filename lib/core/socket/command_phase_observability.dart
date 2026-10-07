typedef CommandPhaseListener = void Function(String phase, Duration elapsed);

/// Optional local diagnostics; does not alter RPC envelopes or transport ports.
// ignore: one_member_abstracts
abstract interface class CommandPhaseObservability {
  void Function() observePhases(
    String requestId,
    CommandPhaseListener listener,
  );
}

class CommandPhaseObservers {
  final Map<String, CommandPhaseListener> _listeners = {};

  void Function() observe(String requestId, CommandPhaseListener listener) {
    _listeners[requestId] = listener;
    return () {
      if (identical(_listeners[requestId], listener)) {
        _listeners.remove(requestId);
      }
    };
  }

  void record(String requestId, String phase, Duration elapsed) {
    try {
      _listeners[requestId]?.call(phase, elapsed);
    } on Object {
      // Optional diagnostics must never change the transport outcome.
    }
  }
}

void Function() observeCommandPhases(
  Object transport,
  String requestId,
  CommandPhaseListener? listener,
) {
  if (listener != null && transport is CommandPhaseObservability) {
    return transport.observePhases(requestId, listener);
  }
  return () {};
}
