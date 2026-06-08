import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';

/// Loads a focused subset of overview sections for chart detail pages.
class LoadOverviewSectionsUseCase {
  LoadOverviewSectionsUseCase(this._overviewRepository);

  final OverviewRepository _overviewRepository;

  Stream<AppResult<OverviewProgressiveSnapshot>> progressively({
    required String userId,
    required OverviewSectionRequest sectionRequest,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _overviewRepository.loadOverviewProgressively(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
      cancelScope: cancelScope,
      sectionRequest: sectionRequest,
    );
  }

  Future<AppResult<Overview>> call({
    required String userId,
    required OverviewSectionRequest sectionRequest,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _overviewRepository.loadOverview(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
      cancelScope: cancelScope,
      sectionRequest: sectionRequest,
    );
  }
}
