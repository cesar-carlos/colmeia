import 'dart:convert';

import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_use_case.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_vendas_municipio_filial_periodo_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/pwa/domain/offline_package_exception.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

class PwaDatasetLoader {
  PwaDatasetLoader(this._overview, this._context, this._tokens, this._sales);
  final OverviewRepository _overview;
  final UserContextRemoteDataSource _context;
  final AgentClientTokenReader _tokens;
  final LoadResumoTotalVendasMunicipioFilialPeriodoUseCase _sales;
  Future<Map<String, dynamic>> call(
    String user,
    String agent,
    DateTime start,
    DateTime end,
    AgentQueriesCancelScope cancelScope,
  ) async {
    final context = await _context.loadUserContext(userId: user);
    final overviewResult = await _overview.loadOverview(
      userId: user,
      policy: OverviewLoadPolicy.forceRefresh,
      cancelScope: cancelScope,
      sectionRequest: OverviewSectionRequest.offlinePackage,
      filter: DashboardFilter(
        selectedAgentIds: {agent},
        referenceRange: DashboardDateRange(
          startInclusive: start,
          endInclusive: end,
        ),
      ),
    );
    final overview = overviewResult.getOrThrow();
    if (overview.hasPartialAgentQueryFailure ||
        overview.hasMissingClientToken ||
        overview.hasAgentsSkippedDueToHubPresence ||
        overview.hasLucratividadePartialFailure ||
        overview.dailySalesTrendLoadFailed ||
        overview.monthlyParcelTrendLoadFailed ||
        overview.weekdaySalesTrendLoadFailed ||
        overview.weekdayUserSalesTrendLoadFailed ||
        overview.agentRankingsLoadFailed ||
        overview.userRankingsLoadFailed ||
        overview.lucratividadeTrendLoadFailed) {
      throw const OfflinePackageException(OfflinePackageIssue.incomplete);
    }
    final tokens = await _tokens.readMany(userId: user, agentIds: [agent]);
    final salesResult = await _sales(
      userId: user,
      agentId: agent,
      clientToken: tokens[agent],
      filter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      ),
      cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      cancelScope: cancelScope,
    );
    final sales = salesResult.getOrThrow();
    return {
      'context': context.toJson(),
      'overview': OverviewModel.fromEntity(
        overview,
        cachedAt: DateTime.now().toUtc(),
        sourceAgentIds: [agent],
      ).toJson(includeDerivedSnapshots: true),
      'salesByBranch': jsonDecode(
        utf8.decode(
          const ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy()
              .encodePayload(sales.rows),
        ),
      ),
      'includesPartialCurrentDay': true,
    };
  }
}
