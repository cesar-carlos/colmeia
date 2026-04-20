import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeClientAgentsRemoteDataSource fake;

  // Approved by default in the in-memory fake.
  const approvedAgentId = '6ac362c2-72b5-4f2f-a071-96fe6f5f5080';

  setUp(() {
    fake = FakeClientAgentsRemoteDataSource();
  });

  test('fetchClientAgentToken returns null when no token has been stored',
      () async {
    final dto = await fake.fetchClientAgentToken(agentId: approvedAgentId);
    check(dto.agentId).equals(approvedAgentId);
    check(dto.clientToken).isNull();
    check(dto.hasClientToken).isFalse();
  });

  test('fetchClientAgentToken throws DioException 403 when no access', () async {
    DioException? captured;
    try {
      await fake.fetchClientAgentToken(
        agentId: '11111111-1111-1111-8111-111111111111',
      );
    } on DioException catch (error) {
      captured = error;
    }
    check(captured).isNotNull();
    check(captured!.response?.statusCode).equals(403);
  });

  test('putClientAgentToken stores token and round-trips on subsequent GET',
      () async {
    final put = await fake.putClientAgentToken(
      agentId: approvedAgentId,
      request: const ClientAgentTokenRequestDto(clientToken: '  secret  '),
    );
    check(put.clientToken).equals('secret');
    check(put.hasClientToken).isTrue();

    final get = await fake.fetchClientAgentToken(agentId: approvedAgentId);
    check(get.clientToken).equals('secret');
    check(get.hasClientToken).isTrue();
  });

  test('putClientAgentToken with null clears the stored token', () async {
    await fake.putClientAgentToken(
      agentId: approvedAgentId,
      request: const ClientAgentTokenRequestDto(clientToken: 'x'),
    );

    final cleared = await fake.putClientAgentToken(
      agentId: approvedAgentId,
      request: const ClientAgentTokenRequestDto(clientToken: null),
    );
    check(cleared.clientToken).isNull();
    check(cleared.hasClientToken).isFalse();

    final get = await fake.fetchClientAgentToken(agentId: approvedAgentId);
    check(get.clientToken).isNull();
    check(get.hasClientToken).isFalse();
  });

  test(
    'fetchApprovedAgents reflects hasClientToken flag after token is saved',
    () async {
    final before = await fake.fetchApprovedAgents(query: const PaginatedQuery());
    final beforeRow = before.agents.firstWhere(
      (a) => a.agentId == approvedAgentId,
    );
    check(beforeRow.hasClientToken).equals(false);

    await fake.putClientAgentToken(
      agentId: approvedAgentId,
      request: const ClientAgentTokenRequestDto(clientToken: 'tok'),
    );

    final after = await fake.fetchApprovedAgents(query: const PaginatedQuery());
    final afterRow = after.agents.firstWhere(
      (a) => a.agentId == approvedAgentId,
    );
    check(afterRow.hasClientToken).equals(true);

    final detail = await fake.fetchApprovedAgentById(approvedAgentId);
    check(detail.agent.hasClientToken).equals(true);
  });
}
