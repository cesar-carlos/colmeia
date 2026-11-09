import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_report_refresh_executor.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_itens_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_resumo_fornecedor_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_mensal_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_report.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:get_it/get_it.dart';

RegisteredReportRefreshExecutor createReportRefreshExecutor(GetIt getIt) {
  final reports = <CacheRefreshReport>[
    const CacheRefreshReport('overview.summary', 'Resumo de vendas'),
    const CacheRefreshReport('overview.paymentMix', 'Formas de pagamento'),
    const CacheRefreshReport('overview.userRanking', 'Vendas por usuário'),
    const CacheRefreshReport('overview.agentRanking', 'Ranking de agentes'),
    const CacheRefreshReport('overview.dailySales', 'Vendas diárias'),
    const CacheRefreshReport('overview.monthlyParcels', 'Parcelas mensais'),
    const CacheRefreshReport(
      'overview.weekdaySales',
      'Vendas por dia da semana',
    ),
    const CacheRefreshReport(
      'overview.weekdayUserSales',
      'Vendas por usuário e dia da semana',
    ),
    const CacheRefreshReport(
      'overview.lucratividadePeriod',
      'Lucratividade no período',
    ),
    const CacheRefreshReport(
      'salesByBranch',
      'Vendas por filial e município',
    ),
    const CacheRefreshReport(
      'salesBySeller',
      'Vendas diárias por vendedor',
      fields: {
        'codVendedor': RefreshFilterType.integer,
        'bairro': RefreshFilterType.text,
        'municipio': RefreshFilterType.text,
      },
    ),
    const CacheRefreshReport(
      'monthlyProfit',
      'Lucratividade mensal',
    ),
    const CacheRefreshReport(
      'productSales',
      'Vendas por produto',
      fields: {
        'origem': RefreshFilterType.text,
        'page': RefreshFilterType.integer,
        'pageSize': RefreshFilterType.integer,
      },
      note: 'Consulta paginada: somente a página configurada é armazenada.',
    ),
    const CacheRefreshReport(
      'productMargin',
      'Margem por produto',
      fields: {
        'searchTerm': RefreshFilterType.text,
        'page': RefreshFilterType.integer,
        'pageSize': RefreshFilterType.integer,
      },
      supportsFixedPeriod: false,
      note: 'Usa o período próprio da consulta; margem e itens representam a posição atual.',
    ),
    const CacheRefreshReport(
      'purchaseNotes',
      'Notas de entrada',
      fields: {
        'searchTerm': RefreshFilterType.text,
        'codFornecedor': RefreshFilterType.integer,
        'codEmpresa': RefreshFilterType.integer,
        'codFilial': RefreshFilterType.integer,
        'page': RefreshFilterType.integer,
        'pageSize': RefreshFilterType.integer,
      },
      note: 'Consulta paginada: somente a página configurada é armazenada.',
    ),
    const CacheRefreshReport(
      'purchaseSuppliers',
      'Compras por fornecedor',
      fields: {
        'codFornecedor': RefreshFilterType.integer,
        'codEmpresa': RefreshFilterType.integer,
        'codFilial': RefreshFilterType.integer,
        'page': RefreshFilterType.integer,
        'pageSize': RefreshFilterType.integer,
      },
      note: 'Consulta paginada: somente a página configurada é armazenada.',
    ),
    const CacheRefreshReport(
      'purchaseItems',
      'Itens de uma nota de entrada',
      fields: {'compraId': RefreshFilterType.integer},
      supportsFixedPeriod: false,
      note: 'Usa o período próprio da consulta; margem e itens representam a posição atual.',
    ),
    const CacheRefreshReport(
      'movingAverage',
      'Tendência por média móvel',
      fields: {
        'searchTerm': RefreshFilterType.text,
        'codFilial': RefreshFilterType.integer,
        'codMarca': RefreshFilterType.integer,
        'codGrupoProduto': RefreshFilterType.integer,
        'page': RefreshFilterType.integer,
        'pageSize': RefreshFilterType.integer,
      },
      supportsFixedPeriod: false,
      note: 'Usa o período próprio da consulta; margem e itens representam a posição atual.',
    ),
    const CacheRefreshReport(
      'productTrend',
      'Tendência de vendas por produto',
      fields: {
        'searchTerm': RefreshFilterType.text,
        'codFilial': RefreshFilterType.integer,
        'page': RefreshFilterType.integer,
        'pageSize': RefreshFilterType.integer,
      },
      note: 'Consulta paginada: somente a página configurada é armazenada.',
    ),
    const CacheRefreshReport(
      'offlinePackage',
      'Pacote offline',
      supportsFixedPeriod: false,
    ),
  ];
  final handlers = <String, ScheduledReportHandler>{
    'salesByBranch': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: p.start,
        dataVendaFim: p.end,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<ResumoTotalVendasMunicipioFilialPeriodoRepository>().load(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      )).getOrThrow();
    },
    'salesBySeller': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: p.start,
        dataVendaFim: p.end,
        codVendedor: s.filters['codVendedor'] as int?,
        bairro: s.filters['bairro'] as String?,
        municipio: s.filters['municipio'] as String?,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<ResumoVendasDiariasPorVendedorRepository>().load(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
      )).getOrThrow();
    },
    'monthlyProfit': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: p.start,
        dataVendaFim: p.end,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<ResumoProdutoVendaLucratividadeMensalRepository>().loadAll(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
      )).getOrThrow();
    },
    'productSales': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = ResumoProdutoVendaFilter(
        dataVendaInicio: p.start,
        dataVendaFim: p.end,
        origem: (s.filters['origem'] as String?) ?? 'FrenteLoja',
        page: (s.filters['page'] as int?) ?? 1,
        pageSize: (s.filters['pageSize'] as int?) ?? 20,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<ResumoProdutoVendaRepository>().loadPage(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
      )).getOrThrow();
    },
    'productMargin': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = MargemProdutoFilter(
        searchTerm: s.filters['searchTerm'] as String?,
        page: (s.filters['page'] as int?) ?? 1,
        pageSize: (s.filters['pageSize'] as int?) ?? 20,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<MargemProdutoRepository>().loadPage(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
      )).getOrThrow();
    },
    'purchaseNotes': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = NotasEntradaFilter(
        dataLancamentoInicio: p.start,
        dataLancamentoFim: p.end,
        searchTerm: s.filters['searchTerm'] as String?,
        codFornecedor: s.filters['codFornecedor'] as int?,
        codEmpresa: (s.filters['codEmpresa'] as int?) ?? 1,
        codFilial: (s.filters['codFilial'] as int?) ?? 1,
        page: (s.filters['page'] as int?) ?? 1,
        pageSize: (s.filters['pageSize'] as int?) ?? 50,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<NotasEntradaRepository>().loadPage(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
      )).getOrThrow();
    },
    'purchaseSuppliers': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = NotasEntradaFilter(
        dataLancamentoInicio: p.start,
        dataLancamentoFim: p.end,
        codFornecedor: s.filters['codFornecedor'] as int?,
        codEmpresa: (s.filters['codEmpresa'] as int?) ?? 1,
        codFilial: (s.filters['codFilial'] as int?) ?? 1,
        page: (s.filters['page'] as int?) ?? 1,
        pageSize: (s.filters['pageSize'] as int?) ?? 50,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<NotasEntradaResumoFornecedorRepository>().loadPage(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
      )).getOrThrow();
    },
    'purchaseItems': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = NotasEntradaItensFilter(
        compraId: (s.filters['compraId'] as int?) ?? 0,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<NotasEntradaItensRepository>().load(
        userId: s.userId,
        agentId: s.agentId,
        filter: filter,
        clientToken: tokens[s.agentId],
        cancelScope: scope,
      )).getOrThrow();
    },
    'movingAverage': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 30,
        searchTerm: s.filters['searchTerm'] as String?,
        codFilial: s.filters['codFilial'] as int?,
        codMarca: s.filters['codMarca'] as int?,
        codGrupoProduto: s.filters['codGrupoProduto'] as int?,
        page: (s.filters['page'] as int?) ?? 1,
        pageSize: (s.filters['pageSize'] as int?) ?? 20,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>()
              .loadPageAndSummary(
                userId: s.userId,
                agentId: s.agentId,
                filter: filter,
                clientToken: tokens[s.agentId],
                cancelScope: scope,
              ))
          .getOrThrow();
    },
    'productTrend': (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: p.start,
        periodoAtualFim: p.end,
        periodoAnteriorInicio: p.start.subtract(
          Duration(days: p.end.difference(p.start).inDays + 1),
        ),
        periodoAnteriorFim: p.start.subtract(const Duration(days: 1)),
        searchTerm: s.filters['searchTerm'] as String?,
        codFilial: s.filters['codFilial'] as int?,
        page: (s.filters['page'] as int?) ?? 1,
        pageSize: (s.filters['pageSize'] as int?) ?? 20,
      );
      final invalid = filter.validationError();
      if (invalid != null) throw ValidationFailure(message: invalid);
      final tokens = await getIt<AgentClientTokenReader>().readMany(
        userId: s.userId,
        agentIds: [s.agentId],
      );
      (await getIt<ProdutoVendidoTendenciaDeVendaRepository>()
              .loadPageAndSummary(
                userId: s.userId,
                agentId: s.agentId,
                pageFilter: filter,
                summaryFilter: filter,
                clientToken: tokens[s.agentId],
                cancelScope: scope,
              ))
          .getOrThrow();
    },
    'offlinePackage': (s, p, scope) async {
      await getIt<PwaPackageService>().synchronize(
        s.userId,
        s.agentId,
        cancelScope: scope,
        ifStale: true,
      );
    },
  };
  for (final section in OverviewProgressiveSection.values) {
    handlers['overview.${section.name}'] = (s, p, scope) async {
      wireAgentQueriesCancelScopeHandlers(getIt, scope);
      final request = OverviewSectionRequest.forChartSection(section);
      final result = (await getIt<OverviewRepositoryImpl>().loadOverview(
        userId: s.userId,
        policy: OverviewLoadPolicy.forceRefresh,
        cancelScope: scope,
        filter: DashboardFilter(
          selectedAgentIds: {s.agentId},
          referenceRange: DashboardDateRange(
            startInclusive: p.start,
            endInclusive: p.end,
          ),
        ),
        sectionRequest: OverviewSectionRequest(
          runMainBatch: request.runMainBatch,
          mainBatchIncludePaymentResumo: request.mainBatchIncludePaymentResumo,
          mainBatchIncludeUserRanking: request.mainBatchIncludeUserRanking,
          sectionBatchSections: request.sectionBatchSections,
          restrictToReferencePeriod: true,
        ),
      )).getOrThrow();
      if (result.hasPartialAgentQueryFailure ||
          result.hasMissingClientToken ||
          result.hasAgentsSkippedDueToHubPresence ||
          result.hasLucratividadePartialFailure ||
          result.dailySalesTrendLoadFailed ||
          result.monthlyParcelTrendLoadFailed ||
          result.weekdaySalesTrendLoadFailed ||
          result.weekdayUserSalesTrendLoadFailed ||
          result.agentRankingsLoadFailed ||
          result.userRankingsLoadFailed ||
          result.lucratividadeTrendLoadFailed) {
        throw const NetworkFailure(message: 'incomplete_scheduled_report');
      }
    };
  }
  return RegisteredReportRefreshExecutor(reports, handlers);
}
