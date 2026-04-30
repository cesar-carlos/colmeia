import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

void main() {
  late _MockClientAgentsRepository repository;
  late _MockAgentClientTokenReader tokenReader;
  late LoadAvailableAgentsForSales useCase;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    repository = _MockClientAgentsRepository();
    tokenReader = _MockAgentClientTokenReader();
    useCase = LoadAvailableAgentsForSales(repository, tokenReader);
  });

  test('marks agents without resolvable token as missing', () async {
    when(
      () => repository.loadApprovedAgents(
        userId: 'user-1',
        query: const PaginatedQuery(pageSize: 100),
        includeOnlineStatus: false,
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: <ClientAgent>[
            _agent(agentId: 'agent-1', name: 'Agent 1'),
            _agent(agentId: 'agent-2', name: 'Agent 2'),
          ],
          count: 2,
          total: 2,
          page: 1,
          pageSize: 100,
        ),
      ),
    );
    when(
      () => tokenReader.readMany(
        userId: 'user-1',
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer(
      (_) async => <String, String>{
        'agent-1': 'token-1',
      },
    );

    final agents = await useCase('user-1');

    expect(agents, hasLength(2));
    expect(agents[0].agentId, 'agent-1');
    expect(agents[0].missingLocalClientToken, isFalse);
    expect(agents[1].agentId, 'agent-2');
    expect(agents[1].missingLocalClientToken, isTrue);
  });

  test('returns empty list when approved agents load fails', () async {
    when(
      () => repository.loadApprovedAgents(
        userId: 'user-2',
        query: const PaginatedQuery(pageSize: 100),
        includeOnlineStatus: false,
      ),
    ).thenAnswer(
      (_) async => const Failure<PaginatedResult<ClientAgent>, AppFailure>(
        UnknownFailure(message: 'boom'),
      ),
    );

    final agents = await useCase('user-2');

    expect(agents, isEmpty);
    verifyNever(
      () => tokenReader.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    );
  });
}

ClientAgent _agent({
  required String agentId,
  required String name,
}) {
  final timestamp = DateTime.utc(2026, 1, 1);
  return ClientAgent(
    agentId: agentId,
    name: name,
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.unknown,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
