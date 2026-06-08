import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_option.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_visual_snapshot_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final refreshedAt = DateTime(2026, 6, 3, 12);

  SalesLiveMapLoadResult loadedResult({double revenue = 1200}) {
    return SalesLiveMapLoadResult(
      points: <SalesLiveMapPoint>[
        SalesLiveMapPoint(
          id: 'branch-1',
          name: 'Branch',
          latitude: -23.5,
          longitude: -46.6,
          uf: 'SP',
          salesAmount: revenue,
          salesCount: 10,
          agentName: 'Agent',
          companyCode: 1,
          branchCode: 1,
        ),
      ],
      branchOptions: const <SalesLiveMapBranchOption>[],
      totalRevenue: revenue,
      totalSalesCount: 10,
      totalBranchCount: 1,
      mappedBranchCount: 1,
      mappedMunicipalityCount: 1,
      queriedAgentCount: 1,
      plannedAgentCount: 1,
      failedAgentCount: 0,
      missingClientTokenAgentCount: 0,
      skippedOfflineAgentCount: 0,
      rowCapReachedAgentCount: 0,
      refreshedAt: refreshedAt,
    );
  }

  group('SalesLiveMapVisualSnapshotPolicy', () {
    test('resolveNextVisualResult keeps previous snapshot on loadFailed', () {
      final previous = loadedResult();
      final failed = SalesLiveMapLoadResult(
        points: const <SalesLiveMapPoint>[],
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalRevenue: 0,
        totalSalesCount: 0,
        totalBranchCount: 0,
        mappedBranchCount: 0,
        mappedMunicipalityCount: 0,
        queriedAgentCount: 0,
        plannedAgentCount: 0,
        failedAgentCount: 0,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        loadFailed: true,
        refreshedAt: refreshedAt,
      );

      final next = SalesLiveMapVisualSnapshotPolicy.resolveNextVisualResult(
        incomingResult: failed,
        previousVisualResult: previous,
      );

      expect(identical(next, previous), isTrue);
    });

    test(
      'resolveNextVisualResult promotes pending snapshot with branchOptions',
      () {
        final pending = SalesLiveMapLoadResult(
          points: const <SalesLiveMapPoint>[],
          branchOptions: const <SalesLiveMapBranchOption>[
            SalesLiveMapBranchOption(
              id: 'branch-1',
              agentId: 'agent-1',
              agentName: 'Agent',
              codEmpresa: 1,
              codFilial: 1,
              registrationName: 'Branch',
              city: 'Cuiaba',
              uf: 'MT',
            ),
          ],
          totalRevenue: 0,
          totalSalesCount: 0,
          totalBranchCount: 1,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 1,
          plannedAgentCount: 1,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          salesDataPending: true,
          refreshedAt: refreshedAt,
        );

        final next = SalesLiveMapVisualSnapshotPolicy.resolveNextVisualResult(
          incomingResult: pending,
          previousVisualResult: null,
        );

        expect(identical(next, pending), isTrue);
      },
    );

    test('resolveNextVisualResult does not promote empty pending snapshot', () {
      final pending = SalesLiveMapLoadResult(
        points: const <SalesLiveMapPoint>[],
        branchOptions: const <SalesLiveMapBranchOption>[],
        totalRevenue: 0,
        totalSalesCount: 0,
        totalBranchCount: 0,
        mappedBranchCount: 0,
        mappedMunicipalityCount: 0,
        queriedAgentCount: 0,
        plannedAgentCount: 0,
        failedAgentCount: 0,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        salesDataPending: true,
        refreshedAt: refreshedAt,
      );

      final next = SalesLiveMapVisualSnapshotPolicy.resolveNextVisualResult(
        incomingResult: pending,
        previousVisualResult: null,
      );

      expect(next, isNull);
    });

    test(
      'resolveNextVisualResult keeps previous snapshot on regressive shell',
      () {
        final previous = loadedResult();
        final shell = SalesLiveMapLoadResult(
          points: const <SalesLiveMapPoint>[],
          branchOptions: const <SalesLiveMapBranchOption>[
            SalesLiveMapBranchOption(
              id: 'branch-1',
              agentId: 'agent-1',
              agentName: 'Agent',
              codEmpresa: 1,
              codFilial: 1,
              registrationName: 'Branch',
              city: 'Cuiaba',
              uf: 'MT',
            ),
          ],
          unmappedBranchOptions: const <SalesLiveMapBranchOption>[
            SalesLiveMapBranchOption(
              id: 'branch-1',
              agentId: 'agent-1',
              agentName: 'Agent',
              codEmpresa: 1,
              codFilial: 1,
              registrationName: 'Branch',
              city: 'Cuiaba',
              uf: 'MT',
            ),
          ],
          totalRevenue: 0,
          totalSalesCount: 0,
          totalBranchCount: 1,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 1,
          plannedAgentCount: 1,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          salesDataPending: false,
          refreshedAt: refreshedAt,
        );

        final next = SalesLiveMapVisualSnapshotPolicy.resolveNextVisualResult(
          incomingResult: shell,
          previousVisualResult: previous,
        );

        expect(identical(next, previous), isTrue);
      },
    );

    test(
      'resolveNextOperationalResult preserves geo fields on regressive shell',
      () {
        final established = loadedResult();
        final shell = SalesLiveMapLoadResult(
          points: const <SalesLiveMapPoint>[],
          branchOptions: established.branchOptions,
          unmappedBranchOptions: established.branchOptions,
          totalRevenue: 99,
          totalSalesCount: 9,
          totalBranchCount: 1,
          mappedBranchCount: 0,
          mappedMunicipalityCount: 0,
          queriedAgentCount: 1,
          plannedAgentCount: 1,
          failedAgentCount: 0,
          missingClientTokenAgentCount: 0,
          skippedOfflineAgentCount: 0,
          rowCapReachedAgentCount: 0,
          salesDataPending: false,
          refreshedAt: refreshedAt,
        );

        final next =
            SalesLiveMapVisualSnapshotPolicy.resolveNextOperationalResult(
              incomingResult: shell,
              previousResult: established,
              nextVisualResult: established,
            );

        expect(next.totalRevenue, 99);
        expect(next.mappedBranchCount, established.mappedBranchCount);
        expect(next.unmappedBranchOptions, isEmpty);
        expect(next.points, established.points);
      },
    );

    test('hasObservableDelta detects partial-issue changes', () {
      final previous = loadedResult();
      final next = SalesLiveMapLoadResult(
        points: previous.points,
        branchOptions: previous.branchOptions,
        unmappedBranchOptions: const <SalesLiveMapBranchOption>[
          SalesLiveMapBranchOption(
            id: 'branch-2',
            agentId: 'agent-1',
            agentName: 'Agent',
            codEmpresa: 1,
            codFilial: 2,
            registrationName: 'Branch 2',
            city: 'Cuiaba',
            uf: 'MT',
          ),
        ],
        totalRevenue: previous.totalRevenue,
        totalSalesCount: previous.totalSalesCount,
        totalBranchCount: 2,
        mappedBranchCount: 1,
        mappedMunicipalityCount: 1,
        queriedAgentCount: 1,
        plannedAgentCount: 1,
        failedAgentCount: 0,
        missingClientTokenAgentCount: 0,
        skippedOfflineAgentCount: 0,
        rowCapReachedAgentCount: 0,
        refreshedAt: refreshedAt,
      );

      expect(
        SalesLiveMapVisualSnapshotPolicy.hasObservableDelta(
          previous: previous,
          next: next,
          previousVisualResult: previous,
          nextVisualResult: previous,
          previousDigest: SalesLiveMapVisualSnapshotPolicy.payloadDigestFor(
            previous,
          ),
          nextDigest: SalesLiveMapVisualSnapshotPolicy.payloadDigestFor(
            previous,
          ),
        ),
        isTrue,
      );
    });

    test('isTransportTimeoutFailure reads uiKey from failure context', () {
      const failure = NetworkFailure(
        message: 'timeout',
        context: <String, Object?>{
          AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.transportTimeout,
        },
      );

      expect(
        SalesLiveMapVisualSnapshotPolicy.isTransportTimeoutFailure(failure),
        isTrue,
      );
    });
  });
}
