import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_summary_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OverviewHomePage extends StatefulWidget {
  const OverviewHomePage({super.key});

  @override
  State<OverviewHomePage> createState() => _OverviewHomePageState();
}

class _OverviewHomePageState extends State<OverviewHomePage> {
  /// Neutral placeholders (no plausible KPIs before real data).
  static final Overview _neutralSkeletonOverview = Overview(
    periodStart: DateTime(1970),
    periodEnd: DateTime(1970),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 0,
      totalAmount: 0,
      averageTicket: 0,
      paymentMethodCount: 0,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[],
    agentRankings: const <OverviewAgentRanking>[],
    userRankings: const <OverviewUserRanking>[],
  );

  late final OverviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<OverviewController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _greetingFirstName(String fullName, AppLocalizations l10n) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return l10n.overviewDefaultGreetingName;
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String _previewAgentNames(List<String> names) {
    final nonEmpty = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (nonEmpty.isEmpty) {
      return '';
    }
    const maxShown = 4;
    if (nonEmpty.length <= maxShown) {
      return nonEmpty.join(', ');
    }
    final head = nonEmpty.take(maxShown).join(', ');
    return '$head (+${nonEmpty.length - maxShown})';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OverviewController>.value(
      value: _controller,
      child:
          Consumer3<
            AuthController,
            CurrentUserContextController,
            OverviewController
          >(
            builder:
                (
                  context,
                  authController,
                  userContext,
                  overviewController,
                  _,
                ) {
                  overviewController.activeLocalizations = AppLocalizations.of(
                    context,
                  );
                  final theme = Theme.of(context);
                  final tokens = theme.extension<AppThemeTokens>()!;
                  final l10n = AppLocalizations.of(context);
                  final session = authController.session;
                  final overview = overviewController.overview;
                  final sessionUserId = session?.userId;
                  final isUserContextReady =
                      sessionUserId != null &&
                      !userContext.isLoadingInitial &&
                      userContext.errorMessage == null &&
                      userContext.hasResolvedData;
                  final showSkeleton =
                      overviewController.isLoadingInitial && overview == null;
                  final displayOverview = showSkeleton
                      ? _neutralSkeletonOverview
                      : overview;

                  final greetingName = _greetingFirstName(
                    userContext.userScope.name,
                    l10n,
                  );

                  Future<void> onRefresh() async {
                    final current = authController.session;
                    if (current == null) return;
                    await overviewController.refreshOverview(
                      userId: current.userId,
                    );
                  }

                  final periodLabel = (overview != null && !showSkeleton)
                      ? '${AppBrFormatters.shortDate(overview.periodStart)}'
                            ' – '
                            '${AppBrFormatters.shortDate(overview.periodEnd)}'
                      : null;

                  return _OverviewAutoLoader(
                    controller: overviewController,
                    userId: sessionUserId,
                    isReady: isUserContextReady,
                    child: RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: context.pageScrollPadding(tokens),
                        children: <Widget>[
                          AppShellPageIntro(
                            eyebrow: l10n.overviewGreetingEyebrow(greetingName),
                            subtitle: l10n.overviewHomeSubtitle,
                            footer: periodLabel != null
                                ? AppTagChip(
                                    label: periodLabel,
                                    icon: Icons.calendar_today_outlined,
                                  )
                                : null,
                          ),
                          SizedBox(height: tokens.gapMd),
                          _OverviewFilterBar(
                            l10n: l10n,
                            filter: overviewController.activeFilter,
                            availableAgents: overviewController.availableAgents,
                            onFilterChanged: sessionUserId == null
                                ? null
                                : (f) => unawaited(
                                    overviewController.applyFilter(
                                      userId: sessionUserId,
                                      filter: f,
                                    ),
                                  ),
                          ),
                          if (overviewController.errorMessage
                              case final String msg) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              title: l10n.overviewLoadErrorTitle,
                              message: msg,
                              actions: _OverviewPanelActions(
                                onRetry: sessionUserId == null
                                    ? null
                                    : () => unawaited(
                                        overviewController.retryOverview(
                                          userId: sessionUserId,
                                        ),
                                      ),
                                onManageAgents: () =>
                                    context.goTo(AppRoute.agents),
                                retryLabel: l10n.appInlineErrorRetry,
                                manageAgentsLabel: l10n.clientAgentsPageTitle,
                              ),
                            ),
                          ],
                          if (overview?.requiresClientTokenSetup ==
                              true) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              tone: AppInlinePanelTone.informational,
                              title: l10n.dashboardSetupRequiredTitle,
                              message: l10n.dashboardSetupRequiredMessage(
                                _previewAgentNames(
                                  overview!.agentNamesMissingClientToken,
                                ),
                              ),
                              actions: _OverviewPanelActions(
                                onManageAgents: () =>
                                    context.goTo(AppRoute.agents),
                                primaryLabel: l10n.clientAgentsPageTitle,
                                manageAgentsLabel: l10n.clientAgentsPageTitle,
                              ),
                            ),
                          ],
                          if (overview?.isStaleCache == true) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              tone: AppInlinePanelTone.informational,
                              title: l10n.overviewStaleCacheTitle,
                              message: l10n.overviewStaleCacheMessage,
                              actions: _OverviewPanelActions(
                                onRetry: sessionUserId == null
                                    ? null
                                    : () => unawaited(
                                        overviewController.retryOverview(
                                          userId: sessionUserId,
                                        ),
                                      ),
                                onManageAgents:
                                    overview?.hasMissingClientToken == true
                                    ? () => context.goTo(AppRoute.agents)
                                    : null,
                                retryLabel: l10n.appInlineErrorRetry,
                                manageAgentsLabel: l10n.clientAgentsPageTitle,
                              ),
                            ),
                          ],
                          if (overview != null &&
                              overview.hasMissingClientToken &&
                              !overview.requiresClientTokenSetup) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              tone: AppInlinePanelTone.informational,
                              title: l10n.dashboardMissingClientTokenTitle,
                              message: l10n.dashboardMissingClientTokenMessage(
                                _previewAgentNames(
                                  overview.agentNamesMissingClientToken,
                                ),
                              ),
                              actions: _OverviewPanelActions(
                                onManageAgents: () =>
                                    context.goTo(AppRoute.agents),
                                primaryLabel: l10n.clientAgentsPageTitle,
                                manageAgentsLabel: l10n.clientAgentsPageTitle,
                              ),
                            ),
                          ],
                          if (overview != null &&
                              overview.hasPartialAgentQueryFailure) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              tone: AppInlinePanelTone.informational,
                              title: l10n.dashboardPartialAgentQueriesTitle,
                              message: l10n.dashboardPartialAgentQueriesMessage(
                                _previewAgentNames(
                                  overview.agentNamesExcludedFromQueryFailure,
                                ),
                              ),
                              actions: _OverviewPanelActions(
                                onRetry: sessionUserId == null
                                    ? null
                                    : () => unawaited(
                                        overviewController.retryOverview(
                                          userId: sessionUserId,
                                        ),
                                      ),
                                onManageAgents: () =>
                                    context.goTo(AppRoute.agents),
                                retryLabel: l10n.appInlineErrorRetry,
                                manageAgentsLabel: l10n.clientAgentsPageTitle,
                              ),
                            ),
                          ],
                          if (overview != null &&
                              overview.shouldShowMultiAgentAggregationNote) ...<
                            Widget
                          >[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              tone: AppInlinePanelTone.informational,
                              title: l10n.dashboardMultiAgentAggregationTitle,
                              message:
                                  l10n.dashboardMultiAgentAggregationMessage,
                            ),
                          ],
                          if (displayOverview != null) ...<Widget>[
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              loadingSemanticsLabel:
                                  l10n.overviewLoadingPaymentKpisSemantics,
                              child: _KpiBar(
                                l10n: l10n,
                                kpis: displayOverview.kpis,
                              ),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: Duration.zero,
                              loadingSemanticsLabel:
                                  l10n.overviewLoadingPaymentMixSemantics,
                              child: _PaymentMixCard(
                                l10n: l10n,
                                methods: displayOverview.paymentMethods,
                              ),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: const Duration(milliseconds: 80),
                              loadingSemanticsLabel:
                                  l10n.overviewLoadingPaymentBarSemantics,
                              child: _PaymentBarChart(
                                l10n: l10n,
                                methods: displayOverview.paymentMethods,
                              ),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: const Duration(milliseconds: 120),
                              loadingSemanticsLabel:
                                  l10n.overviewLoadingRankingsSemantics,
                              child: _RankingsSection(
                                l10n: l10n,
                                agentRankings: displayOverview.agentRankings,
                                userRankings: displayOverview.userRankings,
                              ),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: const Duration(milliseconds: 160),
                              loadingSemanticsLabel:
                                  l10n.dashboardPaymentSummaryLoadingSemantics,
                              child: _PaymentSummaryTable(
                                l10n: l10n,
                                methods: displayOverview.paymentMethods,
                                showSkeleton: showSkeleton,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
          ),
    );
  }
}

class _OverviewAutoLoader extends StatefulWidget {
  const _OverviewAutoLoader({
    required this.controller,
    required this.child,
    this.userId,
    this.isReady = false,
  });

  final OverviewController controller;
  final Widget child;
  final String? userId;
  final bool isReady;

  @override
  State<_OverviewAutoLoader> createState() => _OverviewAutoLoaderState();
}

class _OverviewAutoLoaderState extends State<_OverviewAutoLoader> {
  @override
  void initState() {
    super.initState();
    _scheduleLoadIfReady();
  }

  @override
  void didUpdateWidget(covariant _OverviewAutoLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.isReady != widget.isReady) {
      _scheduleLoadIfReady();
    }
  }

  void _scheduleLoadIfReady() {
    final userId = widget.userId;
    if (!widget.isReady || userId == null || userId.isEmpty) {
      return;
    }
    widget.controller.scheduleOverviewLoadIfNeeded(userId: userId);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------------
// Overview filter bar
// ---------------------------------------------------------------------------

class _OverviewFilterBar extends StatelessWidget {
  const _OverviewFilterBar({
    required this.l10n,
    required this.filter,
    required this.availableAgents,
    this.onFilterChanged,
  });

  final AppLocalizations l10n;
  final OverviewFilter filter;
  final List<OverviewAgentOption> availableAgents;
  final ValueChanged<OverviewFilter>? onFilterChanged;

  static bool _isAgentChecked(
    OverviewFilter filter,
    String agentId,
    Set<String> allAgentIds,
  ) {
    final sel = filter.selectedAgentIds;
    if (sel == null) {
      return true;
    }
    return sel.contains(agentId);
  }

  static void _toggleAgentSelection({
    required OverviewFilter filter,
    required String agentId,
    required List<OverviewAgentOption> availableAgents,
    required ValueChanged<OverviewFilter> onFilterChanged,
  }) {
    final allIds = availableAgents.map((e) => e.agentId).toSet();
    final current = filter.selectedAgentIds ?? allIds;
    final next = Set<String>.from(current);
    if (next.contains(agentId)) {
      next.remove(agentId);
    } else {
      next.add(agentId);
    }
    if (next.isEmpty) {
      return;
    }
    if (next.length == allIds.length && next.containsAll(allIds)) {
      onFilterChanged(filter.copyWith(selectedAgentIds: null));
    } else {
      onFilterChanged(filter.copyWith(selectedAgentIds: next));
    }
  }

  // Generates the last 13 months (current + 12 previous) as options.
  static List<OverviewYearMonth> _buildMonthOptions() {
    final now = DateTime.now();
    return List<OverviewYearMonth>.generate(13, (i) {
      var month = now.month - i;
      var year = now.year;
      while (month < 1) {
        month += 12;
        year -= 1;
      }
      return OverviewYearMonth(year: year, month: month);
    });
  }

  static String _monthLabel(BuildContext context, OverviewYearMonth ym) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateTime(ym.year, ym.month);
    return DateFormat.yMMM(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final colors = theme.appColors;
    final monthOptions = _buildMonthOptions();
    final isDisabled = onFilterChanged == null;

    final labelStyle = typography.utilityOverline.copyWith(
      color: colors.onSurfaceVariant,
      fontSize: 10,
    );

    Widget buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: labelStyle),
    );

    // Month dropdown
    final monthValue = filter.yearMonth;
    final monthItems = <DropdownMenuItem<OverviewYearMonth?>>[
      DropdownMenuItem<OverviewYearMonth?>(
        child: Text(
          l10n.dashboardHomeFiltersPeriodLast30Days,
          style: typography.body.copyWith(fontSize: 13),
        ),
      ),
      for (final ym in monthOptions)
        DropdownMenuItem<OverviewYearMonth?>(
          value: ym,
          child: Text(
            _monthLabel(context, ym),
            style: typography.body.copyWith(fontSize: 13),
          ),
        ),
    ];

    final inputDecoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.gapSm,
        vertical: tokens.gapSm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        borderSide: BorderSide(color: cs.primary),
      ),
      filled: true,
      fillColor: cs.surfaceContainerLow,
    );

    final hasActiveFilter = !filter.isDefault;
    final allAgentIds = availableAgents.map((e) => e.agentId).toSet();

    return AppSectionCard(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.tune_rounded,
                size: 14,
                color: hasActiveFilter ? cs.primary : colors.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapXs),
              Text(
                l10n.reportFiltersTitle,
                style: typography.utilityOverline.copyWith(
                  color: hasActiveFilter ? cs.primary : colors.onSurfaceVariant,
                ),
              ),
              if (hasActiveFilter) ...<Widget>[
                SizedBox(width: tokens.gapSm),
                GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => onFilterChanged!(const OverviewFilter()),
                  child: Text(
                    l10n.reportFiltersClearAction,
                    style: typography.caption.copyWith(
                      color: cs.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: cs.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: tokens.gapSm),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              final agentField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.dashboardHomeFiltersAgentsLabel,
                            style: labelStyle,
                          ),
                        ),
                      ),
                      if (!isDisabled &&
                          availableAgents.isNotEmpty &&
                          filter.selectedAgentIds != null)
                        TextButton(
                          onPressed: () => onFilterChanged!(
                            filter.copyWith(selectedAgentIds: null),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.reportInlineFiltersAllOption,
                            style: typography.caption.copyWith(
                              color: cs.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (availableAgents.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: tokens.gapXs),
                      child: Text(
                        l10n.dashboardHomeFiltersAgentsEmptyHint,
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...availableAgents.map(
                      (a) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        value: _isAgentChecked(filter, a.agentId, allAgentIds),
                        onChanged: isDisabled
                            ? null
                            : (_) {
                                _toggleAgentSelection(
                                  filter: filter,
                                  agentId: a.agentId,
                                  availableAgents: availableAgents,
                                  onFilterChanged: onFilterChanged!,
                                );
                              },
                        title: Text(
                          a.name,
                          style: typography.body.copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                ],
              );

              final monthField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  buildLabel(l10n.dashboardHomeFiltersYearMonthLabel),
                  DropdownButtonFormField<OverviewYearMonth?>(
                    initialValue: monthValue,
                    items: monthItems,
                    isExpanded: true,
                    decoration: inputDecoration,
                    style: typography.body.copyWith(
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                    onChanged: isDisabled
                        ? null
                        : (v) => onFilterChanged!(
                            filter.copyWith(yearMonth: v),
                          ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    agentField,
                    SizedBox(height: tokens.gapMd),
                    monthField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: agentField),
                  SizedBox(width: tokens.gapMd),
                  Expanded(child: monthField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewPanelActions extends StatelessWidget {
  const _OverviewPanelActions({
    required this.manageAgentsLabel,
    this.onRetry,
    this.onManageAgents,
    this.retryLabel,
    this.primaryLabel,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onManageAgents;
  final String? retryLabel;
  final String? primaryLabel;
  final String manageAgentsLabel;

  @override
  Widget build(BuildContext context) {
    assert(
      onRetry == null || (retryLabel != null && retryLabel!.isNotEmpty),
      'retryLabel is required when onRetry is set',
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: <Widget>[
        if (onRetry != null)
          AppPrimaryButton(
            label: primaryLabel ?? retryLabel!,
            onPressed: onRetry,
          ),
        if (onManageAgents != null)
          (onRetry == null
              ? AppPrimaryButton(
                  label: primaryLabel ?? manageAgentsLabel,
                  icon: const Icon(Icons.hub_rounded),
                  onPressed: onManageAgents,
                )
              : AppSecondaryButton(
                  label: manageAgentsLabel,
                  icon: const Icon(Icons.hub_outlined),
                  onPressed: onManageAgents,
                )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// KPI bar
// ---------------------------------------------------------------------------

class _KpiBar extends StatelessWidget {
  const _KpiBar({required this.l10n, required this.kpis});

  final AppLocalizations l10n;
  final OverviewPaymentKpis kpis;

  @override
  Widget build(BuildContext context) {
    return AppReportSummaryBar(
      items: <AppReportSummaryItem>[
        AppReportSummaryItem(
          label: l10n.overviewKpiTotalRevenue,
          value: AppBrFormatters.currency(kpis.totalAmount),
          icon: Icons.payments_outlined,
        ),
        AppReportSummaryItem(
          label: l10n.overviewKpiSales,
          value: kpis.totalSalesCount.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        AppReportSummaryItem(
          label: l10n.overviewKpiAvgTicket,
          value: AppBrFormatters.currency(kpis.averageTicket),
          icon: Icons.local_offer_outlined,
        ),
        AppReportSummaryItem(
          label: l10n.overviewKpiPaymentMethodCount,
          value: kpis.paymentMethodCount.toString(),
          icon: Icons.credit_card_outlined,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Payment mix donut
// ---------------------------------------------------------------------------

class _PaymentMixCard extends StatelessWidget {
  const _PaymentMixCard({required this.l10n, required this.methods});

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;

  @override
  Widget build(BuildContext context) {
    final total = methods.fold<double>(0, (sum, m) => sum + m.totalAmount);

    return AppCategoryDonutCard(
      title: l10n.overviewPaymentMixTitle,
      subtitle: l10n.overviewPaymentMixSubtitle,
      segments: methods
          .map(
            (m) => AppCategoryDonutSegment(
              label: m.label,
              value: m.totalAmount,
              valueLabel: AppBrFormatters.currency(m.totalAmount),
              percentLabel: '${m.sharePercent.toStringAsFixed(1)}%',
            ),
          )
          .toList(growable: false),
      centerPrimaryLabel: total > 0
          ? AppBrFormatters.compactCurrency(total)
          : null,
      centerSecondaryLabel: l10n.overviewPaymentMixDonutTotalLabel,
    );
  }
}

// ---------------------------------------------------------------------------
// Payment bar chart
// ---------------------------------------------------------------------------

enum _OverviewHomeBarChartKind {
  payment,
  ranking,
}

/// Shared [AppComparisonBarChartStyle] for overview bar charts: compact Y axis,
/// data labels, two-line category labels, optional ranking-only density/height.
AppComparisonBarChartStyle _overviewHomeComparisonBarChartStyle({
  required AppThemeTokens tokens,
  required _OverviewHomeBarChartKind kind,
  required String horizontalScrollSemanticsHint,
}) {
  final isRanking = kind == _OverviewHomeBarChartKind.ranking;
  return AppComparisonBarChartStyle(
    yAxisFormat: AppBrFormatters.compactCurrencyFormat,
    horizontalScrollSemanticsHint: horizontalScrollSemanticsHint,
    showDataLabels: true,
    autoRotateXLabels: false,
    wrapXAxisLabelsInTwoLines: true,
    wrapXAxisCharsPerLine: isRanking ? 14 : 12,
    minBarWidth: isRanking ? 84 : null,
    height: isRanking
        ? tokens.chartStandardHeight + tokens.contentSpacing * 3
        : null,
  );
}

class _PaymentBarChart extends StatelessWidget {
  const _PaymentBarChart({required this.l10n, required this.methods});

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AppComparisonBarChart<OverviewPaymentMethodBreakdown>(
      title: l10n.overviewPaymentBarTitle,
      subtitle: l10n.overviewPaymentBarSubtitle,
      items: methods,
      labelBuilder: (m) => m.label,
      valueBuilder: (m) => m.totalAmount,
      tooltipLabelBuilder: (m, v) => l10n.overviewPaymentBarTooltip(
        m.label,
        AppBrFormatters.currency(v),
      ),
      dataLabelBuilder: (m, v) => AppBrFormatters.compactCurrency(v),
      style: _overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: _OverviewHomeBarChartKind.payment,
        horizontalScrollSemanticsHint:
            l10n.overviewComparisonBarHorizontalScrollHint,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rankings section (agent + user)
// ---------------------------------------------------------------------------

class _RankingsSection extends StatelessWidget {
  const _RankingsSection({
    required this.l10n,
    required this.agentRankings,
    required this.userRankings,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentRanking> agentRankings;
  final List<OverviewUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _AgentRankingCard(
          l10n: l10n,
          agentRankings: agentRankings,
        ),
        SizedBox(height: tokens.sectionSpacing),
        _UserRankingCard(
          l10n: l10n,
          userRankings: userRankings,
        ),
      ],
    );
  }
}

class _AgentRankingCard extends StatelessWidget {
  const _AgentRankingCard({
    required this.l10n,
    required this.agentRankings,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentRanking> agentRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AppComparisonBarChart<OverviewAgentRanking>(
      title: l10n.dashboardAgentRankingTitle,
      subtitle: l10n.dashboardAgentRankingSubtitle,
      items: agentRankings,
      labelBuilder: (a) => a.displayName,
      valueBuilder: (a) => a.totalAmount,
      tooltipLabelBuilder: (a, v) =>
          '${a.displayName}: ${AppBrFormatters.currency(v)}',
      dataLabelBuilder: (a, v) => AppBrFormatters.compactCurrency(v),
      style: _overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: _OverviewHomeBarChartKind.ranking,
        horizontalScrollSemanticsHint:
            l10n.overviewComparisonBarHorizontalScrollHint,
      ),
    );
  }
}

class _UserRankingCard extends StatelessWidget {
  const _UserRankingCard({
    required this.l10n,
    required this.userRankings,
  });

  final AppLocalizations l10n;
  final List<OverviewUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AppComparisonBarChart<OverviewUserRanking>(
      title: l10n.dashboardUserRankingTitle,
      subtitle: l10n.dashboardUserRankingSubtitle,
      items: userRankings,
      labelBuilder: (u) => u.userName,
      valueBuilder: (u) => u.totalAmount,
      tooltipLabelBuilder: (u, v) =>
          '${u.userName}: ${AppBrFormatters.currency(v)}',
      dataLabelBuilder: (u, v) => AppBrFormatters.compactCurrency(v),
      style: _overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: _OverviewHomeBarChartKind.ranking,
        horizontalScrollSemanticsHint:
            l10n.overviewComparisonBarHorizontalScrollHint,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment summary table
// ---------------------------------------------------------------------------

const double _kPaymentSummaryTableTypeScale = 0.92;
const int _kPaymentSummaryMaxRowsBeforeInnerScroll = 8;
const double _kPaymentSummaryInnerListMaxHeight = 320;

TextStyle _scaledPaymentSummaryTextStyle(TextStyle base) {
  final fs = base.fontSize;
  if (fs == null) {
    return base;
  }
  return base.copyWith(fontSize: fs * _kPaymentSummaryTableTypeScale);
}

TextStyle _tabularFigures(TextStyle style) {
  return style.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

class _PaymentSummaryTable extends StatelessWidget {
  const _PaymentSummaryTable({
    required this.l10n,
    required this.methods,
    required this.showSkeleton,
  });

  final AppLocalizations l10n;
  final List<OverviewPaymentMethodBreakdown> methods;
  final bool showSkeleton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    final Widget body;
    if (methods.isEmpty) {
      if (showSkeleton) {
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _PaymentTableHeader(l10n: l10n),
            SizedBox(height: tokens.gapMd * 3),
          ],
        );
      } else {
        body = AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          variant: AppInlineErrorPanelVariant.plain,
          title: l10n.dashboardPaymentSummaryEmptyTitle,
          message: l10n.dashboardPaymentSummaryEmptyMessage,
        );
      }
    } else if (methods.length <= _kPaymentSummaryMaxRowsBeforeInnerScroll) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PaymentTableHeader(l10n: l10n),
          ...methods.asMap().entries.map(
            (e) => _PaymentTableRow(
              l10n: l10n,
              method: e.value,
              showTopDivider: e.key > 0,
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PaymentTableHeader(l10n: l10n),
          SizedBox(
            height: _kPaymentSummaryInnerListMaxHeight,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              itemCount: methods.length,
              itemBuilder: (context, index) {
                return _PaymentTableRow(
                  l10n: l10n,
                  method: methods[index],
                  showTopDivider: index > 0,
                );
              },
            ),
          ),
        ],
      );
    }

    return AppSectionCardWithHeading(
      title: l10n.dashboardPaymentSummaryTitle,
      subtitle: l10n.dashboardPaymentSummarySubtitle,
      style: AppSectionCardWithHeadingStyle(
        titleTextStyle: _scaledPaymentSummaryTextStyle(
          typography.sectionHeaderH2,
        ),
        subtitleTextStyle: _scaledPaymentSummaryTextStyle(
          typography.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      child: body,
    );
  }
}

class _PaymentTableHeader extends StatelessWidget {
  const _PaymentTableHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    final style =
        _scaledPaymentSummaryTextStyle(
          typography.utilityOverline,
        ).copyWith(
          color: cs.onSurfaceVariant,
        );
    final bodyStyle = _scaledPaymentSummaryTextStyle(typography.body);
    final highlightStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: Opacity(
            opacity: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ' ',
                style: highlightStyle,
                maxLines: 1,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Tooltip(
              message: l10n.dashboardPaymentSummaryTooltipRevenueAbbr,
              child: Text(
                l10n.dashboardPaymentSummaryHeaderRevenueAbbr,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: tokens.gapMd),
            Text(
              l10n.dashboardPaymentSummaryHeaderSales,
              style: style,
              textAlign: TextAlign.right,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: tokens.gapMd),
            Text(
              l10n.dashboardPaymentSummaryHeaderAvgTicket,
              style: style,
              textAlign: TextAlign.right,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: tokens.gapMd),
            Tooltip(
              message: l10n.dashboardPaymentSummaryTooltipParticipationAbbr,
              child: Text(
                l10n.dashboardPaymentSummaryHeaderParticipationAbbr,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.gapSm),
        Divider(
          height: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

class _PaymentSummaryValuesScrollRow extends StatelessWidget {
  const _PaymentSummaryValuesScrollRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentTableRow extends StatelessWidget {
  const _PaymentTableRow({
    required this.l10n,
    required this.method,
    required this.showTopDivider,
  });

  final AppLocalizations l10n;
  final OverviewPaymentMethodBreakdown method;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final bodyStyle = _tabularFigures(
      _scaledPaymentSummaryTextStyle(typography.body),
    );
    final highlightStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);
    final percentText = method.sharePercent.toStringAsFixed(1);
    final lang = Localizations.localeOf(context).languageCode;
    final percentSemanticsValue = lang == 'en'
        ? percentText
        : percentText.replaceAll('.', ',');
    final amountStyle = _tabularFigures(
      bodyStyle.copyWith(fontWeight: FontWeight.w600),
    );
    final percentStyle = _tabularFigures(
      bodyStyle.copyWith(color: cs.onSurface),
    );
    final amountText = AppBrFormatters.currency(method.totalAmount);
    final averageTicketText = AppBrFormatters.currency(method.averageTicket);

    final title = Semantics(
      label: l10n.overviewSemanticsPaymentMethodRow(method.label),
      child: Text(
        method.label,
        style: highlightStyle,
        textAlign: TextAlign.left,
        maxLines: 3,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final valuesRow = _PaymentSummaryValuesScrollRow(
      children: <Widget>[
        Semantics(
          label: l10n.overviewSemanticsRevenue(amountText),
          child: ExcludeSemantics(
            child: Text(
              amountText,
              style: amountStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Semantics(
          label: l10n.overviewSemanticsSalesCount(
            method.totalSalesCount.toString(),
          ),
          child: ExcludeSemantics(
            child: Text(
              method.totalSalesCount.toString(),
              style: bodyStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Semantics(
          label: l10n.overviewSemanticsAvgTicket(averageTicketText),
          child: ExcludeSemantics(
            child: Text(
              averageTicketText,
              style: bodyStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: tokens.gapMd),
        Semantics(
          label: l10n.overviewSemanticsSharePercent(percentSemanticsValue),
          child: ExcludeSemantics(
            child: Text(
              '$percentText%',
              style: percentStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        title,
        SizedBox(height: tokens.gapXs),
        valuesRow,
      ],
    );

    return DecoratedBox(
      decoration: showTopDivider
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.gapSm),
        child: column,
      ),
    );
  }
}
