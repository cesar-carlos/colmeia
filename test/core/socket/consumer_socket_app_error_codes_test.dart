import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/consumer_socket_app_error_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsumerSocketAppErrorCodes', () {
    test('recognizes terminal hub codes', () {
      check(
        ConsumerSocketAppErrorCodes.isTerminal('ACCOUNT_BLOCKED'),
      ).isTrue();
      check(
        ConsumerSocketAppErrorCodes.isTerminal('AGENT_ACCESS_REVOKED'),
      ).isTrue();
      check(
        ConsumerSocketAppErrorCodes.isTerminal('CONSUMER_IDLE_TIMEOUT'),
      ).isTrue();
      check(
        ConsumerSocketAppErrorCodes.isTerminal(
          'CONSUMER_SOCKET_INITIALIZATION_FAILED',
        ),
      ).isTrue();
      check(
        ConsumerSocketAppErrorCodes.isTerminal('SERVICE_UNAVAILABLE'),
      ).isFalse();
    });

    test('maps disconnect reasons and auth invalidation', () {
      check(
        ConsumerSocketAppErrorCodes.disconnectReasonFor('ACCOUNT_BLOCKED'),
      ).equals('hub_forced_ACCOUNT_BLOCKED');
      check(
        ConsumerSocketAppErrorCodes.isHubForcedDisconnectReason(
          'hub_forced_ACCOUNT_BLOCKED',
        ),
      ).isTrue();
      check(
        ConsumerSocketAppErrorCodes.requiresAuthSessionInvalidation(
          'ACCOUNT_BLOCKED',
        ),
      ).isTrue();
      check(
        ConsumerSocketAppErrorCodes.requiresAuthSessionInvalidation(
          'CONSUMER_IDLE_TIMEOUT',
        ),
      ).isFalse();
    });
  });
}
