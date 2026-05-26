import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

export 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart'
    show OverviewLoadPolicy;
export 'package:colmeia/shared/filters/dashboard_filter.dart'
    show DashboardAgentOption, DashboardFilter, DashboardYearMonth;

abstract interface class OverviewRepository {
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  });

  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  });
}
