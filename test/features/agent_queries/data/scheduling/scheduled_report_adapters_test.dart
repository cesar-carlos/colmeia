import 'package:colmeia/core/di/injector_cache_refresh_reports.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_query_snapshots.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
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
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_schedule.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class ReachedRepository implements Exception {}

class FakeOverview extends RecordingRepository
    implements OverviewRepositoryImpl {}

class FakePackages extends RecordingRepository implements PwaPackageService {}

class RecordingRepository {
  Invocation? invocation;
  bool captured = false;
  @override
  dynamic noSuchMethod(Invocation value) {
    invocation = value;
    captured = ScheduledQueryCapture.current != null;
    throw ReachedRepository();
  }
}

class Tokens implements AgentClientTokenReader {
  @override
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  }) async => {for (final id in agentIds) id: 'test-token'};
}

class FakeResumoTotalVendasMunicipioFilialPeriodo extends RecordingRepository
    implements ResumoTotalVendasMunicipioFilialPeriodoRepository {}

class FakeResumoVendasDiariasPorVendedor extends RecordingRepository
    implements ResumoVendasDiariasPorVendedorRepository {}

class FakeResumoProdutoVendaLucratividadeMensal extends RecordingRepository
    implements ResumoProdutoVendaLucratividadeMensalRepository {}

class FakeResumoProdutoVenda extends RecordingRepository
    implements ResumoProdutoVendaRepository {}

class FakeMargemProduto extends RecordingRepository
    implements MargemProdutoRepository {}

class FakeNotasEntrada extends RecordingRepository
    implements NotasEntradaRepository {}

class FakeNotasEntradaResumoFornecedor extends RecordingRepository
    implements NotasEntradaResumoFornecedorRepository {}

class FakeNotasEntradaItens extends RecordingRepository
    implements NotasEntradaItensRepository {}

class FakeProdutoVendidoTendenciaDeVendaMediaMovel extends RecordingRepository
    implements ProdutoVendidoTendenciaDeVendaMediaMovelRepository {}

class FakeProdutoVendidoTendenciaDeVenda extends RecordingRepository
    implements ProdutoVendidoTendenciaDeVendaRepository {}

void main() {
  for (final section in OverviewProgressiveSection.values) {
    test(
      'overview ${section.name} preserves period and forces refresh',
      () async {
        final getIt = GetIt.asNewInstance();
        addTearDown(getIt.reset);
        final repository = FakeOverview();
        getIt.registerSingleton<OverviewRepositoryImpl>(repository);
        final executor = createReportRefreshExecutor(getIt);
        final schedule = CacheRefreshSchedule(
          id: 'job',
          userId: 'user',
          agentId: 'agent',
          reportId: 'overview.${section.name}',
        );
        final period = schedule.resolvePeriod(DateTime.now());
        await expectLater(
          executor.execute(schedule, period, AgentQueriesCancelScope()),
          throwsA(isA<ReachedRepository>()),
        );
        final call = repository.invocation!;
        expect(call.memberName, #loadOverview);
        expect(call.namedArguments[#policy], OverviewLoadPolicy.forceRefresh);
        final filter = call.namedArguments[#filter]! as DashboardFilter;
        expect(filter.selectedAgentIds, {'agent'});
        expect(filter.referenceRange!.startInclusive, period.start);
        expect(filter.referenceRange!.endInclusive, period.end);
        final sections =
            call.namedArguments[#sectionRequest]! as OverviewSectionRequest;
        expect(sections.restrictToReferencePeriod, isTrue);
        expect(sections.completedWhenFinal(), contains(section));
      },
    );
  }
  test('offline package uses its own atomic publisher without duplicate SQL snapshot', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final packages = FakePackages();
    getIt.registerSingleton<PwaPackageService>(packages);
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'offlinePackage',
    );
    await expectLater(
      executor.execute(
        schedule,
        schedule.resolvePeriod(DateTime.now()),
        AgentQueriesCancelScope(),
      ),
      throwsA(isA<ReachedRepository>()),
    );
    expect(packages.invocation!.memberName, #synchronize);
    expect(packages.invocation!.positionalArguments, ['user', 'agent']);
    expect(packages.captured, isFalse);
  });

  test('salesByBranch delegates to ResumoTotalVendasMunicipioFilialPeriodo.load under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeResumoTotalVendasMunicipioFilialPeriodo();
    getIt
      ..registerSingleton<ResumoTotalVendasMunicipioFilialPeriodoRepository>(
        repository,
      )
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'salesByBranch',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #load);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
    expect(
      call.namedArguments[#cachePolicy],
      AgentQueryLoadPolicy.forceRefresh,
    );
  });

  test('salesBySeller delegates to ResumoVendasDiariasPorVendedor.load under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeResumoVendasDiariasPorVendedor();
    getIt
      ..registerSingleton<ResumoVendasDiariasPorVendedorRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'salesBySeller',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #load);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('monthlyProfit delegates to ResumoProdutoVendaLucratividadeMensal.loadAll under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeResumoProdutoVendaLucratividadeMensal();
    getIt
      ..registerSingleton<ResumoProdutoVendaLucratividadeMensalRepository>(
        repository,
      )
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'monthlyProfit',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadAll);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('productSales delegates to ResumoProdutoVenda.loadPage under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeResumoProdutoVenda();
    getIt
      ..registerSingleton<ResumoProdutoVendaRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'productSales',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadPage);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
  });

  test('productMargin delegates to MargemProduto.loadPage under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeMargemProduto();
    getIt
      ..registerSingleton<MargemProdutoRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'productMargin',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadPage);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('purchaseNotes delegates to NotasEntrada.loadPage under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeNotasEntrada();
    getIt
      ..registerSingleton<NotasEntradaRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'purchaseNotes',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadPage);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('purchaseSuppliers delegates to NotasEntradaResumoFornecedor.loadPage under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeNotasEntradaResumoFornecedor();
    getIt
      ..registerSingleton<NotasEntradaResumoFornecedorRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'purchaseSuppliers',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadPage);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('purchaseItems delegates to NotasEntradaItens.load under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeNotasEntradaItens();
    getIt
      ..registerSingleton<NotasEntradaItensRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'purchaseItems',
      filters: {'compraId': 42},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #load);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('movingAverage delegates to ProdutoVendidoTendenciaDeVendaMediaMovel.loadPageAndSummary under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeProdutoVendidoTendenciaDeVendaMediaMovel();
    getIt
      ..registerSingleton<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(
        repository,
      )
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'movingAverage',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadPageAndSummary);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });

  test('productTrend delegates to ProdutoVendidoTendenciaDeVenda.loadPageAndSummary under forced query capture', () async {
    final getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    final repository = FakeProdutoVendidoTendenciaDeVenda();
    getIt
      ..registerSingleton<ProdutoVendidoTendenciaDeVendaRepository>(repository)
      ..registerSingleton<AgentClientTokenReader>(Tokens());
    final executor = createReportRefreshExecutor(getIt);
    final schedule = CacheRefreshSchedule(
      id: 'job',
      userId: 'user',
      agentId: 'agent',
      reportId: 'productTrend',
      filters: {},
    );
    final now = DateTime.now();
    final period = schedule.resolvePeriod(now);
    final scope = AgentQueriesCancelScope();
    await expectLater(
      executor.execute(schedule, period, scope),
      throwsA(isA<ReachedRepository>()),
    );
    final call = repository.invocation!;
    expect(call.memberName, #loadPageAndSummary);
    expect(call.namedArguments[#userId], 'user');
    expect(call.namedArguments[#agentId], 'agent');
    expect(call.namedArguments[#clientToken], 'test-token');
    expect(repository.captured, isTrue);
    expect(call.namedArguments[#cancelScope], same(scope));
  });
}
