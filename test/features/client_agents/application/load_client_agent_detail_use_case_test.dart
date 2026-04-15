import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
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

  setUp(() {
    repository = _MockClientAgentsRepository();
    useCase = LoadClientAgentDetailUseCase(repository);
  });

  test('loads detail from approved-agent endpoint only', () async {
    when(
      () => repository.loadApprovedAgentById(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => Success<ClientAgent, AppFailure>(approved));

    final result = await useCase(userId: 'u1', agentId: 'a1');

    check(result.getOrNull()).equals(approved);
    verify(
      () => repository.loadApprovedAgentById(userId: 'u1', agentId: 'a1'),
    ).called(1);
    verifyNever(
      () => repository.loadCatalogAgentById(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    );
  });

  test('propagates failure when approved load fails', () async {
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

    final result = await useCase(userId: 'u1', agentId: 'a1');

    check(result.exceptionOrNull()).isNotNull();
  });
}
