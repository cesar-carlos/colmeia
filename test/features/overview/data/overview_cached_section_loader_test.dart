import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/overview_cached_section_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadDaily extends Mock
    implements LoadResumoTotalDiarioVendasUseCase {}

class _MockLoadMonthly extends Mock
    implements LoadResumoParcelasMensalUseCase {}

class _MockLoadWeekday extends Mock
    implements LoadResumoParcelasDiaSemanaUseCase {}

class _MockLoadLucratividade extends Mock
    implements LoadResumoProdutoVendaLucratividadeUseCase {}

void main() {
  late _MockLoadDaily loadDaily;
  late _MockLoadMonthly loadMonthly;
  late _MockLoadWeekday loadWeekday;
  late _MockLoadLucratividade loadLucratividade;

  const target = AgentQueryTarget(
    agentId: 'agent-1',
    displayName: 'Agent 1',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: 'token',
    hubConnectedFromApprovedCatalogRow: true,
  );

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
    registerFallbackValue(
      ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
    registerFallbackValue(
      ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
    registerFallbackValue(AgentQueryLoadPolicy.defaultLoad);
  });

  setUp(() {
    loadDaily = _MockLoadDaily();
    loadMonthly = _MockLoadMonthly();
    loadWeekday = _MockLoadWeekday();
    loadLucratividade = _MockLoadLucratividade();
  });

  test('loads configured use cases serially in registration order', () async {
    final callOrder = <String>[];
    when(
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer((_) async {
      callOrder.add('daily');
      return const Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
        <ResumoTotalDiarioVendasRow>[],
      );
    });
    when(
      () => loadMonthly.call(
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer((_) async {
      callOrder.add('monthly');
      return const Success<List<ResumoParcelasMensalRow>, AppFailure>(
        <ResumoParcelasMensalRow>[],
      );
    });
    when(
      () => loadWeekday.call(
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer((_) async {
      callOrder.add('weekday');
      return const Success<List<ResumoParcelasDiaSemanaRow>, AppFailure>(
        <ResumoParcelasDiaSemanaRow>[],
      );
    });
    when(
      () => loadLucratividade.call(
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer((_) async {
      callOrder.add('lucratividade');
      return const Success<
        List<ResumoProdutoVendaLucratividadeRow>,
        AppFailure
      >(
        <ResumoProdutoVendaLucratividadeRow>[],
      );
    });

    final loader = OverviewCachedSectionLoader(
      loadDaily: loadDaily,
      loadMonthly: loadMonthly,
      loadWeekday: loadWeekday,
      loadLucratividade: loadLucratividade,
    );

    await loader.load(
      cachePolicy: AgentQueryLoadPolicy.defaultLoad,
      userId: 'user-1',
      target: target,
      mensalFilter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 12, 31),
      ),
      weekdayFilter: ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
      dailyTotalFilter: ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
      planBridgeTimeoutMs: 120000,
      hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
    );

    expect(
      callOrder,
      <String>['daily', 'monthly', 'weekday', 'lucratividade'],
    );
  });

  test('returns null when cancel scope is already cancelled', () async {
    final loader = OverviewCachedSectionLoader(
      loadDaily: loadDaily,
      loadMonthly: loadMonthly,
    );
    final scope = AgentQueriesCancelScope()..cancelAll();

    final result = await loader.load(
      cachePolicy: AgentQueryLoadPolicy.defaultLoad,
      userId: 'user-1',
      target: target,
      mensalFilter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 12, 31),
      ),
      weekdayFilter: ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
      dailyTotalFilter: ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
      planBridgeTimeoutMs: 120000,
      hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
      cancelScope: scope,
    );

    expect(result, isNull);
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    );
  });
}
