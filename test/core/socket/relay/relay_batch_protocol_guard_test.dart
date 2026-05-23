import 'package:colmeia/core/socket/relay/relay_batch_protocol_guard.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows single-item batch check', () {
    expect(
      () => RelayBatchProtocolGuard.assertBatchNotRequested(itemCount: 1),
      returnsNormally,
    );
  });

  test('rejects multi-item batch when env flag is off', () {
    expect(
      () => RelayBatchProtocolGuard.assertBatchNotRequested(itemCount: 3),
      throwsA(isA<RelayRequestRejected>()),
    );
  });
}
