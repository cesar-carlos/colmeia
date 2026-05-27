import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/presentation/overview_alert_banner_spec.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter_test/flutter_test.dart';

const OverviewPaymentMethodBreakdown _samplePaymentMethod =
    OverviewPaymentMethodBreakdown(
  code: 'PIX',
  label: 'Pix',
  totalSalesCount: 1,
  totalAmount: 100,
  averageTicket: 100,
  sharePercent: 100,
);

void main() {
  final l10n = AppLocalizationsEn();

  List<OverviewAlertBannerSpec> build({
    String? errorMessage,
    String? errorDiagnosticBody,
    Overview? overview,
    List<String> missingTokenAgentNames = const <String>[],
    List<String> partialFailureAgentNames = const <String>[],
    List<String> skippedDueToHubPresenceAgentNames = const <String>[],
    String? retryCountdownLabel,
  }) {
    return buildOverviewAlertBannerSpecs(
      l10n: l10n,
      errorMessage: errorMessage,
      errorDiagnosticBody: errorDiagnosticBody,
      overview: overview,
      missingTokenAgentNames: missingTokenAgentNames,
      partialFailureAgentNames: partialFailureAgentNames,
      skippedDueToHubPresenceAgentNames: skippedDueToHubPresenceAgentNames,
      retryCountdownLabel: retryCountdownLabel,
    );
  }

  test('returns no specs when nothing is wrong and overview is null', () {
    expect(build(), isEmpty);
  });

  test('returns no specs when overview is clean and there is no error', () {
    final overview = Overview.empty().copyWith(mainResumoHadPlannedTargets: true);
    expect(build(overview: overview), isEmpty);
  });

  test('builds a loadError spec including the diagnostic body in details', () {
    final specs = build(
      errorMessage: 'Network down',
      errorDiagnosticBody: 'HTTP 502',
    );

    expect(specs, hasLength(1));
    final spec = specs.single;
    expect(spec.kind, OverviewAlertKind.loadError);
    expect(spec.tone, AppInlinePanelTone.error);
    expect(spec.title, l10n.overviewLoadErrorTitle);
    expect(spec.message, 'Network down');
    expect(spec.detailsBody, contains('Network down'));
    expect(spec.detailsBody, contains('HTTP 502'));
    expect(spec.showRetry, isTrue);
    expect(spec.showManage, isTrue);
  });

  test('loadError uses the retry countdown label when provided', () {
    final specs = build(
      errorMessage: 'Network down',
      retryCountdownLabel: 'Retry in 5s',
    );

    expect(specs.single.retryDisabledLabel, 'Retry in 5s');
  });

  test('emits setupRequired with affected agents when present', () {
    final overview = Overview.empty().copyWith(
      agentIdsMissingClientToken: const <String>['a'],
      agentNamesMissingClientToken: const <String>['Alpha'],
    );

    final specs = build(
      overview: overview,
      missingTokenAgentNames: const <String>['Alpha'],
    );

    expect(specs.map((s) => s.kind), contains(OverviewAlertKind.setupRequired));
    final spec =
        specs.firstWhere((s) => s.kind == OverviewAlertKind.setupRequired);
    expect(spec.affectedAgents, isNotNull);
    expect(spec.affectedAgents!.normalizedNames, <String>['Alpha']);
    expect(
      spec.affectedAgents!.sheetTitle,
      l10n.dashboardAffectedAgentsSheetTitleSetupRequired,
    );
    expect(spec.showManage, isTrue);
    expect(spec.showRetry, isFalse);
  });

  test('emits staleCache banner with optional manage when token is missing',
      () {
    final staleWithoutToken = Overview.empty().copyWith(
      isStaleCache: true,
      mainResumoHadPlannedTargets: true,
    );
    final staleWithMissingToken = Overview.empty().copyWith(
      isStaleCache: true,
      mainResumoHadPlannedTargets: true,
      agentIdsMissingClientToken: const <String>['a'],
      agentNamesMissingClientToken: const <String>['Alpha'],
    );

    final withoutToken =
        build(overview: staleWithoutToken).where((s) => s.kind == OverviewAlertKind.staleCache).single;
    final withToken = build(
      overview: staleWithMissingToken,
      missingTokenAgentNames: const <String>['Alpha'],
    ).where((s) => s.kind == OverviewAlertKind.staleCache).single;

    expect(withoutToken.showManage, isFalse);
    expect(withToken.showManage, isTrue);
    expect(withToken.detailsBody, contains('Alpha'));
  });

  test(
    'emits missingClientToken (separate from setupRequired) when payment rows exist',
    () {
      final overview = Overview.empty().copyWith(
        agentIdsMissingClientToken: const <String>['a'],
        agentNamesMissingClientToken: const <String>['Alpha'],
        mainResumoHadPlannedTargets: true,
      );

      final specs = build(
        overview: overview,
        missingTokenAgentNames: const <String>['Alpha'],
      );

      final kinds = specs.map((s) => s.kind).toSet();
      expect(kinds, contains(OverviewAlertKind.missingClientToken));
      expect(kinds, isNot(contains(OverviewAlertKind.setupRequired)));
    },
  );

  test('emits agentsOffline when hub-presence skipped list is non-empty', () {
    final overview = Overview.empty().copyWith(
      agentIdsSkippedDueToHubPresence: const <String>['a'],
      agentNamesSkippedDueToHubPresence: const <String>['Alpha'],
    );

    final specs = build(
      overview: overview,
      skippedDueToHubPresenceAgentNames: const <String>['Alpha'],
    );

    final spec =
        specs.firstWhere((s) => s.kind == OverviewAlertKind.agentsOffline);
    expect(spec.affectedAgents!.normalizedNames, <String>['Alpha']);
    expect(spec.showRetry, isTrue);
    expect(spec.showManage, isTrue);
  });

  test('emits partialAgentQueries when resumo or lucratividade partials exist',
      () {
    final resumoOnly = Overview.empty().copyWith(
      agentIdsExcludedFromQueryFailure: const <String>['a'],
      agentNamesExcludedFromQueryFailure: const <String>['Alpha'],
    );
    final lucratividadeOnly = Overview.empty().copyWith(
      lucratividadePartialFailureAgentNames: const <String>['Beta'],
    );

    final fromResumo = build(
      overview: resumoOnly,
      partialFailureAgentNames: const <String>['Alpha'],
    );
    final fromLucratividade = build(
      overview: lucratividadeOnly,
      partialFailureAgentNames: const <String>['Beta'],
    );

    expect(
      fromResumo.map((s) => s.kind),
      contains(OverviewAlertKind.partialAgentQueries),
    );
    expect(
      fromLucratividade.map((s) => s.kind),
      contains(OverviewAlertKind.partialAgentQueries),
    );
  });

  test('emits multiAgentAggregation note without actions', () {
    final overview = Overview.empty().copyWith(
      approvedAgentCount: 3,
      paymentMethods: const <OverviewPaymentMethodBreakdown>[
        _samplePaymentMethod,
      ],
    );

    final spec = build(overview: overview)
        .firstWhere((s) => s.kind == OverviewAlertKind.multiAgentAggregation);

    expect(spec.tone, AppInlinePanelTone.informational);
    expect(spec.showRetry, isFalse);
    expect(spec.showManage, isFalse);
    expect(spec.detailsBody, isNull);
  });

  test('orders banners deterministically (error → setup → stale → token → '
      'offline → partial → aggregation)', () {
    final overview = Overview.empty().copyWith(
      isStaleCache: true,
      mainResumoHadPlannedTargets: true,
      agentIdsMissingClientToken: const <String>['a'],
      agentNamesMissingClientToken: const <String>['Alpha'],
      agentIdsSkippedDueToHubPresence: const <String>['b'],
      agentNamesSkippedDueToHubPresence: const <String>['Beta'],
      agentIdsExcludedFromQueryFailure: const <String>['c'],
      agentNamesExcludedFromQueryFailure: const <String>['Gamma'],
      approvedAgentCount: 3,
      paymentMethods: const <OverviewPaymentMethodBreakdown>[
        _samplePaymentMethod,
      ],
    );

    final kinds = build(
      errorMessage: 'boom',
      overview: overview,
      missingTokenAgentNames: const <String>['Alpha'],
      skippedDueToHubPresenceAgentNames: const <String>['Beta'],
      partialFailureAgentNames: const <String>['Gamma'],
    ).map((s) => s.kind).toList();

    expect(kinds, <OverviewAlertKind>[
      OverviewAlertKind.loadError,
      OverviewAlertKind.staleCache,
      OverviewAlertKind.missingClientToken,
      OverviewAlertKind.agentsOffline,
      OverviewAlertKind.partialAgentQueries,
      OverviewAlertKind.multiAgentAggregation,
    ]);
  });
}
