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

  test('parse keeps empty semantic body unacknowledged without fallback', () {
    final dto = ClientRequestAccessResponseDto.parse(
      const <String, dynamic>{},
    );
    check(dto.requested).isEmpty();
    check(dto.acknowledgesAgent('x')).isFalse();
  });

  test('parse accepts snake_case aliases', () {
    final dto = ClientRequestAccessResponseDto.parse(
      const <String, dynamic>{
        'already_approved': <String>['a1'],
        'new_requests': <String>['a2'],
      },
    );
    check(dto.alreadyApproved).deepEquals(<String>['a1']);
    check(dto.newRequests).deepEquals(<String>['a2']);
    check(dto.acknowledgesAgent('a1')).isTrue();
    check(dto.acknowledgesAgent('a2')).isTrue();
  });

  test('parse uses fallbackRequestedIds for empty 2xx body', () {
    final dto = ClientRequestAccessResponseDto.parse(
      const <String, dynamic>{},
      fallbackRequestedIds: <String>{'a1', 'a2'},
    );
    check(dto.requested.toSet()).deepEquals(<String>{'a1', 'a2'});
    check(dto.acknowledgesAgent('a1')).isTrue();
    check(dto.shouldPollApprovalFor('a2')).isTrue();
  });
}
