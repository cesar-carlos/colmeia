import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/overview/application/overview_prefetch_session.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/scheduler.dart';

typedef OverviewPrefetchStaleCheck = bool Function(int loadGeneration);
typedef OverviewPrefetchGateCheck = bool Function();
typedef OverviewPrefetchNotifyListeners = void Function();

/// Warms shell cache for chart sections not included in the home load.
final class OverviewSectionPrefetchCoordinator {
  OverviewSectionPrefetchCoordinator({
    required this._prefetchSession,
    required this._isOnRetryCooldown,
    required this._isLoading,
    required this._notifyListeners,
    required this._isNarrowViewport,
  });

  static const List<OverviewProgressiveSection> prefetchSectionsWide =
      <OverviewProgressiveSection>[
        OverviewProgressiveSection.paymentMix,
        OverviewProgressiveSection.userRanking,
        OverviewProgressiveSection.dailySales,
        OverviewProgressiveSection.weekdaySales,
        OverviewProgressiveSection.weekdayUserSales,
        OverviewProgressiveSection.lucratividadePeriod,
      ];

  static const List<OverviewProgressiveSection> prefetchSectionsNarrow =
      <OverviewProgressiveSection>[
        OverviewProgressiveSection.dailySales,
        OverviewProgressiveSection.weekdaySales,
      ];

  final OverviewPrefetchSession _prefetchSession;
  final OverviewPrefetchGateCheck _isOnRetryCooldown;
  final OverviewPrefetchGateCheck _isLoading;
  final OverviewPrefetchNotifyListeners _notifyListeners;
  final bool Function() _isNarrowViewport;

  void schedule({
    required LoadOverviewSectionsUseCase useCase,
    required OverviewShellCache cache,
    required String userId,
    required String signature,
    required int loadGeneration,
    required DashboardFilter activeFilter,
    required OverviewLoadLabels rowLabels,
    required OverviewPrefetchStaleCheck isLoadStale,
    required bool disposed,
  }) {
    if (_isOnRetryCooldown()) {
      return;
    }
    final prefetchGeneration = _prefetchSession.begin();
    unawaited(
      _prefetchSectionsInBackground(
        useCase: useCase,
        cache: cache,
        userId: userId,
        signature: signature,
        loadGeneration: loadGeneration,
        prefetchGeneration: prefetchGeneration,
        activeFilter: activeFilter,
        rowLabels: rowLabels,
        isLoadStale: isLoadStale,
        disposed: disposed,
      ),
    );
  }

  List<OverviewProgressiveSection> _prefetchSectionsForViewport() {
    return _isNarrowViewport() ? prefetchSectionsNarrow : prefetchSectionsWide;
  }

  bool _isPrefetchStale({
    required int loadGeneration,
    required int prefetchGeneration,
    required OverviewPrefetchStaleCheck isLoadStale,
    required bool disposed,
  }) {
    return disposed ||
        isLoadStale(loadGeneration) ||
        _prefetchSession.isStale(prefetchGeneration);
  }

  Future<void> _prefetchSectionsInBackground({
    required LoadOverviewSectionsUseCase useCase,
    required OverviewShellCache cache,
    required String userId,
    required String signature,
    required int loadGeneration,
    required int prefetchGeneration,
    required DashboardFilter activeFilter,
    required OverviewLoadLabels rowLabels,
    required OverviewPrefetchStaleCheck isLoadStale,
    required bool disposed,
  }) async {
    final sections = _prefetchSectionsForViewport();
    final delayMs = AppEnvironment.overviewSectionPrefetchDelayMs;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      if (_isPrefetchStale(
        loadGeneration: loadGeneration,
        prefetchGeneration: prefetchGeneration,
        isLoadStale: isLoadStale,
        disposed: disposed,
      )) {
        return;
      }
    }

    AppLogger.debug(
      'Overview section prefetch started',
      context: <String, Object?>{
        'operation': 'prefetchOverviewSections',
        'userId': userId,
        'sections': sections.map((s) => s.name).toList(),
      },
    );
    final cancelScope = _prefetchSession.cancelScope;
    for (final section in sections) {
      if (_isPrefetchStale(
        loadGeneration: loadGeneration,
        prefetchGeneration: prefetchGeneration,
        isLoadStale: isLoadStale,
        disposed: disposed,
      )) {
        return;
      }
      if (_isOnRetryCooldown() || _isLoading()) {
        return;
      }
      final entry = cache.read(signature);
      if (entry == null) {
        return;
      }
      if (entry.completedSections.contains(section)) {
        continue;
      }

      final request = OverviewSectionRequest.forChartSection(section);
      await for (final result in useCase.progressively(
        userId: userId,
        sectionRequest: request,
        filter: activeFilter,
        rowLabels: rowLabels,
        cancelScope: cancelScope,
      )) {
        if (_isPrefetchStale(
          loadGeneration: loadGeneration,
          prefetchGeneration: prefetchGeneration,
          isLoadStale: isLoadStale,
          disposed: disposed,
        )) {
          return;
        }
        final snapshot = result.getOrNull();
        if (snapshot != null && snapshot.isFinal) {
          if (request.isSectionBatchOnly || request.runMainBatch) {
            cache.mergePublish(
              signature: signature,
              detailOverview: snapshot.overview,
              section: section,
              addedSections: request.completedWhenFinal(),
            );
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _notifyListeners();
            });
            AppLogger.debug(
              'Overview section prefetch warmed',
              context: <String, Object?>{
                'operation': 'prefetchOverviewSections',
                'section': section.name,
              },
            );
          }
        }
      }
    }
  }
}
