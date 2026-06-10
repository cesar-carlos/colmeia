import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_dia_semana_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_parcelas_mensal_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_produto_venda_lucratividade_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_diario_vendas_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_vendas_municipio_filial_periodo_row_model.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_vendas_municipio_filial_periodo_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_support.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_periodo_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy_extensions.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';

final class ResumoTotalDiarioVendasFactsBucketBatchSupport
    implements
        AgentQueryFactsBucketBatchSupport<
          ResumoTotalDiarioVendasFilter,
          ResumoTotalDiarioVendasRow
        > {
  const ResumoTotalDiarioVendasFactsBucketBatchSupport();

  @override
  String get operation => ResumoTotalDiarioVendasRepositoryImpl.operation;

  @override
  String? validationError(ResumoTotalDiarioVendasFilter filter) =>
      filter.validationError();

  @override
  AgentSqlExecuteBatchCommand commandForBucket({
    required ResumoTotalDiarioVendasFilter bucketFilter,
    required String agentId,
    required int executionOrder,
  }) {
    return AgentSqlExecuteBatchCommand(
      sql: ResumoTotalDiarioVendasSql.query,
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaFim,
        ),
        'origem': bucketFilter.trimmedOrigem,
        'geraFinanceiro': bucketFilter.trimmedGeraFinanceiro,
        'preVenda': bucketFilter.trimmedPreVenda,
      },
      executionOrder: executionOrder,
    );
  }

  @override
  ResumoTotalDiarioVendasRow mapRow(Map<String, dynamic> row) =>
      ResumoTotalDiarioVendasRowModel.fromMap(row).toEntity();

  @override
  int resolveBridgeTimeoutMs(int? bridgeTimeoutMs) =>
      bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs;

  @override
  int get batchMaxRows =>
      AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas;

  @override
  bool bypassTransportCache(AgentQueryLoadPolicy cachePolicy) =>
      cachePolicy.bypassTransportCache;
}

final class ResumoParcelasMensalFactsBucketBatchSupport
    implements
        AgentQueryFactsBucketBatchSupport<
          ResumoParcelasMensalFilter,
          ResumoParcelasMensalRow
        > {
  const ResumoParcelasMensalFactsBucketBatchSupport();

  @override
  String get operation => ResumoParcelasMensalRepositoryImpl.operation;

  @override
  String? validationError(ResumoParcelasMensalFilter filter) =>
      filter.validationError();

  @override
  AgentSqlExecuteBatchCommand commandForBucket({
    required ResumoParcelasMensalFilter bucketFilter,
    required String agentId,
    required int executionOrder,
  }) {
    return AgentSqlExecuteBatchCommand(
      sql: ResumoParcelasMensalSql.query(
        codEmpresa: bucketFilter.codEmpresa,
        codFilial: bucketFilter.codFilial,
        codVendedor: bucketFilter.codVendedor,
      ),
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaFim,
        ),
        'origem': bucketFilter.trimmedOrigem,
        'geraFinanceiro': bucketFilter.trimmedGeraFinanceiro,
        'preVenda': bucketFilter.trimmedPreVenda,
      },
      executionOrder: executionOrder,
    );
  }

  @override
  ResumoParcelasMensalRow mapRow(Map<String, dynamic> row) =>
      ResumoParcelasMensalRowModel.fromMap(row).toEntity();

  @override
  int resolveBridgeTimeoutMs(int? bridgeTimeoutMs) =>
      bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeLongTimeoutMs;

  @override
  int get batchMaxRows => AgentQueriesBoundedResultMaxRows.resumoParcelasMensal;

  @override
  bool bypassTransportCache(AgentQueryLoadPolicy cachePolicy) =>
      cachePolicy.bypassTransportCache;
}

final class ResumoParcelasDiaSemanaFactsBucketBatchSupport
    implements
        AgentQueryFactsBucketBatchSupport<
          ResumoParcelasDiaSemanaFilter,
          ResumoParcelasDiaSemanaRow
        > {
  const ResumoParcelasDiaSemanaFactsBucketBatchSupport();

  @override
  String get operation => ResumoParcelasDiaSemanaRepositoryImpl.operation;

  @override
  String? validationError(ResumoParcelasDiaSemanaFilter filter) =>
      filter.validationError();

  @override
  AgentSqlExecuteBatchCommand commandForBucket({
    required ResumoParcelasDiaSemanaFilter bucketFilter,
    required String agentId,
    required int executionOrder,
  }) {
    return AgentSqlExecuteBatchCommand(
      sql: ResumoParcelasDiaSemanaSql.query(
        codEmpresa: bucketFilter.codEmpresa,
        codFilial: bucketFilter.codFilial,
        codVendedor: bucketFilter.codVendedor,
      ),
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaFim,
        ),
        'origem': bucketFilter.trimmedOrigem,
        'geraFinanceiro': bucketFilter.trimmedGeraFinanceiro,
        'preVenda': bucketFilter.trimmedPreVenda,
      },
      executionOrder: executionOrder,
    );
  }

  @override
  ResumoParcelasDiaSemanaRow mapRow(Map<String, dynamic> row) =>
      ResumoParcelasDiaSemanaRowModel.fromMap(row).toEntity();

  @override
  int resolveBridgeTimeoutMs(int? bridgeTimeoutMs) =>
      bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs;

  @override
  int get batchMaxRows =>
      AgentQueriesBoundedResultMaxRows.resumoParcelasDiaSemana;

  @override
  bool bypassTransportCache(AgentQueryLoadPolicy cachePolicy) =>
      cachePolicy.bypassTransportCache;
}

final class ResumoProdutoVendaLucratividadeFactsBucketBatchSupport
    implements
        AgentQueryFactsBucketBatchSupport<
          ResumoProdutoVendaLucratividadeFilter,
          ResumoProdutoVendaLucratividadeRow
        > {
  const ResumoProdutoVendaLucratividadeFactsBucketBatchSupport();

  @override
  String get operation =>
      ResumoProdutoVendaLucratividadeRepositoryImpl.operation;

  @override
  String? validationError(ResumoProdutoVendaLucratividadeFilter filter) =>
      filter.validationError();

  @override
  AgentSqlExecuteBatchCommand commandForBucket({
    required ResumoProdutoVendaLucratividadeFilter bucketFilter,
    required String agentId,
    required int executionOrder,
  }) {
    return AgentSqlExecuteBatchCommand(
      sql: ResumoProdutoVendaLucratividadeSql.query,
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaFim,
        ),
        'origem': bucketFilter.trimmedOrigem,
      },
      executionOrder: executionOrder,
    );
  }

  @override
  ResumoProdutoVendaLucratividadeRow mapRow(Map<String, dynamic> row) =>
      ResumoProdutoVendaLucratividadeRowModel.fromMap(row).toEntity();

  @override
  int resolveBridgeTimeoutMs(int? bridgeTimeoutMs) =>
      bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs;

  @override
  int get batchMaxRows =>
      AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade;

  @override
  bool bypassTransportCache(AgentQueryLoadPolicy cachePolicy) =>
      cachePolicy.bypassTransportCache;
}

final class ResumoTotalVendasMunicipioFilialPeriodoFactsBucketBatchSupport
    implements
        AgentQueryFactsBucketBatchSupport<
          ResumoTotalVendasMunicipioFilialPeriodoFilter,
          ResumoTotalVendasMunicipioFilialPeriodoRow
        > {
  const ResumoTotalVendasMunicipioFilialPeriodoFactsBucketBatchSupport();

  @override
  String get operation =>
      ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl.operation;

  @override
  String? validationError(
    ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
  ) => filter.validationError();

  @override
  AgentSqlExecuteBatchCommand commandForBucket({
    required ResumoTotalVendasMunicipioFilialPeriodoFilter bucketFilter,
    required String agentId,
    required int executionOrder,
  }) {
    return AgentSqlExecuteBatchCommand(
      sql: ResumoTotalVendasMunicipioFilialPeriodoSql.query(
        branches: bucketFilter.branchesForAgent(agentId.trim()),
        codEmpresa: bucketFilter.codEmpresa,
        codFilial: bucketFilter.codFilial,
      ),
      namedParams: <String, Object?>{
        'dataVendaInicio': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaInicio,
        ),
        'dataVendaFim': AgentQueriesSqlLocalDate.format(
          bucketFilter.dataVendaFim,
        ),
        'origem': bucketFilter.trimmedOrigem,
        'geraFinanceiro': bucketFilter.trimmedGeraFinanceiro,
        'preVenda': bucketFilter.trimmedPreVenda,
      },
      executionOrder: executionOrder,
    );
  }

  @override
  ResumoTotalVendasMunicipioFilialPeriodoRow mapRow(Map<String, dynamic> row) =>
      ResumoTotalVendasMunicipioFilialPeriodoRowModel.fromMap(row).toEntity();

  @override
  int resolveBridgeTimeoutMs(int? bridgeTimeoutMs) =>
      bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeTimeoutMs;

  @override
  int get batchMaxRows =>
      AgentQueriesBoundedResultMaxRows.resumoTotalVendasMunicipioFilialPeriodo;

  @override
  bool bypassTransportCache(AgentQueryLoadPolicy cachePolicy) =>
      cachePolicy.bypassTransportCache;
}
