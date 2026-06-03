import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, SessionFailure;
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_vendas_municipio_filial_periodo_sql.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_counting_agent_queries_repository.dart';
import 'e2e_dependency_bootstrap.dart';

void expectSalesLiveMapMergedBatchSql(
  E2eCountingAgentQueriesRepository countingRepository,
) {
  expect(countingRepository.executeSqlBatchCallCount, greaterThanOrEqualTo(1));
  expect(countingRepository.batchRequests, isNotEmpty);

  final mergedBatch = countingRepository.batchRequests.firstWhere(
    (request) => request.commands.length == salesLiveMapBatchCommandCount,
    orElse: () => countingRepository.batchRequests.first,
  );
  expect(mergedBatch.agentId, AppEnvironment.e2eAgentId);
  expect(mergedBatch.commands.length, salesLiveMapBatchCommandCount);
  expect(
    countingRepository.batchRequests.every((request) => request.useRelay),
    isTrue,
  );

  final sqlBodies = mergedBatch.commands.map((command) => command.sql).join(
    '\n',
  );
  expect(
    sqlBodies,
    contains(
      CadastroFilialSql.query(
        codEmpresa: SalesLiveMapPolicies.primaryCompanyCode,
        codFilial: SalesLiveMapPolicies.primaryBranchCode,
        projection: CadastroFilialSqlProjection.mapCatalog,
      ),
    ),
  );
  expect(
    sqlBodies,
    contains(
      ResumoTotalVendasMunicipioFilialPeriodoSql.query(
        codEmpresa: SalesLiveMapPolicies.primaryCompanyCode,
        codFilial: SalesLiveMapPolicies.primaryBranchCode,
      ),
    ),
  );
  expect(sqlBodies, contains('FROM Filial'));
  expect(sqlBodies, contains('ProdutoVendido'));

  final catalogOnlyBatches = countingRepository.batchRequests
      .where((request) => request.commands.length == 1)
      .toList(growable: false);
  for (final batch in catalogOnlyBatches) {
    expect(batch.agentId, AppEnvironment.e2eAgentId);
    expect(
      batch.commands.single.sql,
      contains('FROM Filial'),
    );
    expect(
      batch.commands.single.sql,
      isNot(contains('ProdutoVendido')),
    );
  }
}

void expectSalesLiveMapAgentSqlE2eFailure(AppFailure failure) {
  if (shouldLogE2eAcceptedFailureDiagnostic(failure)) {
    // E2E diagnostic only; stdout is intentional for local/CI triage.
    // ignore: avoid_print
    print(
      'sales_live_map_e2e failure: '
      '${e2eAgentSqlFailureDiagnostic(failure)}',
    );
  }
  expect(failure, isA<AppFailure>());
  if (AppEnvironment.hasE2eAgentBridgeCredentials) {
    expect(
      failure,
      isNot(isA<SessionFailure>()),
      reason:
          'Unexpected HTTP 401 after client login for sales live map.',
    );
  }
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason:
        'Sales live map e2e should return rows/empty sections, '
        'invalid_policy / missing_permission RPC, transient transport, '
        'queue saturation, or transient bridge HTTP 5xx. '
        '${e2eAgentSqlFailureDiagnostic(failure)}',
  );
}
