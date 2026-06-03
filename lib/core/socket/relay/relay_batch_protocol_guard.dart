import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';

/// Guard for relay JSON-RPC batch when [AppEnvironment.socketRelayBatchEnabled]
/// is false. Hub v1 shipped 2026-05-28; with the flag off, multi-item batch
/// attempts are rejected before emit.
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
