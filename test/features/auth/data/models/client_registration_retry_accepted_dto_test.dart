import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/models/client_registration_retry_accepted_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientRegistrationRetryAcceptedDto', () {
    test('should parse retry accepted message', () {
      final dto = ClientRegistrationRetryAcceptedDto.fromJson(
        const <String, dynamic>{
          'message': 'If eligible, a new approval request will be sent.',
        },
      );

      check(dto.message).which((m) => m.contains('eligible'));
    });
  });
}
