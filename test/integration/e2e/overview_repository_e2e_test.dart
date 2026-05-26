@Tags(['e2e'])
@Timeout(Duration(minutes: 7))
library;

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_overview.dart';
import 'package:colmeia/core/errors/app_failure.dart'
    show AppFailure, SessionFailure, UnknownFailure;
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:result_dart/result_dart.dart';
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

const String _e2eOverviewRepositoryScopeName = 'e2e_overview_repository';

void main() {
  group(
    'OverviewRepository / LoadOverviewUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      setUp(() {
        if (missingE2eRepositoryKeys().isNotEmpty) {
          return;
        }
        getIt
          ..pushNewScope(scopeName: _e2eOverviewRepositoryScopeName)
          ..registerSingleton<AppCacheStore>(_E2eInMemoryAppCacheStore());
        registerInjectorOverview(getIt);
      });

      tearDown(() async {
        if (getIt.currentScopeName != _e2eOverviewRepositoryScopeName) {
          return;
        }
        await getIt.popScope();
      });

      test(
        'loadOverview hits the hub via overview batch path and returns Overview',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; stdout is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP overview_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final useCase = getIt<LoadOverviewUseCase>();
          final result = await runE2eAppResultWithHubRetry(
            () => useCase(
              userId: 'user-1',
              policy: OverviewLoadPolicy.forceRefresh,
              filter: DashboardFilter(
                selectedAgentIds: <String>{AppEnvironment.e2eAgentId},
              ),
              rowLabels: OverviewLoadLabels.englishFallback,
            ),
            actionLabel: 'overview_repository',
          );

          result.fold(
            _expectOverviewE2eSuccess,
            _expectOverviewRepositoryE2eFailure,
          );
        },
      );

      test(
        'loadOverviewProgressively ends with isFinal snapshot and same invariants',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; stdout is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP overview_repository_progressive_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<OverviewRepository>();
          final result = await runE2eAppResultWithHubRetry(
            () => _loadOverviewProgressiveEnd(repository),
            actionLabel: 'overview_repository_progressive',
          );

          result.fold(
            _expectOverviewE2eSuccess,
            _expectOverviewRepositoryE2eFailure,
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}

Future<AppResult<Overview>> _loadOverviewProgressiveEnd(
  OverviewRepository repository,
) async {
  OverviewProgressiveSnapshot? lastSnapshot;
  await for (final chunk in repository.loadOverviewProgressively(
    userId: 'user-1',
    policy: OverviewLoadPolicy.forceRefresh,
    filter: DashboardFilter(
      selectedAgentIds: <String>{AppEnvironment.e2eAgentId},
    ),
    rowLabels: OverviewLoadLabels.englishFallback,
  )) {
    final failure = chunk.exceptionOrNull();
    if (failure != null) {
      return Failure<Overview, AppFailure>(failure);
    }
    lastSnapshot = chunk.getOrNull();
  }
  final last = lastSnapshot;
  if (last == null) {
    return const Failure<Overview, AppFailure>(
      UnknownFailure(
        message: 'Overview progressive stream produced no snapshot',
        userMessage: 'Unable to load the overview.',
      ),
    );
  }
  if (!last.isFinal) {
    return const Failure<Overview, AppFailure>(
      UnknownFailure(
        message: 'Overview progressive stream ended without isFinal',
        userMessage: 'Unable to load the overview.',
      ),
    );
  }
  return Success<Overview, AppFailure>(last.overview);
}

void _expectOverviewE2eSuccess(Overview overview) {
  expect(
    overview.periodEnd.compareTo(overview.periodStart),
    greaterThanOrEqualTo(0),
  );
  expect(overview.kpis.totalSalesCount, greaterThanOrEqualTo(0));
  expect(overview.kpis.totalAmount, isNonNegative);
  expect(overview.kpis.averageTicket, isNonNegative);
  expect(overview.kpis.paymentMethodCount, greaterThanOrEqualTo(0));
  expect(overview.approvedAgentCount, greaterThanOrEqualTo(0));
  for (final method in overview.paymentMethods) {
    expect(method.label, isNotEmpty);
  }
}

void _expectOverviewRepositoryE2eFailure(AppFailure failure) {
  if (shouldLogE2eAcceptedFailureDiagnostic(failure)) {
    // E2E diagnostic only; stdout is intentional for local/CI triage.
    // ignore: avoid_print
    print(
      'overview_repository_e2e failure: '
      '${e2eAgentSqlFailureDiagnostic(failure)}',
    );
  }
  expect(failure, isA<AppFailure>());
  if (AppEnvironment.hasE2eAgentBridgeCredentials) {
    expect(
      failure,
      isNot(isA<SessionFailure>()),
      reason:
          'Unexpected HTTP 401 after client login for overview '
          'repository.',
    );
  }
  expect(
    isAcceptableE2eAgentSqlRepositoryFailure(failure),
    isTrue,
    reason:
        'Overview repository e2e should return overview data, '
        'invalid_policy / missing_permission RPC, transient '
        'transport, queue saturation, or transient bridge HTTP 5xx. '
        '${e2eAgentSqlFailureDiagnostic(failure)}',
  );
}

final class _E2eInMemoryAppCacheStore implements AppCacheStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<void> clearAll() async {
    _data.clear();
  }

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    _data[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _data.remove(key);
  }
}
