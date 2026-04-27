import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:get_it/get_it.dart';

void registerInjectorOverview(GetIt getIt) {
  getIt
    ..registerLazySingleton<OverviewLocalDataSource>(
      () => OverviewLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<OverviewRepository>(
      () => OverviewRepositoryImpl(
        localDataSource: getIt<OverviewLocalDataSource>(),
        resumoAcrossAgentsRepository:
            getIt<ResumoParcelaFormaPagamentoAcrossAgentsRepository>(),
        loadResumoParcelasMensalAcrossAgents:
            getIt<LoadResumoParcelasMensalAcrossAgentsUseCase>(),
        loadResumoParcelasDiaSemanaAcrossAgents:
            getIt<LoadResumoParcelasDiaSemanaAcrossAgentsUseCase>(),
        loadResumoParcelasDiaSemanaUsuarioAcrossAgents:
            getIt<LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase>(),
        loadResumoProdutoVendaLucratividadeMensal:
            getIt<LoadResumoProdutoVendaLucratividadeMensalUseCase>(),
        loadResumoProdutoVendaLucratividade:
            getIt<LoadResumoProdutoVendaLucratividadeUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadOverviewUseCase>(
      () => LoadOverviewUseCase(getIt<OverviewRepository>()),
    );
}
