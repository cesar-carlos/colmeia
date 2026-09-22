/// Relay batch limits advertised by the connected hub during
/// `connection:ready`.
///
/// A missing value means the hub predates capability advertisement. Callers
/// must retain their local compatibility fallback in that case.
class RelayBatchCapabilities {
  const RelayBatchCapabilities({
    required this.enabled,
    required this.maxItems,
  }) : assert(
         maxItems >= 1 && maxItems <= protocolMaxItems,
         'maxItems must be between 1 and $protocolMaxItems',
       );

  static const int protocolMaxItems = 32;

  final bool enabled;
  final int maxItems;
}

/// Provides the relay-batch capabilities for the active consumer socket.
///
/// The value is `null` before a handshake and for legacy hubs that do not
/// advertise capabilities.
abstract interface class RelayBatchCapabilitiesProvider {
  RelayBatchCapabilities? get relayBatchCapabilities;

  /// Identifies the socket session so learned limits expire on reconnect.
  String? get relayBatchSessionId;
}
