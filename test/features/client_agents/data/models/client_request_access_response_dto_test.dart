import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shouldPollApprovalFor includes newRequests and excludes alreadyApproved',
    () {
      const dto = ClientRequestAccessResponseDto(
        alreadyApproved: <String>['a1'],
        newRequests: <String>['a2'],
        requested: <String>['a3'],
      );
      check(dto.shouldPollApprovalFor('a1')).isFalse();
      check(dto.shouldPollApprovalFor('a2')).isTrue();
      check(dto.shouldPollApprovalFor('a3')).isTrue();
    },
  );

  test('parse keeps empty semantic body unacknowledged', () {
    final dto = ClientRequestAccessResponseDto.parse(
      const <String, dynamic>{},
    );
    check(dto.requested).isEmpty();
    check(dto.acknowledgesAgent('x')).isFalse();
  });
}
