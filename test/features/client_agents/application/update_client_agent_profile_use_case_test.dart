import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

void main() {
  late _MockClientAgentsRepository repository;
  late UpdateClientAgentProfileUseCase useCase;

  final agent = ClientAgent(
    agentId: 'a1',
    name: 'Updated',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.offline,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  setUpAll(() {
    registerFallbackValue(
      const AgentProfileUpdateRequest(name: 'fallback'),
    );
  });

  setUp(() {
    repository = _MockClientAgentsRepository();
    useCase = UpdateClientAgentProfileUseCase(repository);
  });

  test('forwards to repository.updateCatalogAgentProfile', () async {
    const request = AgentProfileUpdateRequest(name: 'New Name');
    when(
      () => repository.updateCatalogAgentProfile(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        request: any(named: 'request'),
      ),
    ).thenAnswer((_) async => Success<ClientAgent, AppFailure>(agent));

    final result = await useCase(
      userId: 'user-1',
      agentId: 'a1',
      request: request,
    );

    verify(
      () => repository.updateCatalogAgentProfile(
        userId: 'user-1',
        agentId: 'a1',
        request: request,
      ),
    ).called(1);
    check(result.getOrNull()?.agentId).equals('a1');
  });
}
