import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector_overview.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/application/sync/agent_query_facts_prefetch_coordinator.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_online_agent_ids_use_case.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockOverviewRepository extends Mock implements OverviewRepository {}

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

class _MockLoadDaily extends Mock implements LoadResumoTotalDiarioVendasUseCase {}

class _MockLoadMonthly extends Mock implements LoadResumoParcelasMensalUseCase {}

/// Mirrors production wiring in [registerInjectorOverview] + overview route:
/// shared [RetryAfterGate] singleton and factory-scoped [OverviewController].
void main() {
  late GetIt getIt;
  late _MockOverviewRepository overviewRepository;
  late _MockClientAgentsRepository clientAgentsRepository;
  late _MockLoadDaily loadDaily;
  late _MockLoadMonthly loadMonthly;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
    registerFallbackValue(
      ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 12, 31),
      ),
    );
    registerFallbackValue(AgentQueryLoadPolicy.defaultLoad);
  });

  setUp(() {
    getIt = GetIt.asNewInstance();
    overviewRepository = _MockOverviewRepository();
    clientAgentsRepository = _MockClientAgentsRepository();
    loadDaily = _MockLoadDaily();
    loadMonthly = _MockLoadMonthly();

    when(
      () => clientAgentsRepository.loadOnlineAgentIds(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => null);

    getIt
      ..registerLazySingleton<RetryAfterGate>(RetryAfterGate.new)
      ..registerFactory<OverviewController>(
        () => OverviewController(
          LoadOverviewUseCase(overviewRepository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
          retryAfterGate: getIt<RetryAfterGate>(),
        ),
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  test(
    'second OverviewController from GetIt reuses the same RetryAfterGate '
    'after the first controller is disposed',
    () {
      final gate = getIt<RetryAfterGate>();
      final first = getIt<OverviewController>();
      expect(identical(first.retryAfterGate, gate), isTrue);

      first.dispose();

      final second = getIt<OverviewController>();
      expect(identical(second.retryAfterGate, gate), isTrue);
      expect(second.isOnRetryCooldown, isFalse);
    },
  );

  test('arming the shared gate affects a newly created OverviewController', () {
    final gate = getIt<RetryAfterGate>();
    getIt<OverviewController>().dispose();

    gate.arm(const Duration(seconds: 30));

    final second = getIt<OverviewController>();
    expect(second.isOnRetryCooldown, isTrue);
  });

  test(
    'AgentQueryFactsPrefetchCoordinator still reads shared gate after '
    'OverviewController route teardown',
    () async {
      final gate = getIt<RetryAfterGate>();
      getIt<OverviewController>().dispose();

      gate.arm(const Duration(minutes: 5));

      final coordinator = AgentQueryFactsPrefetchCoordinator(
        loadDaily: loadDaily,
        loadMonthly: loadMonthly,
        retryAfterGate: gate,
      );

      await coordinator.prefetchForPlannedTargets(
        userId: 'user-1',
        targets: const [
          AgentQueryTarget(
            agentId: 'agent-1',
            displayName: 'Agent 1',
            connectionStatus: AgentConnectionStatus.online,
          ),
        ],
        dailyFilter: ResumoTotalDiarioVendasFilter(
          dataVendaInicio: DateTime(2026, 3),
          dataVendaFim: DateTime(2026, 3, 31),
        ),
        monthlyFilter: ResumoParcelasMensalFilter(
          dataVendaInicio: DateTime(2026),
          dataVendaFim: DateTime(2026, 12, 31),
        ),
      );

      if (!AppEnvironment.agentQueryFactsPrefetchEnabled) {
        return;
      }

      verifyNever(
        () => loadDaily.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
          cachePolicy: any(named: 'cachePolicy'),
        ),
      );
    },
  );
}
