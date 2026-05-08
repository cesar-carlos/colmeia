import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';

class LoadOverviewUseCase {
  LoadOverviewUseCase(this._overviewRepository);

  final OverviewRepository _overviewRepository;

  Future<AppResult<Overview>> call({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) {
    return _overviewRepository.loadOverview(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
    );
  }

  Stream<AppResult<OverviewProgressiveSnapshot>> progressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) {
    return _overviewRepository.loadOverviewProgressively(
      userId: userId,
      policy: policy,
      filter: filter,
      rowLabels: rowLabels,
    );
  }
}
