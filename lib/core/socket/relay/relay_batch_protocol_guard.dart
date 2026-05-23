import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';

/// Guard for future hub relay batch support. Today the relay channel accepts
/// exactly one JSON-RPC command per `relay:rpc.request`.
abstract final class RelayBatchProtocolGuard {
  static void assertBatchNotRequested({required int itemCount}) {
    if (itemCount <= 1) {
      return;
    }
    if (!AppEnvironment.socketRelayBatchEnabled) {
      throw RelayRequestRejected(
        message:
            'Relay JSON-RPC batch is not enabled in this client build '
            '(count=$itemCount). Use agents:command batch or unary relay.',
        serverCode: 'relay_batch_not_supported',
      );
    }
  }
}
