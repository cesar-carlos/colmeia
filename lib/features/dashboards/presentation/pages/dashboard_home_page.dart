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
  static final DashboardOverview _skeletonOverview = DashboardOverview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const DashboardPaymentKpis(
      totalSalesCount: 310,
      totalAmount: 27850.75,
      averageTicket: 89.84,
      paymentMethodCount: 4,
    ),
    paymentMethods: const <DashboardPaymentMethodBreakdown>[
      DashboardPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 144,
        totalAmount: 12450.20,
        averageTicket: 86.46,
        sharePercent: 44.7,
      ),
      DashboardPaymentMethodBreakdown(
        code: 'CRED',
        label: 'Cartao de credito',
        totalSalesCount: 92,
        totalAmount: 9650.30,
        averageTicket: 104.89,
        sharePercent: 34.6,
      ),
      DashboardPaymentMethodBreakdown(
        code: 'DEB',
        label: 'Cartao de debito',
        totalSalesCount: 51,
        totalAmount: 3710,
        averageTicket: 72.75,
        sharePercent: 13.3,
      ),
      DashboardPaymentMethodBreakdown(
        code: 'DIN',
        label: 'Dinheiro',
        totalSalesCount: 23,
        totalAmount: 2040.25,
        averageTicket: 88.70,
        sharePercent: 7.4,
      ),
    ],
    filialRankings: const <DashboardFilialRanking>[
      DashboardFilialRanking(
        codEmpresa: 1,
        codFilial: 3,
        totalSalesCount: 130,
        totalAmount: 11800.40,
      ),
      DashboardFilialRanking(
        codEmpresa: 1,
        codFilial: 8,
        totalSalesCount: 102,
        totalAmount: 9570.10,
      ),
      DashboardFilialRanking(
        codEmpresa: 1,
        codFilial: 14,
        totalSalesCount: 78,
        totalAmount: 6480.25,
      ),
    ],
    userRankings: const <DashboardUserRanking>[
      DashboardUserRanking(
        userName: 'Caixa 01',
        totalSalesCount: 84,
        totalAmount: 7750.10,
        averageTicket: 92.26,
      ),
      DashboardUserRanking(
        userName: 'Caixa 02',
        totalSalesCount: 73,
        totalAmount: 6540.60,
        averageTicket: 89.60,
      ),
      DashboardUserRanking(
        userName: 'Caixa 03',
        totalSalesCount: 58,
        totalAmount: 5210.25,
        averageTicket: 89.83,
      ),
    ],
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
          final theme = Theme.of(context);
          final tokens = theme.extension<AppThemeTokens>()!;
          final session = authController.session;
          final overview = dashboardController.overview;
          final showSkeleton =
              dashboardController.isLoadingInitial && overview == null;
          final resolvedOverview = overview ?? _skeletonOverview;
          final hasContent = showSkeleton || overview != null;

          if (session != null && !userContext.isLoadingInitial) {
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

          final periodLabel = hasContent
              ? '${AppBrFormatters.shortDate(resolvedOverview.periodStart)}'
                    ' – '
                    '${AppBrFormatters.shortDate(resolvedOverview.periodEnd)}'
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
                  subtitle: 'Resumo consolidado de todas as filiais.',
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
                if (hasContent) ...<Widget>[
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    loadingSemanticsLabel:
                        'Carregando indicadores de pagamento...',
                    child: _KpiBar(kpis: resolvedOverview.kpis),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    showDelay: Duration.zero,
                    loadingSemanticsLabel:
                        'Carregando mix de formas de pagamento...',
                    child: _PaymentMixCard(
                      methods: resolvedOverview.paymentMethods,
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    showDelay: const Duration(milliseconds: 80),
                    loadingSemanticsLabel:
                        'Carregando faturamento por forma de pagamento...',
                    child: _PaymentBarChart(
                      methods: resolvedOverview.paymentMethods,
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    showDelay: const Duration(milliseconds: 120),
                    loadingSemanticsLabel: 'Carregando rankings...',
                    child: _RankingsSection(
                      filialRankings: resolvedOverview.filialRankings,
                      userRankings: resolvedOverview.userRankings,
                    ),
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppSkeleton(
                    enabled: showSkeleton,
                    showDelay: const Duration(milliseconds: 160),
                    loadingSemanticsLabel:
                        'Carregando tabela de formas de pagamento...',
                    child: _PaymentSummaryTable(
                      methods: resolvedOverview.paymentMethods,
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
