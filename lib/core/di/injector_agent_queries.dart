import 'dart:async';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_metrics_listener.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/agent_sql_cancel_emitter.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/sync/agent_query_facts_prefetch_coordinator.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_municipios_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_produto_rank_lucro_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_ranking_produtos_faturamento_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case_v2.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_diario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_diario_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case_v2.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_por_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_por_usuario_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_diario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_diario_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_all_filter_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/resolve_cadastro_filial_location_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execution_eligibility_checker.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_mensal_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/collecting_relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/hybrid_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/routing_relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_with_rest_fallback_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/facts/hive_agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_chain_factory.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/cadastro_filial_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/cadastro_filial_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/grupo_produto_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/marca_produto_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/metrics_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/municipio_list_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_produto_rank_lucro_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_media_movel_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/ranking_produtos_faturamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl_v2.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl_v2.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_por_usuario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_por_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_usuario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_diario_vendas_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_diario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_periodo_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_periodo_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/streaming_sql_execute_collector.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store_metrics.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/grupo_produto_options_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/marca_produto_options_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/ranking_produtos_faturamento_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_por_usuario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_por_usuario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_usuario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_usuario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_mensal_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_diario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_diario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/shared/maps/resolve_postal_address_location_use_case.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_invalidator.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void registerInjectorAgentQueries(GetIt getIt) {
  getIt.registerLazySingleton<ResolveCadastroFilialLocationUseCase>(
    () => ResolveCadastroFilialLocationUseCase(
      getIt<ResolvePostalAddressLocationUseCase>(),
    ),
  );
  _registerAgentQueryTransport(getIt);
  _registerAgentQueriesRepositoryChain(getIt);
  _registerSingleAgentQueryRepositories(getIt);
  _registerAcrossAgentQueryRepositories(getIt);
  if (!getIt.isRegistered<RetryAfterGate>()) {
    getIt.registerLazySingleton<RetryAfterGate>(RetryAfterGate.new);
  }
  getIt.registerLazySingleton<AgentQueryFactsPrefetchCoordinator>(
    () => AgentQueryFactsPrefetchCoordinator(
      loadDaily: getIt<LoadResumoTotalDiarioVendasUseCase>(),
      loadMonthly: getIt<LoadResumoParcelasMensalUseCase>(),
      retryAfterGate: getIt<RetryAfterGate>(),
    ),
  );
  _registerFilterOptionsRepositories(getIt);
  _registerStreamingRelay(getIt);
  wireAgentQueriesSocketMetricsExport(getIt);
}

/// Attaches SQL metrics export to [SocketMetricsListener] after both stacks
/// are registered.
void wireAgentQueriesSocketMetricsExport(GetIt getIt) {
  if (!getIt.isRegistered<SocketMetricsListener>()) {
    return;
  }
  if (!getIt.isRegistered<MetricsAgentQueriesRepository>()) {
    return;
  }
  getIt<SocketMetricsListener>().sqlAppendix = () {
    final chain = getIt<AgentQueriesRepositoryChain>();
    final metrics = getIt<MetricsAgentQueriesRepository>();
    return <String, Object?>{
      ...metrics.appendixForSocketExport(),
      ...MetricsAgentQueriesRepository.repositoryLayerAppendix(
        cache: chain.cachingRepository,
        coalescing: chain.coalescingRepository,
      ),
      ...AgentQueryFactsStoreMetrics.instance.appendix(),
    };
  };
}

/// Wires transport cancel handlers for [AgentQueriesCancelScope].
void wireAgentQueriesCancelScopeHandlers(
  GetIt getIt,
  AgentQueriesCancelScope scope,
) {
  if (getIt.isRegistered<RelayCommandDispatcher>()) {
    final dispatcher = getIt<RelayCommandDispatcher>();
    scope.relayCancelHandler = (clientRequestIds) {
      clientRequestIds.forEach(dispatcher.cancel);
    };
  } else {
    scope.relayCancelHandler = null;
  }

  if (getIt.isRegistered<SocketCommandDispatcher>()) {
    final socket = getIt<SocketCommandDispatcher>();
    scope.socketRpcCancelHandler = (rpcIds) {
      rpcIds.forEach(socket.cancel);
    };
  } else {
    scope.socketRpcCancelHandler = null;
  }

  if (getIt.isRegistered<AgentSqlCancelEmitter>()) {
    final emitter = getIt<AgentSqlCancelEmitter>();
    scope.streamingSqlCancelHandler = (targets) {
      for (final target in targets) {
        unawaited(
          emitter.cancelStream(
            agentId: target.agentId,
            streamId: target.streamId,
            clientToken: target.clientToken,
          ),
        );
      }
    };
  } else {
    scope.streamingSqlCancelHandler = null;
  }
}

/// Wires [AgentQueriesCancelScope.relayCancelHandler] to fail-fast pending
/// relay unary/streaming RPCs when the scope is abandoned.
void wireAgentQueriesRelayCancelHandler(
  GetIt getIt,
  AgentQueriesCancelScope scope,
) {
  wireAgentQueriesCancelScopeHandlers(getIt, scope);
}

void _onAgentQueriesRestFallbackLatched(
  GetIt getIt,
  SocketDispatchException trigger,
  String latchLabel,
) {
  if (getIt.isRegistered<SocketChannelMetrics>()) {
    getIt<SocketChannelMetrics>().recordRestFallbackLatch();
  }
  AppLogger.warning(
    '$latchLabel latched to REST fallback',
    context: <String, Object?>{
      'triggerCode': trigger.code,
      'triggerMessage': trigger.message,
      'transport': AppEnvironment.agentBridgeTransport.wireValue,
    },
  );
  unawaited(
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'agent_queries.transport',
        message: 'REST fallback latched ($latchLabel)',
        data: <String, String>{
          'triggerCode': trigger.code,
          'triggerMessage': trigger.message,
          'latchLabel': latchLabel,
        },
        level: SentryLevel.warning,
      ),
    ),
  );
}

void _registerAgentQueryTransport(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentSqlExecutionEligibilityPolicy>(
      () => const AgentSqlExecutionEligibilityPolicy(),
    )
    ..registerLazySingleton<AgentSqlExecuteRequestToBridgeBody>(
      () => const AgentSqlExecuteRequestToBridgeBody(),
    )
    ..registerLazySingleton<AgentSqlExecuteBatchRequestToBridgeBody>(
      () => const AgentSqlExecuteBatchRequestToBridgeBody(),
    )
    ..registerLazySingleton<AgentQueriesRemoteDataSource>(
      () {
        if (AppEnvironment.useFakeBackend) {
          return FakeAgentQueriesRemoteDataSource();
        }
        final rest = ApiAgentQueriesRemoteDataSource(
          dio: getIt<Dio>(),
          bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
          onServerTimings: getIt.isRegistered<SocketChannelMetrics>()
              ? (timings) =>
                    getIt<SocketChannelMetrics>().recordServerTimings(timings)
              : null,
        );
        final relay = _resolveRelayDatasource(getIt);
        AgentQueriesRemoteDataSource wrapWithRestFallback({
          required AgentQueriesRemoteDataSource socketDelegate,
          required String latchLabel,
        }) {
          return SocketWithRestFallbackAgentQueriesRemoteDataSource(
            socketDelegate: socketDelegate,
            restDelegate: rest,
            onFallback: (trigger) =>
                _onAgentQueriesRestFallbackLatched(getIt, trigger, latchLabel),
          );
        }

        final relayFallback = relay == null
            ? null
            : wrapWithRestFallback(
                socketDelegate: relay,
                latchLabel: 'Relay AgentQueriesRemoteDataSource',
              );
        AgentQueriesRemoteDataSource legacySocketBase() {
          return wrapWithRestFallback(
            socketDelegate: SocketAgentQueriesRemoteDataSource(
              sender: getIt<AgentCommandSender>(),
              bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
            ),
            latchLabel: 'AgentQueriesRemoteDataSource',
          );
        }

        // When relay is available on socket transport, route all SQL
        // (including `useRelay: false`) through relay unary instead of
        // `agents:command`, which hangs when the hub does not respond.
        final base = switch (AppEnvironment.agentBridgeTransport) {
          AgentBridgeTransport.socket => relayFallback ?? legacySocketBase(),
          AgentBridgeTransport.rest => rest,
        };
        // PR-L+ part 1: wrap with the per-call selector when the relay
        // datasource is available (SOCKET_RELAY_ENABLED=true). Requests
        // with `useRelay: true` flow through the relay channel; on REST
        // transport everything else stays on REST.
        final relayWrapped = relay == null
            ? base
            : HybridAgentQueriesRemoteDataSource(
                baseDelegate: base,
                relayDelegate: relayFallback,
              );
        AppLogger.info(
          'AgentQueriesRemoteDataSource initialized',
          context: <String, Object?>{
            'transport': AppEnvironment.agentBridgeTransport.wireValue,
            'relayEnabled': relay != null,
            'baseUsesRelayOnSocket':
                AppEnvironment.agentBridgeTransport ==
                    AgentBridgeTransport.socket &&
                relay != null,
            'baseUsesSocketRestFallback':
                AppEnvironment.agentBridgeTransport ==
                    AgentBridgeTransport.socket &&
                relay == null,
            'relayUsesSocketRestFallback': relay != null,
          },
        );
        return relayWrapped;
      },
    )
    ..registerLazySingleton<AgentSqlExecutionEligibilityPort>(
      () => AgentSqlExecutionEligibilityChecker(
        clientAgentsRepository: getIt<ClientAgentsRepository>(),
        policy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    );
}

void _registerAgentQueriesRepositoryChain(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentQueriesRepositoryChain>(() {
    final chain = AgentQueriesRepositoryChainFactory.build(
      remoteDataSource: getIt<AgentQueriesRemoteDataSource>(),
      eligibility: getIt<AgentSqlExecutionEligibilityPort>(),
      maxCacheSize: AppEnvironment.agentSqlCacheMaxSize,
      cacheTtl: Duration(milliseconds: AppEnvironment.agentSqlCacheTtlMs),
      catalogCacheTtl: AppEnvironment.agentSqlCatalogCacheTtlMs > 0
          ? Duration(milliseconds: AppEnvironment.agentSqlCatalogCacheTtlMs)
          : null,
      agentSqlRestMaxInflightPerAgent:
          AppEnvironment.agentSqlRestMaxInflightPerAgent,
    );

    final cache = chain.cachingRepository;
    AppLogger.info(
      'AgentQueriesRepository decorator chain initialized',
      context: <String, Object?>{
        'decorators': chain.decorators,
        'agentSqlCacheMaxSize': AppEnvironment.agentSqlCacheMaxSize,
        'agentSqlCacheTtlMs': AppEnvironment.agentSqlCacheTtlMs,
        'agentSqlRestMaxInflightPerAgent':
            AppEnvironment.agentSqlRestMaxInflightPerAgent,
        'sqlCacheHits': cache.cacheHits,
        'sqlCacheMisses': cache.cacheMisses,
        'sqlBatchCacheHits': cache.batchCacheHits,
        'sqlBatchCacheMisses': cache.batchCacheMisses,
        'sqlCacheSize': cache.cacheSize,
      },
    );

    return chain;
  })
    ..registerLazySingleton<MetricsAgentQueriesRepository>(
      () => getIt<AgentQueriesRepositoryChain>().metricsRepository,
    )
    ..registerLazySingleton<AgentQueriesRepository>(
      () => getIt<AgentQueriesRepositoryChain>().repository,
    );
}

void _registerSingleAgentQueryRepositories(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentQueryFactsStore>(
      () => HiveAgentQueryFactsStore(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton(ResumoTotalDiarioVendasCacheStrategy.new)
    ..registerLazySingleton(ResumoParcelasMensalCacheStrategy.new);

  _registerSingle<CadastroFilialRepository, LoadCadastroFilialPageUseCase>(
    getIt,
    repo: () => CadastroFilialRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () =>
        LoadCadastroFilialPageUseCase(getIt<CadastroFilialRepository>()),
  );

  _registerSingle<MunicipioListRepository, LoadMunicipiosPageUseCase>(
    getIt,
    repo: () => MunicipioListRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadMunicipiosPageUseCase(getIt<MunicipioListRepository>()),
  );

  _registerSingle<
    GrupoProdutoOptionsRepository,
    LoadGrupoProdutoOptionsUseCase
  >(
    getIt,
    repo: () =>
        GrupoProdutoOptionsRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadGrupoProdutoOptionsUseCase(
      getIt<GrupoProdutoOptionsRepository>(),
    ),
  );

  _registerSingle<
    MarcaProdutoOptionsRepository,
    LoadMarcaProdutoOptionsUseCase
  >(
    getIt,
    repo: () =>
        MarcaProdutoOptionsRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadMarcaProdutoOptionsUseCase(
      getIt<MarcaProdutoOptionsRepository>(),
    ),
  );

  _registerSingle<
    ResumoProdutoVendaRepository,
    LoadResumoProdutoVendaPageUseCase
  >(
    getIt,
    repo: () =>
        ResumoProdutoVendaRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadResumoProdutoVendaPageUseCase(
      getIt<ResumoProdutoVendaRepository>(),
    ),
  );

  _registerSingle<
    ResumoProdutoVendaLucratividadeMensalRepository,
    LoadResumoProdutoVendaLucratividadeMensalUseCase
  >(
    getIt,
    repo: () => ResumoProdutoVendaLucratividadeMensalRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoProdutoVendaLucratividadeMensalUseCase(
      getIt<ResumoProdutoVendaLucratividadeMensalRepository>(),
    ),
  );

  _registerSingle<
    ResumoProdutoVendaLucratividadeRepository,
    LoadResumoProdutoVendaLucratividadeUseCase
  >(
    getIt,
    repo: () => ResumoProdutoVendaLucratividadeRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoProdutoVendaLucratividadeUseCase(
      getIt<ResumoProdutoVendaLucratividadeRepository>(),
    ),
  );

  _registerSingle<
    ProdutoVendidoProdutoRankLucroRepository,
    LoadProdutoVendidoProdutoRankLucroUseCase
  >(
    getIt,
    repo: () => ProdutoVendidoProdutoRankLucroRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadProdutoVendidoProdutoRankLucroUseCase(
      getIt<ProdutoVendidoProdutoRankLucroRepository>(),
    ),
  );

  _registerSingle<
    RankingProdutosFaturamentoRepository,
    LoadRankingProdutosFaturamentoUseCase
  >(
    getIt,
    repo: () => RankingProdutosFaturamentoRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadRankingProdutosFaturamentoUseCase(
      getIt<RankingProdutosFaturamentoRepository>(),
    ),
  );

  _registerSingle<
    ProdutoVendidoTendenciaDeVendaMediaMovelRepository,
    LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase
  >(
    getIt,
    repo: () => ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase(
      getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
    ),
  );
  getIt
    ..registerLazySingleton<
      LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase
    >(
      () => LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
    >(
      () => LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
      ),
    );

  _registerSingle<
    ProdutoVendidoTendenciaDeVendaRepository,
    LoadProdutoVendidoTendenciaDeVendaUseCase
  >(
    getIt,
    repo: () => ProdutoVendidoTendenciaDeVendaRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadProdutoVendidoTendenciaDeVendaUseCase(
      getIt<ProdutoVendidoTendenciaDeVendaRepository>(),
    ),
  );
  getIt
    ..registerLazySingleton<LoadProdutoVendidoTendenciaDeVendaSummaryUseCase>(
      () => LoadProdutoVendidoTendenciaDeVendaSummaryUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaRepository>(),
      ),
    )
    ..registerLazySingleton<LoadProdutoVendidoTendenciaDeVendaScreenUseCase>(
      () => LoadProdutoVendidoTendenciaDeVendaScreenUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaRepository>(),
      ),
    );

  _registerSingle<
    ResumoParcelaFormaPagamentoRepository,
    LoadResumoParcelaFormaPagamentoUseCase
  >(
    getIt,
    repo: () => ResumoParcelaFormaPagamentoRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaFormaPagamentoUseCase(
      getIt<ResumoParcelaFormaPagamentoRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelaFormaPagamentoRepositoryV2,
    LoadResumoParcelaFormaPagamentoUseCaseV2
  >(
    getIt,
    repo: () => ResumoParcelaFormaPagamentoRepositoryImplV2(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaFormaPagamentoUseCaseV2(
      getIt<ResumoParcelaFormaPagamentoRepositoryV2>(),
    ),
  );

  _registerSingle<
    ResumoParcelaPorUsuarioRepository,
    LoadResumoParcelaPorUsuarioUseCase
  >(
    getIt,
    repo: () => ResumoParcelaPorUsuarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaPorUsuarioUseCase(
      getIt<ResumoParcelaPorUsuarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelaFormaPagamentoDiarioRepository,
    LoadResumoParcelaFormaPagamentoDiarioUseCase
  >(
    getIt,
    repo: () => ResumoParcelaFormaPagamentoDiarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaFormaPagamentoDiarioUseCase(
      getIt<ResumoParcelaFormaPagamentoDiarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasDiaSemanaRepository,
    LoadResumoParcelasDiaSemanaUseCase
  >(
    getIt,
    repo: () => ResumoParcelasDiaSemanaRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelasDiaSemanaUseCase(
      getIt<ResumoParcelasDiaSemanaRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasDiaSemanaUsuarioRepository,
    LoadResumoParcelasDiaSemanaUsuarioUseCase
  >(
    getIt,
    repo: () => ResumoParcelasDiaSemanaUsuarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelasDiaSemanaUsuarioUseCase(
      getIt<ResumoParcelasDiaSemanaUsuarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasAnualRepository,
    LoadResumoParcelasAnualUseCase
  >(
    getIt,
    repo: () =>
        ResumoParcelasAnualRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () =>
        LoadResumoParcelasAnualUseCase(getIt<ResumoParcelasAnualRepository>()),
  );

  _registerSingle<
    ResumoParcelasFormaPagamentoPorMesRepository,
    LoadResumoParcelasFormaPagamentoPorMesUseCase
  >(
    getIt,
    repo: () => ResumoParcelasFormaPagamentoPorMesRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelasFormaPagamentoPorMesUseCase(
      getIt<ResumoParcelasFormaPagamentoPorMesRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasMensalRepository,
    LoadResumoParcelasMensalUseCase
  >(
    getIt,
    repo: () => CachingResumoParcelasMensalRepositoryImpl(
      delegate: ResumoParcelasMensalRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
      factsStore: getIt<AgentQueryFactsStore>(),
      strategy: getIt<ResumoParcelasMensalCacheStrategy>(),
    ),
    useCase: () => LoadResumoParcelasMensalUseCase(
      getIt<ResumoParcelasMensalRepository>(),
    ),
  );

  _registerSingle<
    ResumoVendasDiariasPorVendedorRepository,
    LoadResumoVendasDiariasPorVendedorUseCase
  >(
    getIt,
    repo: () => ResumoVendasDiariasPorVendedorRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoVendasDiariasPorVendedorUseCase(
      getIt<ResumoVendasDiariasPorVendedorRepository>(),
    ),
  );

  _registerSingle<
    ResumoTotalDiarioVendasRepository,
    LoadResumoTotalDiarioVendasUseCase
  >(
    getIt,
    repo: () => CachingResumoTotalDiarioVendasRepositoryImpl(
      delegate: ResumoTotalDiarioVendasRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
      factsStore: getIt<AgentQueryFactsStore>(),
      strategy: getIt<ResumoTotalDiarioVendasCacheStrategy>(),
    ),
    useCase: () => LoadResumoTotalDiarioVendasUseCase(
      getIt<ResumoTotalDiarioVendasRepository>(),
    ),
  );

  _registerSingle<
    ResumoTotalVendasMunicipioFilialDiarioRepository,
    LoadResumoTotalVendasMunicipioFilialDiarioUseCase
  >(
    getIt,
    repo: () => ResumoTotalVendasMunicipioFilialDiarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoTotalVendasMunicipioFilialDiarioUseCase(
      getIt<ResumoTotalVendasMunicipioFilialDiarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoTotalVendasMunicipioFilialPeriodoRepository,
    LoadResumoTotalVendasMunicipioFilialPeriodoUseCase
  >(
    getIt,
    repo: () => ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoTotalVendasMunicipioFilialPeriodoUseCase(
      getIt<ResumoTotalVendasMunicipioFilialPeriodoRepository>(),
    ),
  );
}

void _registerAcrossAgentQueryRepositories(GetIt getIt) {
  // mergeAllConcurrency caps parallel bridge calls per wave; aligns with
  // AGENT_QUERY_MERGE_ALL_CONCURRENCY and per-agent inflight limits.
  final mergeAllConcurrency = AppEnvironment.agentQueryMergeAllConcurrency;
  getIt
    ..registerLazySingleton<AgentQueryTargetResolver>(
      () => AgentQueryTargetResolver(
        clientAgentsRepository: getIt(),
        clientTokenReader: getIt<AgentClientTokenReader>(),
        policy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    )
    ..registerLazySingleton<AgentQueryTargetResolutionInvalidator>(
      () => getIt<AgentQueryTargetResolver>(),
    )
    ..registerLazySingleton<AgentQueryPlanBuilder>(
      () => AgentQueryPlanBuilder(
        sqlPresencePolicy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>>(
      () => AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2>>(
      () => AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelaPorUsuarioRow>>(
      () => AgentQueryExecutor<ResumoParcelaPorUsuarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoVendaProdutoDiarioRow>>(
      () => AgentQueryExecutor<ResumoVendaProdutoDiarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasDiaSemanaRow>>(
      () => AgentQueryExecutor<ResumoParcelasDiaSemanaRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>
    >(
      () => AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasAnualRow>>(
      () => AgentQueryExecutor<ResumoParcelasAnualRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>
    >(
      () => AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasMensalRow>>(
      () => AgentQueryExecutor<ResumoParcelasMensalRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>
    >(
      () => AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoTotalDiarioVendasRow>>(
      () => AgentQueryExecutor<ResumoTotalDiarioVendasRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<CadastroFilialRow>>(
      () => AgentQueryExecutor<CadastroFilialRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>
    >(
      () => AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >(
      () => AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<ResumoParcelaFormaPagamentoAcrossAgentsRepository>(
      () => ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>>(),
        loadResumo: getIt<LoadResumoParcelaFormaPagamentoUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase>(
      () => LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase(
        getIt<ResumoParcelaFormaPagamentoAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2>(
      () => ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImplV2(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2>>(),
        loadResumo: getIt<LoadResumoParcelaFormaPagamentoUseCaseV2>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaFormaPagamentoAcrossAgentsUseCaseV2>(
      () => LoadResumoParcelaFormaPagamentoAcrossAgentsUseCaseV2(
        getIt<ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelaPorUsuarioAcrossAgentsRepository>(
      () => ResumoParcelaPorUsuarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelaPorUsuarioRow>>(),
        loadResumo: getIt<LoadResumoParcelaPorUsuarioUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaPorUsuarioAcrossAgentsUseCase>(
      () => LoadResumoParcelaPorUsuarioAcrossAgentsUseCase(
        getIt<ResumoParcelaPorUsuarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepository
    >(
      () => ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoVendaProdutoDiarioRow>>(),
        loadResumo: getIt<LoadResumoParcelaFormaPagamentoDiarioUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase
    >(
      () => LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase(
        getIt<ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasDiaSemanaAcrossAgentsRepository>(
      () => ResumoParcelasDiaSemanaAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelasDiaSemanaRow>>(),
        loadResumo: getIt<LoadResumoParcelasDiaSemanaUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasDiaSemanaAcrossAgentsUseCase>(
      () => LoadResumoParcelasDiaSemanaAcrossAgentsUseCase(
        getIt<ResumoParcelasDiaSemanaAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepository
    >(
      () => ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>>(),
        loadResumo: getIt<LoadResumoParcelasDiaSemanaUsuarioUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase
    >(
      () => LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase(
        getIt<ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasAnualAcrossAgentsRepository>(
      () => ResumoParcelasAnualAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelasAnualRow>>(),
        loadResumo: getIt<LoadResumoParcelasAnualUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasAnualAcrossAgentsUseCase>(
      () => LoadResumoParcelasAnualAcrossAgentsUseCase(
        getIt<ResumoParcelasAnualAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository
    >(
      () => ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>>(),
        loadResumo: getIt<LoadResumoParcelasFormaPagamentoPorMesUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase
    >(
      () => LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase(
        getIt<ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasMensalAcrossAgentsRepository>(
      () => ResumoParcelasMensalAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelasMensalRow>>(),
        loadResumo: getIt<LoadResumoParcelasMensalUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasMensalAcrossAgentsUseCase>(
      () => LoadResumoParcelasMensalAcrossAgentsUseCase(
        getIt<ResumoParcelasMensalAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoVendasDiariasPorVendedorAcrossAgentsRepository
    >(
      () => ResumoVendasDiariasPorVendedorAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>>(),
        loadResumo: getIt<LoadResumoVendasDiariasPorVendedorUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase(
        getIt<ResumoVendasDiariasPorVendedorAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoTotalDiarioVendasAcrossAgentsRepository>(
      () => ResumoTotalDiarioVendasAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoTotalDiarioVendasRow>>(),
        loadResumo: getIt<LoadResumoTotalDiarioVendasUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoTotalDiarioVendasAcrossAgentsUseCase>(
      () => LoadResumoTotalDiarioVendasAcrossAgentsUseCase(
        getIt<ResumoTotalDiarioVendasAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepository
    >(
      () => ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<
              AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>
            >(),
        loadResumo: getIt<LoadResumoTotalVendasMunicipioFilialDiarioUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase
    >(
      () => LoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase(
        getIt<ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository
    >(
      () => ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<
              AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>
            >(),
        loadResumo: getIt<LoadResumoTotalVendasMunicipioFilialPeriodoUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
    >(
      () => LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase(
        getIt<ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<CadastroFilialAcrossAgentsRepository>(
      () => CadastroFilialAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<CadastroFilialRow>>(),
        loadCadastroFilial: getIt<LoadCadastroFilialPageUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadCadastroFilialAcrossAgentsUseCase>(
      () => LoadCadastroFilialAcrossAgentsUseCase(
        getIt<CadastroFilialAcrossAgentsRepository>(),
      ),
    );
}

void _registerFilterOptionsRepositories(GetIt getIt) {
  final mergeAllConcurrency = AppEnvironment.agentQueryMergeAllConcurrency;
  getIt
    ..registerLazySingleton<
      ResumoVendasDiariasPorVendedorFilterOptionsRepository
    >(
      () => ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase(
        getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase(
        getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase(
        getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>
    >(
      () => AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
    >(
      () => AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<
        ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
      >
    >(
      () =>
          AgentQueryExecutor<
            ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
          >(
            mergeAllConcurrency: mergeAllConcurrency,
          ),
    )
    ..registerLazySingleton<
      ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
    >(
      () =>
          ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl(
            targetResolver: getIt<AgentQueryTargetResolver>(),
            planBuilder: getIt<AgentQueryPlanBuilder>(),
            vendedorExecutor:
                getIt<
                  AgentQueryExecutor<
                    ResumoVendasDiariasPorVendedorVendedorOption
                  >
                >(),
            textExecutor:
                getIt<
                  AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
                >(),
            allOptionsBatchExecutor:
                getIt<
                  AgentQueryExecutor<
                    ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
                  >
                >(),
            filterOptionsRepository:
                getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
            loadVendedorOptions:
                getIt<
                  LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
                >(),
            loadBairroOptions:
                getIt<LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase>(),
            loadMunicipioOptions:
                getIt<
                  LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
                >(),
          ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase
    >(
      () =>
          LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase(
            getIt<
              ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
            >(),
          ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase(
        getIt<
          ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
        >(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase
    >(
      () =>
          LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase(
            getIt<
              ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
            >(),
          ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgentsUseCase
    >(
      () =>
          LoadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgentsUseCase(
            getIt<
              ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
            >(),
          ),
    );
}

void _registerStreamingRelay(GetIt getIt) {
  // PR-L+ p3: streaming companion datasource. Lives next to the
  // unary registrations because both share the same body mapper and
  // are gated by the same env (`SOCKET_RELAY_ENABLED`). Registered
  // unconditionally as a lazy singleton; the factory checks
  // `RelayCommandDispatcher` at construction time, so builds without
  // the relay layer simply never resolve it.
  if (getIt.isRegistered<RelayCommandDispatcher>()) {
    getIt.registerLazySingleton<AgentQueriesStreamingRemoteDataSource>(
      () => RelayStreamingAgentQueriesRemoteDataSource(
        dispatcher: getIt<RelayCommandDispatcher>(),
        bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
        compression: AppEnvironment.socketRelayPayloadFrameCompression,
      ),
    );
  }
}

/// Helper to reduce boilerplate when registering a simple repository + use case pair.
void _registerSingle<R extends Object, U extends Object>(
  GetIt getIt, {
  required R Function() repo,
  required U Function() useCase,
}) {
  getIt
    ..registerLazySingleton<R>(repo)
    ..registerLazySingleton<U>(useCase);
}

/// Returns the relay-backed datasource when the relay layer is available.
/// `useRelay` selects relay transport; each request's `relayMode` decides
/// whether `sql.execute` uses unary relay or streaming + collector.
AgentQueriesRemoteDataSource? _resolveRelayDatasource(GetIt getIt) {
  if (!getIt.isRegistered<RelayCommandDispatcher>()) {
    return null;
  }

  final rawStreamingDelegate =
      getIt.isRegistered<AgentQueriesStreamingRemoteDataSource>()
      ? getIt<AgentQueriesStreamingRemoteDataSource>()
      : RelayStreamingAgentQueriesRemoteDataSource(
          dispatcher: getIt<RelayCommandDispatcher>(),
          bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
          compression: AppEnvironment.socketRelayPayloadFrameCompression,
        );

  final maxBufferedRows =
      AppEnvironment.socketStreamSqlCollectorMaxBufferedRows;
  final collector = maxBufferedRows > 0
      ? BridgeShapedSqlExecuteCollector(maxBufferedRows: maxBufferedRows)
      : const BridgeShapedSqlExecuteCollector();

  final unaryDelegate = RelayAgentQueriesRemoteDataSource(
    dispatcher: getIt<RelayCommandDispatcher>(),
    bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
    batchBodyMapper: getIt<AgentSqlExecuteBatchRequestToBridgeBody>(),
    compression: AppEnvironment.socketRelayPayloadFrameCompression,
  );

  final streamingRelayDelegate =
      CollectingRelayStreamingAgentQueriesRemoteDataSource(
        streamingDelegate: rawStreamingDelegate,
        batchDelegate: unaryDelegate,
        collector: collector,
        maxConcurrentPerAgent:
            AppEnvironment.agentSqlRelayStreamingMaxConcurrentPerAgent,
      );

  return RoutingRelayAgentQueriesRemoteDataSource(
    unaryDelegate: unaryDelegate,
    streamingDelegate: streamingRelayDelegate,
  );
}
