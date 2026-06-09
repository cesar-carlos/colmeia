import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_operational_fingerprint.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_inline_chart_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesLiveMapOperationalFingerprint', () {
    test('detects totalRevenue changes', () {
      final baseline = SalesLiveMapOperationalFingerprint.from(
        _result(totalRevenue: 10),
      );
      final updated = SalesLiveMapOperationalFingerprint.from(
        _result(totalRevenue: 99),
      );

      expect(baseline == updated, isFalse);
    });

    test('detects failedAgentCount changes', () {
      final baseline = SalesLiveMapOperationalFingerprint.from(
        _result(),
      );
      final updated = SalesLiveMapOperationalFingerprint.from(
        _result(failedAgentCount: 2),
      );

      expect(baseline == updated, isFalse);
    });
  });

  group('SalesLiveMapMapSlice', () {
    test('is not equal when operational fields change but map digest is stable', () {
      final sharedVisual = _result(totalRevenue: 10, queriedAgentCount: 1);
      final baselineState = SalesLiveMapPresentationState(
        result: sharedVisual,
        visualResult: sharedVisual,
        mapPayloadDigest: 42,
        isLoading: false,
      );
      final updatedState = baselineState.copyWith(
        result: _result(totalRevenue: 99, queriedAgentCount: 3),
      );

      final baselineSlice = SalesLiveMapMapSlice.fromState(baselineState);
      final updatedSlice = SalesLiveMapMapSlice.fromState(updatedState);

      expect(baselineSlice.mapPayloadDigest, updatedSlice.mapPayloadDigest);
      expect(baselineSlice == updatedSlice, isFalse);
    });
  });
}

SalesLiveMapLoadResult _result({
  double totalRevenue = 0,
  int queriedAgentCount = 0,
  int failedAgentCount = 0,
}) {
  return SalesLiveMapLoadResult(
    points: const <SalesLiveMapPoint>[],
    branchOptions: const <SalesLiveMapBranchOption>[],
    totalRevenue: totalRevenue,
    totalSalesCount: 0,
    totalBranchCount: 0,
    mappedBranchCount: 0,
    mappedMunicipalityCount: 0,
    queriedAgentCount: queriedAgentCount,
    plannedAgentCount: queriedAgentCount,
    failedAgentCount: failedAgentCount,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime.utc(2026),
  );
}
