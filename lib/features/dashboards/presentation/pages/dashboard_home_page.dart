import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_agent_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_filter.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
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

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  /// Neutral placeholders (no plausible KPIs before real data).
  static final DashboardOverview _neutralSkeletonOverview = DashboardOverview(
    periodStart: DateTime(1970),
    periodEnd: DateTime(1970),
    kpis: const DashboardPaymentKpis(
      totalSalesCount: 0,
      totalAmount: 0,
      averageTicket: 0,
      paymentMethodCount: 0,
    ),
    paymentMethods: const <DashboardPaymentMethodBreakdown>[],
    agentRankings: const <DashboardAgentRanking>[],
    userRankings: const <DashboardUserRanking>[],
  );

  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<DashboardController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _greetingFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Gestor';
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
    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child:
          Consumer3<
            AuthController,
            CurrentUserContextController,
            DashboardController
          >(
            builder:
                (
                  context,
                  authController,
                  userContext,
                  dashboardController,
                  _,
                ) {
                  dashboardController.activeLocalizations = AppLocalizations.of(
                    context,
                  );
                  final theme = Theme.of(context);
                  final tokens = theme.extension<AppThemeTokens>()!;
                  final l10n = AppLocalizations.of(context);
                  final session = authController.session;
                  final overview = dashboardController.overview;
                  final sessionUserId = session?.userId;
                  final isUserContextReady =
                      sessionUserId != null &&
                      !userContext.isLoadingInitial &&
                      userContext.errorMessage == null &&
                      userContext.hasResolvedData;
                  final showSkeleton =
                      dashboardController.isLoadingInitial && overview == null;
                  final displayOverview = showSkeleton
                      ? _neutralSkeletonOverview
                      : overview;

                  final greetingName = _greetingFirstName(
                    userContext.userScope.name,
                  );

                  Future<void> onRefresh() async {
                    final current = authController.session;
                    if (current == null) return;
                    await dashboardController.refreshOverview(
                      userId: current.userId,
                    );
                  }

                  final periodLabel = (overview != null && !showSkeleton)
                      ? '${AppBrFormatters.shortDate(overview.periodStart)}'
                            ' – '
                            '${AppBrFormatters.shortDate(overview.periodEnd)}'
                      : null;

                  return _DashboardAutoLoader(
                    controller: dashboardController,
                    userId: sessionUserId,
                    isReady: isUserContextReady,
                    child: RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: context.pageScrollPadding(tokens),
                        children: <Widget>[
                          AppShellPageIntro(
                            eyebrow: 'Ola, $greetingName',
                            subtitle:
                                'Resumo consolidado dos agentes aprovados '
                                '(todas as filiais conectadas).',
                            footer: periodLabel != null
                                ? AppTagChip(
                                    label: periodLabel,
                                    icon: Icons.calendar_today_outlined,
                                  )
                                : null,
                          ),
                          SizedBox(height: tokens.gapMd),
                          _DashboardFilterBar(
                            l10n: l10n,
                            filter: dashboardController.activeFilter,
                            availableAgents:
                                dashboardController.availableAgents,
                            onFilterChanged: sessionUserId == null
                                ? null
                                : (f) => unawaited(
                                    dashboardController.applyFilter(
                                      userId: sessionUserId,
                                      filter: f,
                                    ),
                                  ),
                          ),
                          if (dashboardController.errorMessage
                              case final String msg) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              title: 'Nao foi possivel carregar o dashboard',
                              message: msg,
                              actions: _DashboardPanelActions(
                                onRetry: sessionUserId == null
                                    ? null
                                    : () => unawaited(
                                        dashboardController.retryOverview(
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
                              actions: _DashboardPanelActions(
                                onManageAgents: () =>
                                    context.goTo(AppRoute.agents),
                                primaryLabel: l10n.clientAgentsPageTitle,
                              ),
                            ),
                          ],
                          if (overview?.isStaleCache == true) ...<Widget>[
                            SizedBox(height: tokens.gapMd),
                            AppInlineErrorPanel(
                              tone: AppInlinePanelTone.informational,
                              title: 'Dados salvos neste aparelho',
                              message:
                                  'Nao foi possivel atualizar agora. '
                                  'Os numeros abaixo refletem o ultimo '
                                  'resumo obtido com sucesso.',
                              actions: _DashboardPanelActions(
                                onRetry: sessionUserId == null
                                    ? null
                                    : () => unawaited(
                                        dashboardController.retryOverview(
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
                              actions: _DashboardPanelActions(
                                onManageAgents: () =>
                                    context.goTo(AppRoute.agents),
                                primaryLabel: l10n.clientAgentsPageTitle,
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
                              actions: _DashboardPanelActions(
                                onRetry: sessionUserId == null
                                    ? null
                                    : () => unawaited(
                                        dashboardController.retryOverview(
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
                                  'Carregando indicadores de pagamento...',
                              child: _KpiBar(kpis: displayOverview.kpis),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: Duration.zero,
                              loadingSemanticsLabel:
                                  'Carregando mix de formas de pagamento...',
                              child: _PaymentMixCard(
                                methods: displayOverview.paymentMethods,
                              ),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: const Duration(milliseconds: 80),
                              loadingSemanticsLabel:
                                  'Carregando faturamento '
                                  'por forma de pagamento...',
                              child: _PaymentBarChart(
                                methods: displayOverview.paymentMethods,
                              ),
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            AppSkeleton(
                              enabled: showSkeleton,
                              showDelay: const Duration(milliseconds: 120),
                              loadingSemanticsLabel: 'Carregando rankings...',
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

class _DashboardAutoLoader extends StatefulWidget {
  const _DashboardAutoLoader({
    required this.controller,
    required this.child,
    this.userId,
    this.isReady = false,
  });

  final DashboardController controller;
  final Widget child;
  final String? userId;
  final bool isReady;

  @override
  State<_DashboardAutoLoader> createState() => _DashboardAutoLoaderState();
}

class _DashboardAutoLoaderState extends State<_DashboardAutoLoader> {
  @override
  void initState() {
    super.initState();
    _scheduleLoadIfReady();
  }

  @override
  void didUpdateWidget(covariant _DashboardAutoLoader oldWidget) {
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
// Dashboard filter bar
// ---------------------------------------------------------------------------

class _DashboardFilterBar extends StatelessWidget {
  const _DashboardFilterBar({
    required this.l10n,
    required this.filter,
    required this.availableAgents,
    this.onFilterChanged,
  });

  final AppLocalizations l10n;
  final DashboardFilter filter;
  final List<DashboardAgentOption> availableAgents;
  final ValueChanged<DashboardFilter>? onFilterChanged;

  static bool _isAgentChecked(
    DashboardFilter filter,
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
    required DashboardFilter filter,
    required String agentId,
    required List<DashboardAgentOption> availableAgents,
    required ValueChanged<DashboardFilter> onFilterChanged,
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
  static List<DashboardYearMonth> _buildMonthOptions() {
    final now = DateTime.now();
    return List<DashboardYearMonth>.generate(13, (i) {
      var month = now.month - i;
      var year = now.year;
      while (month < 1) {
        month += 12;
        year -= 1;
      }
      return DashboardYearMonth(year: year, month: month);
    });
  }

  static String _monthLabel(BuildContext context, DashboardYearMonth ym) {
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
    final monthItems = <DropdownMenuItem<DashboardYearMonth?>>[
      DropdownMenuItem<DashboardYearMonth?>(
        child: Text(
          l10n.dashboardHomeFiltersPeriodLast30Days,
          style: typography.body.copyWith(fontSize: 13),
        ),
      ),
      for (final ym in monthOptions)
        DropdownMenuItem<DashboardYearMonth?>(
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
                      : () => onFilterChanged!(const DashboardFilter()),
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
                  DropdownButtonFormField<DashboardYearMonth?>(
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

class _DashboardPanelActions extends StatelessWidget {
  const _DashboardPanelActions({
    this.onRetry,
    this.onManageAgents,
    this.retryLabel = 'Tentar novamente',
    this.primaryLabel,
    this.manageAgentsLabel = 'Gestao de agentes',
  });

  final VoidCallback? onRetry;
  final VoidCallback? onManageAgents;
  final String retryLabel;
  final String? primaryLabel;
  final String manageAgentsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: <Widget>[
        if (onRetry != null)
          AppPrimaryButton(
            label: primaryLabel ?? retryLabel,
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
  const _KpiBar({required this.kpis});

  final DashboardPaymentKpis kpis;

  @override
  Widget build(BuildContext context) {
    return AppReportSummaryBar(
      items: <AppReportSummaryItem>[
        AppReportSummaryItem(
          label: 'Faturamento total',
          value: AppBrFormatters.currency(kpis.totalAmount),
          icon: Icons.payments_outlined,
        ),
        AppReportSummaryItem(
          label: 'Vendas',
          value: kpis.totalSalesCount.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        AppReportSummaryItem(
          label: 'Ticket medio',
          value: AppBrFormatters.currency(kpis.averageTicket),
          icon: Icons.local_offer_outlined,
        ),
        AppReportSummaryItem(
          label: 'Formas de pagamento',
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
  const _PaymentMixCard({required this.methods});

  final List<DashboardPaymentMethodBreakdown> methods;

  @override
  Widget build(BuildContext context) {
    final total = methods.fold<double>(0, (sum, m) => sum + m.totalAmount);

    return AppCategoryDonutCard(
      title: 'Mix por forma de pagamento',
      subtitle: 'Participacao percentual no faturamento do periodo.',
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
      centerSecondaryLabel: 'TOTAL',
    );
  }
}

// ---------------------------------------------------------------------------
// Payment bar chart
// ---------------------------------------------------------------------------

class _PaymentBarChart extends StatelessWidget {
  const _PaymentBarChart({required this.methods});

  final List<DashboardPaymentMethodBreakdown> methods;

  @override
  Widget build(BuildContext context) {
    return AppComparisonBarChart<DashboardPaymentMethodBreakdown>(
      title: 'Faturamento por forma de pagamento',
      subtitle: 'Valor total acumulado no periodo.',
      items: methods,
      labelBuilder: (m) => m.label,
      valueBuilder: (m) => m.totalAmount,
      tooltipLabelBuilder: (m, v) =>
          '${m.label}: ${AppBrFormatters.currency(v)}',
      dataLabelBuilder: (m, v) => AppBrFormatters.compactCurrency(v),
      style: const AppComparisonBarChartStyle(
        showDataLabels: true,
        autoRotateXLabels: false,
        wrapXAxisLabelsInTwoLines: true,
        wrapXAxisCharsPerLine: 12,
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
  final List<DashboardAgentRanking> agentRankings;
  final List<DashboardUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final agentCard = _AgentRankingCard(
      l10n: l10n,
      agentRankings: agentRankings,
    );
    final userCard = _UserRankingCard(
      l10n: l10n,
      userRankings: userRankings,
    );

    if (AppBreakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          agentCard,
          SizedBox(height: tokens.sectionSpacing),
          userCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: agentCard),
        SizedBox(width: tokens.gapMd),
        Expanded(child: userCard),
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
  final List<DashboardAgentRanking> agentRankings;

  @override
  Widget build(BuildContext context) {
    return AppComparisonBarChart<DashboardAgentRanking>(
      title: l10n.dashboardAgentRankingTitle,
      subtitle: l10n.dashboardAgentRankingSubtitle,
      items: agentRankings,
      labelBuilder: (a) => a.displayName,
      valueBuilder: (a) => a.totalAmount,
      tooltipLabelBuilder: (a, v) =>
          '${a.displayName}: ${AppBrFormatters.currency(v)}',
      style: AppComparisonBarChartStyle(
        yAxisFormat: AppBrFormatters.compactCurrencyFormat,
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
  final List<DashboardUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    return AppComparisonBarChart<DashboardUserRanking>(
      title: l10n.dashboardUserRankingTitle,
      subtitle: l10n.dashboardUserRankingSubtitle,
      items: userRankings,
      labelBuilder: (u) => u.userName,
      valueBuilder: (u) => u.totalAmount,
      tooltipLabelBuilder: (u, v) =>
          '${u.userName}: ${AppBrFormatters.currency(v)}',
      style: AppComparisonBarChartStyle(
        yAxisFormat: AppBrFormatters.compactCurrencyFormat,
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
  final List<DashboardPaymentMethodBreakdown> methods;
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
    required this.method,
    required this.showTopDivider,
  });

  final DashboardPaymentMethodBreakdown method;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final bodyStyle =
        _tabularFigures(_scaledPaymentSummaryTextStyle(typography.body));
    final highlightStyle = bodyStyle.copyWith(fontWeight: FontWeight.w600);
    final percentText = method.sharePercent.toStringAsFixed(1);
    final percentSemantics = '${percentText.replaceAll('.', ',')} por cento';
    final amountStyle = _tabularFigures(
      bodyStyle.copyWith(fontWeight: FontWeight.w600),
    );
    final percentStyle = _tabularFigures(
      bodyStyle.copyWith(color: cs.onSurface),
    );
    final amountText = AppBrFormatters.currency(method.totalAmount);
    final averageTicketText = AppBrFormatters.currency(method.averageTicket);

    final title = Semantics(
      label: 'Forma de pagamento ${method.label}',
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
          label: 'Faturamento $amountText',
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
          label: 'Vendas ${method.totalSalesCount}',
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
          label: 'Ticket medio $averageTicketText',
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
          label: 'Participacao $percentSemantics',
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
