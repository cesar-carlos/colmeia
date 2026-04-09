import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_filial_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
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
    filialRankings: const <DashboardFilialRanking>[],
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

  static String _previewExcludedAgentIds(List<String> ids) {
    if (ids.isEmpty) {
      return '';
    }
    const maxShown = 4;
    if (ids.length <= maxShown) {
      return ids.join(', ');
    }
    final head = ids.take(maxShown).join(', ');
    return '$head (+${ids.length - maxShown})';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child: Consumer3<AuthController, CurrentUserContextController,
          DashboardController>(
        builder: (
          context,
          authController,
          userContext,
          dashboardController,
          _,
        ) {
          dashboardController.activeLocalizations =
              AppLocalizations.of(context);
          final theme = Theme.of(context);
          final tokens = theme.extension<AppThemeTokens>()!;
          final l10n = AppLocalizations.of(context);
          final session = authController.session;
          final overview = dashboardController.overview;
          final showSkeleton =
              dashboardController.isLoadingInitial && overview == null;
          final displayOverview =
              overview ?? (showSkeleton ? _neutralSkeletonOverview : null);

          if (session != null &&
              !userContext.isLoadingInitial &&
              userContext.errorMessage == null &&
              userContext.hasResolvedData) {
            dashboardController.scheduleOverviewLoadIfNeeded(
              userId: session.userId,
            );
          }

          final greetingName = _greetingFirstName(userContext.userScope.name);
          final sessionUserId = session?.userId;

          Future<void> onRefresh() async {
            final current = authController.session;
            if (current == null) return;
            await dashboardController.refreshOverview(userId: current.userId);
          }

          final periodLabel = (overview != null && !showSkeleton)
              ? '${AppBrFormatters.shortDate(overview.periodStart)}'
                    ' – '
                    '${AppBrFormatters.shortDate(overview.periodEnd)}'
              : null;

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: context.pageScrollPadding(tokens),
              children: <Widget>[
                AppShellPageIntro(
                  eyebrow: 'Ola, $greetingName',
                  title: 'Dashboard de Pagamentos',
                  subtitle: 'Resumo consolidado dos agentes aprovados '
                      '(todas as filiais conectadas).',
                  footer: periodLabel != null
                      ? AppTagChip(
                          label: periodLabel,
                          icon: Icons.calendar_today_outlined,
                        )
                      : null,
                ),
                if (dashboardController.errorMessage case final String msg) ...<
                    Widget>[
                  SizedBox(height: tokens.gapMd),
                  AppInlineErrorPanel(
                    title: 'Nao foi possivel carregar o dashboard',
                    message: msg,
                    onRetry: sessionUserId != null
                        ? () => unawaited(
                              dashboardController.retryOverview(
                                userId: sessionUserId,
                              ),
                            )
                        : null,
                  ),
                ],
                if (overview?.isStaleCache == true) ...<Widget>[
                  SizedBox(height: tokens.gapMd),
                  AppInlineErrorPanel(
                    tone: AppInlinePanelTone.informational,
                    title: 'Dados salvos neste aparelho',
                    message:
                        'Nao foi possivel atualizar agora. Os numeros abaixo '
                        'refletem o ultimo resumo obtido com sucesso.',
                    onRetry: sessionUserId != null
                        ? () => unawaited(
                              dashboardController.retryOverview(
                                userId: sessionUserId,
                              ),
                            )
                        : null,
                  ),
                ],
                if (overview != null && overview.hasMissingClientToken) ...<
                    Widget>[
                  SizedBox(height: tokens.gapMd),
                  AppInlineErrorPanel(
                    tone: AppInlinePanelTone.informational,
                    title: l10n.dashboardMissingClientTokenTitle,
                    message: l10n.dashboardMissingClientTokenMessage(
                      _previewExcludedAgentIds(
                        overview.agentIdsMissingClientToken,
                      ),
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
                      _previewExcludedAgentIds(
                        overview.agentIdsExcludedFromQueryFailure,
                      ),
                    ),
                  ),
                ],
                if (overview != null &&
                    overview.shouldShowMultiAgentAggregationNote) ...<Widget>[
                  SizedBox(height: tokens.gapMd),
                  AppInlineErrorPanel(
                    tone: AppInlinePanelTone.informational,
                    title: l10n.dashboardMultiAgentAggregationTitle,
                    message: l10n.dashboardMultiAgentAggregationMessage,
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
                        'Carregando faturamento por forma de pagamento...',
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
                      filialRankings: displayOverview.filialRankings,
                      userRankings: displayOverview.userRankings,
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    showDelay: const Duration(milliseconds: 160),
                    loadingSemanticsLabel:
                        'Carregando tabela de formas de pagamento...',
                    child: _PaymentSummaryTable(
                      methods: displayOverview.paymentMethods,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
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
      centerPrimaryLabel:
          total > 0 ? AppBrFormatters.compactCurrency(total) : null,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rankings section (filial + user)
// ---------------------------------------------------------------------------

class _RankingsSection extends StatelessWidget {
  const _RankingsSection({
    required this.filialRankings,
    required this.userRankings,
  });

  final List<DashboardFilialRanking> filialRankings;
  final List<DashboardUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final filialCard = _FilialRankingCard(filialRankings: filialRankings);
    final userCard = _UserRankingCard(userRankings: userRankings);

    if (AppBreakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          filialCard,
          SizedBox(height: tokens.sectionSpacing),
          userCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: filialCard),
        SizedBox(width: tokens.gapMd),
        Expanded(child: userCard),
      ],
    );
  }
}

class _FilialRankingCard extends StatelessWidget {
  const _FilialRankingCard({required this.filialRankings});

  final List<DashboardFilialRanking> filialRankings;

  @override
  Widget build(BuildContext context) {
    return AppComparisonBarChart<DashboardFilialRanking>(
      title: 'Ranking por filial',
      subtitle: 'Faturamento por filial no periodo.',
      items: filialRankings,
      labelBuilder: (f) => 'Fil. ${f.codFilial}',
      valueBuilder: (f) => f.totalAmount,
      tooltipLabelBuilder: (f, v) =>
          '${f.label}: ${AppBrFormatters.currency(v)}',
      style: AppComparisonBarChartStyle(
        yAxisFormat: AppBrFormatters.compactCurrencyFormat,
      ),
    );
  }
}

class _UserRankingCard extends StatelessWidget {
  const _UserRankingCard({required this.userRankings});

  final List<DashboardUserRanking> userRankings;

  @override
  Widget build(BuildContext context) {
    return AppComparisonBarChart<DashboardUserRanking>(
      title: 'Ranking por operador',
      subtitle: 'Faturamento por operador no periodo.',
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

class _PaymentSummaryTable extends StatelessWidget {
  const _PaymentSummaryTable({required this.methods});

  final List<DashboardPaymentMethodBreakdown> methods;

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppSectionCardWithHeading(
      title: 'Resumo por forma de pagamento',
      subtitle: 'Detalhamento de vendas, ticket medio e participacao.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PaymentTableHeader(),
          ...methods.map((m) => _PaymentTableRow(method: m)),
        ],
      ),
    );
  }
}

class _PaymentTableHeader extends StatelessWidget {
  const _PaymentTableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    final style = typography.utilityOverline.copyWith(
      color: cs.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: Row(
        children: <Widget>[
          const Expanded(flex: 3, child: SizedBox.shrink()),
          Expanded(
            flex: 2,
            child: Text(
              'FATURAMENTO',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              'VENDAS',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TICKET MEDIO',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '%',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTableRow extends StatelessWidget {
  const _PaymentTableRow({required this.method});

  final DashboardPaymentMethodBreakdown method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.gapSm),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Text(
                method.label,
                style: typography.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                AppBrFormatters.currency(method.totalAmount),
                style: typography.body,
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                method.totalSalesCount.toString(),
                style: typography.body,
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                AppBrFormatters.currency(method.averageTicket),
                style: typography.body,
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                '${method.sharePercent.toStringAsFixed(1)}%',
                style: typography.body.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
