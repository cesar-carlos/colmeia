import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_constraints.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/features/client_agents/presentation/utils/client_agents_request_access_form_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validIdA = '11111111-1111-1111-8111-111111111111';
  const validIdB = '22222222-2222-2222-8222-222222222222';
  const validIdC = '33333333-3333-3333-8333-333333333333';

  ClientAgentAccessRequestRowInput row(String id, [String token = '']) {
    return ClientAgentAccessRequestRowInput(
      agentIdRaw: id,
      clientTokenRaw: token,
    );
  }

  group('parseClientAgentsRequestAccessForm', () {
    test('returns needs-one-valid-id when all rows are empty', () {
      final result = parseClientAgentsRequestAccessForm(<
        ClientAgentAccessRequestRowInput
      >[row(''), row('   ')]);

      expect(result, isA<ClientAgentsRequestAccessFormNeedsAtLeastOneId>());
    });

    test('reports invalid ids when no row holds a valid UUID', () {
      final result = parseClientAgentsRequestAccessForm(<
        ClientAgentAccessRequestRowInput
      >[row('not-a-uuid'), row('also-bad')]);

      expect(result, isA<ClientAgentsRequestAccessFormHasInvalidIds>());
      final failure = result as ClientAgentsRequestAccessFormHasInvalidIds;
      expect(failure.invalidAgentIds, <String>['not-a-uuid', 'also-bad']);
    });

    test(
      'reports invalid ids even when a valid id is also present, '
      'so the user fixes the typo before submit',
      () {
        final result = parseClientAgentsRequestAccessForm(<
          ClientAgentAccessRequestRowInput
        >[row(validIdA), row('bad-id')]);

        expect(result, isA<ClientAgentsRequestAccessFormHasInvalidIds>());
        final failure = result as ClientAgentsRequestAccessFormHasInvalidIds;
        expect(failure.invalidAgentIds, <String>['bad-id']);
      },
    );

    test('reports tokens too long when only invalid is the token length', () {
      final tooLong = 'a' * (ClientAgentTokenConstraints.maxLength + 1);
      final result = parseClientAgentsRequestAccessForm(<
        ClientAgentAccessRequestRowInput
      >[row(validIdA, tooLong)]);

      expect(result, isA<ClientAgentsRequestAccessFormHasTokensTooLong>());
      final failure = result as ClientAgentsRequestAccessFormHasTokensTooLong;
      expect(failure.maxLength, ClientAgentTokenConstraints.maxLength);
      expect(failure.agentIds, <String>[validIdA]);
    });

    test('succeeds with deduped rows preserving first-seen order', () {
      final result = parseClientAgentsRequestAccessForm(<
        ClientAgentAccessRequestRowInput
      >[row(validIdB), row(validIdA), row(validIdB), row(validIdC)]);

      expect(result, isA<ClientAgentsRequestAccessFormParseSuccess>());
      final success = result as ClientAgentsRequestAccessFormParseSuccess;
      expect(success.rows.map((r) => r.agentIdRaw.trim()), <String>[
        validIdB,
        validIdA,
        validIdC,
      ]);
      expect(success.duplicatedAgentIds, <String>{validIdB});
    });

    test(
      'succeeds with empty rows interleaved without blocking submit',
      () {
        final result = parseClientAgentsRequestAccessForm(<
          ClientAgentAccessRequestRowInput
        >[row(''), row(validIdA), row('  '), row(validIdB)]);

        expect(result, isA<ClientAgentsRequestAccessFormParseSuccess>());
        final success = result as ClientAgentsRequestAccessFormParseSuccess;
        expect(success.rows, hasLength(2));
        expect(success.duplicatedAgentIds, isEmpty);
      },
    );

    test('trims agent id whitespace before validating', () {
      final result = parseClientAgentsRequestAccessForm(<
        ClientAgentAccessRequestRowInput
      >[row('  $validIdA  ')]);

      expect(result, isA<ClientAgentsRequestAccessFormParseSuccess>());
    });

    test('keeps duplicates without invalidating the form', () {
      final result = parseClientAgentsRequestAccessForm(<
        ClientAgentAccessRequestRowInput
      >[row(validIdA), row(validIdA)]);

      expect(result, isA<ClientAgentsRequestAccessFormParseSuccess>());
      final success = result as ClientAgentsRequestAccessFormParseSuccess;
      expect(success.rows, hasLength(1));
      expect(success.duplicatedAgentIds, <String>{validIdA});
    });
  });
}
