import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';

export 'package:colmeia/features/overview/domain/entities/overview_filter.dart'
    show OverviewAgentOption, OverviewFilter, OverviewYearMonth;

enum OverviewLoadPolicy {
  defaultLoad,
  forceRefresh,
}

// ignore: one_member_abstracts, this contract should grow with cache and sync operations
abstract interface class OverviewRepository {
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  });
}
