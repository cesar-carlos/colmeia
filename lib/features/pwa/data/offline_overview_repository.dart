import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:result_dart/result_dart.dart';

class OfflineOverviewRepository implements OverviewRepository {
  OfflineOverviewRepository(this._delegate, this._packages);
  final OverviewRepository _delegate;
  final PwaPackageService _packages;
  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async {
    if (_packages.platform.online) {
      return _delegate.loadOverview(
        userId: userId,
        policy: policy,
        filter: filter,
        rowLabels: rowLabels,
        cancelScope: cancelScope,
        sectionRequest: sectionRequest,
      );
    }
    if (cancelScope?.isCancelled ?? false) {
      return const Failure(OperationCancelledFailure());
    }
    final agents =
        filter.selectedAgentIds?.toList() ??
        await _packages.selectedAgents(userId);
    if (agents.length != 1) {
      return const Failure(
        ValidationFailure(
          message: 'offline_select_store',
          userMessage: 'Selecione uma loja disponível offline.',
        ),
      );
    }
    final package = await _packages.read(userId, agents.single);
    if (package == null) {
      return const Failure(
        ValidationFailure(
          message: 'offline_data_unavailable',
          userMessage:
              'Requer conexão: pacote indisponível ou autorização expirada.',
        ),
      );
    }
    final range = filter.referenceRange;
    if (filter.yearMonth != null ||
        range == null ||
        (range.startInclusive != package.periodStart ||
            range.endInclusive != package.periodEnd)) {
      return const Failure(
        ValidationFailure(
          message: 'offline_period_unavailable',
          userMessage: 'Requer conexão: o período solicitado não está no pacote offline.',
        ),
      );
    }
    return Success(
      OverviewModel.fromJson(
        Map<String, dynamic>.from(package.datasets['overview'] as Map),
      ).toEntity(),
    );
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
    OverviewSectionRequest sectionRequest = OverviewSectionRequest.full,
  }) async* {
    if (_packages.platform.online) {
      yield* _delegate.loadOverviewProgressively(
        userId: userId,
        policy: policy,
        filter: filter,
        rowLabels: rowLabels,
        cancelScope: cancelScope,
        sectionRequest: sectionRequest,
      );
      return;
    }
    final result = await loadOverview(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
      cancelScope: cancelScope,
      sectionRequest: sectionRequest,
    );
    yield result.map(
      (overview) => OverviewProgressiveSnapshot(
        overview: overview,
        completedSections: OverviewProgressiveSection.values.toSet(),
        pendingSections: const {},
        isFinal: true,
      ),
    );
  }
}
