import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

void main() {
  late _MockClientAgentsRepository repository;
  late LoadClientAgentDetailUseCase useCase;

  final approved = ClientAgent(
    agentId: 'a1',
    name: 'Approved Name',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.offline,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026, 1, 2),
    email: 'a@x.com',
  );

  final catalogAgent = ClientAgent(
    agentId: 'a1',
    name: 'Catalog Name',
    tradeName: 'Trade',
    catalogStatus: AgentCatalogStatus.inactive,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime(2025, 12),
    updatedAt: DateTime(2026, 1, 3),
    mobile: '11999999999',
  );

  setUp(() {
    repository = _MockClientAgentsRepository();
    useCase = LoadClientAgentDetailUseCase(repository);
  });

  test(
    'should merge catalog connection and fill nulls when both loads succeed',
    () async {
      when(
        () => repository.loadApprovedAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => Success<ClientAgent, AppFailure>(approved),
      );
      when(
        () => repository.loadCatalogAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => Success<ClientAgentCatalogItem, AppFailure>(
          ClientAgentCatalogItem(agent: catalogAgent),
        ),
      );

      final result = await useCase(userId: 'u1', agentId: 'a1');

      final merged = result.getOrNull();
      check(merged).isNotNull();
      check(merged!.name).equals('Approved Name');
      check(merged.tradeName).equals('Trade');
      check(merged.email).equals('a@x.com');
      check(merged.mobile).equals('11999999999');
      check(merged.connectionStatus).equals(AgentConnectionStatus.online);
      check(merged.catalogStatus).equals(AgentCatalogStatus.inactive);
      check(merged.updatedAt).equals(DateTime(2026, 1, 3));
    },
  );

  test('should return approved agent when catalog load fails', () async {
    when(
      () => repository.loadApprovedAgentById(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => Success<ClientAgent, AppFailure>(approved),
    );
    when(
      () => repository.loadCatalogAgentById(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Failure<ClientAgentCatalogItem, AppFailure>(
        NetworkFailure(message: 'x', userMessage: 'y'),
      ),
    );

    final result = await useCase(userId: 'u1', agentId: 'a1');

    check(result.getOrNull()).equals(approved);
  });

  test('should propagate failure when approved load fails', () async {
    when(
      () => repository.loadApprovedAgentById(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Failure<ClientAgent, AppFailure>(
        NetworkFailure(message: 'x', userMessage: 'y'),
      ),
    );
    when(
      () => repository.loadCatalogAgentById(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => Success<ClientAgentCatalogItem, AppFailure>(
        ClientAgentCatalogItem(agent: catalogAgent),
      ),
    );

    final result = await useCase(userId: 'u1', agentId: 'a1');

    check(result.exceptionOrNull()).isNotNull();
  });
}
