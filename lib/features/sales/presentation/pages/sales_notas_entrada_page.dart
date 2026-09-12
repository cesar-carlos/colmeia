import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_notas_entrada_controller.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_view.dart';
import 'package:colmeia/features/sales/presentation/share/sales_notas_entrada_share.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_fullscreen.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_pagination_footer.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_report_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesNotasEntradaPage extends StatefulWidget {
  const SalesNotasEntradaPage({super.key});

  @override
  State<SalesNotasEntradaPage> createState() => _SalesNotasEntradaPageState();
}

class _SalesNotasEntradaPageState extends State<SalesNotasEntradaPage>
    with AgentQueryRetryAfterHost<SalesNotasEntradaPage> {
  late SalesNotasEntradaController _controller;
  var _isListeningToController = false;
  String? _boundUserId;
  bool _hasBoundUser = false;
  AppFailure? _lastArmedFailure;
  final GlobalKey _shareKey = GlobalKey();
  final ValueNotifier<SalesNotasEntradaGridSnapshot> _gridView =
      ValueNotifier<SalesNotasEntradaGridSnapshot>(
        SalesNotasEntradaGridSnapshot.initial(),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<SalesNotasEntradaController>();
    if (!_isListeningToController) {
      _controller = controller;
      _controller.addListener(_onControllerTick);
      _isListeningToController = true;
      _publishGridView();
    } else if (!identical(_controller, controller)) {
      _controller.removeListener(_onControllerTick);
      _controller = controller;
      _controller.addListener(_onControllerTick);
      _publishGridView();
    }

    final userId = context.watch<AuthController>().session?.userId;
    if (_hasBoundUser && _boundUserId == userId) {
      return;
    }
    _hasBoundUser = true;
    _boundUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _boundUserId != userId) {
        return;
      }
      unawaited(_controller.bindUser(userId));
    });
  }

  @override
  void dispose() {
    if (_isListeningToController) {
      _controller.removeListener(_onControllerTick);
    }
    _gridView.dispose();
    super.dispose();
  }

  void _onControllerTick() {
    _publishGridView();
    final failure = _controller.loadFailure;
    if (failure == null) {
      _lastArmedFailure = null;
      return;
    }
    if (identical(failure, _lastArmedFailure)) {
      return;
    }
    _lastArmedFailure = failure;
    onAgentQueryLoadFailure(failure);
  }

  void _publishGridView() {
    if (!mounted) {
      return;
    }
    final controller = _controller;
    _gridView.value = SalesNotasEntradaGridSnapshot(
      view: controller.view,
      notesRows: controller.rows,
      summaryRows: controller.summaryRows,
      page: controller.page,
      pageSize: controller.pageSize,
      totalCount: controller.totalCount,
      totalValorCompra: controller.totalValorCompra,
      rangeStart: controller.rangeStart,
      rangeEnd: controller.rangeEnd,
      totalPages: controller.totalPages,
      searchTerm: controller.searchTerm,
      supplierScopeName: controller.supplierScopeName,
      isLoading: controller.isLoading,
      loadFailure: controller.loadFailure,
      selectedAgentId: controller.selectedAgentId,
    );
  }

  Future<void> _openFiltersSheet() async {
    final controller = _controller;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => SalesNotasEntradaFiltersSheet(
        l10n: AppLocalizations.of(context),
        availableAgents: controller.availableAgents,
        initialSelectedAgentId: controller.selectedAgentId,
        initialDataLancamentoInicio: controller.dataLancamentoInicio,
        initialDataLancamentoFim: controller.dataLancamentoFim,
        onApply:
            ({
              required selectedAgentId,
              required dataLancamentoInicio,
              required dataLancamentoFim,
            }) {
              unawaited(
                controller.applyFilters(
                  selectedAgentId: selectedAgentId,
                  dataLancamentoInicio: dataLancamentoInicio,
                  dataLancamentoFim: dataLancamentoFim,
                ),
              );
            },
      ),
    );
  }

  void _showShareMessage(String message) {
    if (!mounted || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _shareCatalog() async {
    final controller = _controller;
    if (!controller.canShare) {
      return;
    }
    if (!ChartShareGuard.tryAcquire(_shareKey)) {
      return;
    }

    var transferredToCapture = false;
    try {
      final l10n = AppLocalizations.of(context);
      final totalCount = controller.totalCount;
      final totalValorCompra = controller.totalValorCompra;
      final exportHeaderContext =
          buildSalesNotasEntradaShareExportHeaderContext(
            l10n: l10n,
            agentName:
                controller.selectedAgent?.name ?? l10n.salesBranchPickerEmpty,
            dataLancamentoInicio: controller.dataLancamentoInicio,
            dataLancamentoFim: controller.dataLancamentoFim,
            searchTerm: controller.searchTerm,
          );

      switch (controller.view) {
        case SalesNotasEntradaView.notes:
          final result = await controller.loadRowsForShare();
          if (!mounted) {
            return;
          }
          await result.fold(
            (rows) async {
              ChartShareGuard.release(_shareKey);
              transferredToCapture = true;
              await shareChartCapture(
                context,
                buildSalesNotasEntradaShareMetadata(
                  l10n: l10n,
                  rows: rows,
                  totalValorCompra: totalValorCompra,
                  exportHeaderContext: exportHeaderContext,
                ).toShareRequest(_shareKey),
              );
            },
            (failure) async => _showShareFailure(failure, l10n, totalCount),
          );
        case SalesNotasEntradaView.bySupplier:
          final result = await controller.loadSummaryRowsForShare();
          if (!mounted) {
            return;
          }
          await result.fold(
            (rows) async {
              ChartShareGuard.release(_shareKey);
              transferredToCapture = true;
              await shareChartCapture(
                context,
                buildSalesNotasEntradaResumoShareMetadata(
                  l10n: l10n,
                  rows: rows,
                  totalValorCompra: totalValorCompra,
                  exportHeaderContext: exportHeaderContext,
                ).toShareRequest(_shareKey),
              );
            },
            (failure) async => _showShareFailure(failure, l10n, totalCount),
          );
      }
    } finally {
      if (!transferredToCapture) {
        ChartShareGuard.release(_shareKey);
      }
    }
  }

  void _showShareFailure(
    AppFailure failure,
    AppLocalizations l10n,
    int totalCount,
  ) {
    if (shouldSuppressAgentQueryFailureUi(failure)) {
      return;
    }
    final message =
        failure is ValidationFailure &&
            failure.message == 'share_export_row_limit_exceeded'
        ? l10n.chartShareExportRowLimitExceeded(
            ChartSharePdfLimits.maxTableRows,
            totalCount,
          )
        : failure is ValidationFailure &&
              failure.message == 'share_export_incomplete_catalog'
        ? l10n.chartShareExportIncompleteCatalog
        : failure is SessionFailure
        ? l10n.agentSqlErrorAuthenticationFailed
        : agentQueryFailureUserMessage(failure, l10n);
    _showShareMessage(message);
  }

  void _openFullscreen() {
    if (!_controller.canOpenFullscreen) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final rangeLabel =
        '${AppBrFormatters.shortDate(_controller.dataLancamentoInicio)} – '
        '${AppBrFormatters.shortDate(_controller.dataLancamentoFim)}';
    final selectedAgentName =
        _controller.selectedAgent?.name ?? l10n.salesBranchPickerEmpty;
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: l10n.salesCardNotasEntradaTitle,
          subtitle: l10n.salesNotasEntradaIntroSubtitle,
          filterSummary: '$selectedAgentName · $rangeLabel',
          chartSemanticsLabel: l10n.salesCardNotasEntradaTitle,
          headerTrailing: ValueListenableBuilder<SalesNotasEntradaGridSnapshot>(
            valueListenable: _gridView,
            builder: (context, snapshot, _) {
              final canShare = !snapshot.isLoading && snapshot.totalCount > 0;
              return AppChartHeaderTrailing(
                onShare: canShare ? () => unawaited(_shareCatalog()) : null,
                shareProgressKey: _shareKey,
                shareEnabled: !snapshot.isLoading,
              );
            },
          ),
          chartBuilder: (fullscreenContext) {
            return ValueListenableBuilder<SalesNotasEntradaGridSnapshot>(
              valueListenable: _gridView,
              builder: (context, snapshot, _) {
                return SalesNotasEntradaFullscreen(
                  snapshot: snapshot,
                  onSearchChanged: (term) =>
                      unawaited(_controller.applySearch(term)),
                  onViewChanged: (view) =>
                      unawaited(_controller.selectView(view)),
                  onPageSelected: (page) =>
                      unawaited(_controller.showPage(page)),
                  onPageSizeChanged: (pageSize) =>
                      unawaited(_controller.setPageSize(pageSize)),
                  onClearSupplierScope: () =>
                      unawaited(_controller.clearSupplierScope()),
                  onSupplierSelected: (row) =>
                      unawaited(_controller.openSupplierNotes(row)),
                  loadErrorPanel: snapshot.loadFailure == null
                      ? null
                      : AgentQueryErrorPanelFactory.fromFailure(
                          snapshot.loadFailure!,
                          AppLocalizations.of(fullscreenContext),
                          onRetry: () => unawaited(_controller.reload()),
                          retryCountdownLabel: agentQueryRetryCountdownLabel(
                            AppLocalizations.of(fullscreenContext),
                          ),
                          supportContext:
                              AgentQueryFailureSupportContext.environment(
                                extra: <String, String>{
                                  'agentId': ?snapshot.selectedAgentId,
                                  'screen': 'sales_notas_entrada',
                                },
                              ),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final controller = context.watch<SalesNotasEntradaController>();
    final selectedAgentName =
        controller.selectedAgent?.name ?? l10n.salesBranchPickerEmpty;
    final rangeLabel =
        '${AppBrFormatters.shortDate(controller.dataLancamentoInicio)} – '
        '${AppBrFormatters.shortDate(controller.dataLancamentoFim)}';

    return RefreshIndicator(
      onRefresh: () => _controller.reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.pageScrollPadding(
          tokens,
          horizontalAdjustment:
              AppPageSpacingPresets.dashboardHorizontalAdjustment,
        ),
        children: <Widget>[
          AppShellPageIntro(
            sectionLabel: l10n.shellNavSalesLabel,
            onSectionLabelTap: () => context.goTo(AppRoute.sales),
            title: l10n.salesCardNotasEntradaTitle,
            subtitle: l10n.salesNotasEntradaIntroSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesCardFilterTrigger(
            onTap: () => unawaited(_openFiltersSheet()),
            buttonSemanticsLabel: l10n.reportFiltersButton,
            summaryItems: <SalesCardFilterSummaryItem>[
              SalesCardFilterSummaryItem(
                label: l10n.salesBranchFilterLabel,
                value: selectedAgentName,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesNotasEntradaLaunchPeriodLabel,
                value: rangeLabel,
              ),
            ],
          ),
          SizedBox(height: tokens.sectionSpacing),
          _NotasEntradaReportSurface(
            controller: controller,
            l10n: l10n,
            boundUserId: _boundUserId,
            retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
            headerTrailing: AppChartHeaderTrailing(
              onOpenFullscreen: controller.canOpenFullscreen
                  ? _openFullscreen
                  : null,
              openFullscreenTooltip: l10n.salesNotasEntradaFullscreenTooltip,
              onShare: controller.canShare
                  ? () => unawaited(_shareCatalog())
                  : null,
              shareProgressKey: _shareKey,
              shareEnabled: !controller.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotasEntradaReportSurface extends StatelessWidget {
  const _NotasEntradaReportSurface({
    required this.controller,
    required this.l10n,
    required this.boundUserId,
    required this.retryCountdownLabel,
    required this.headerTrailing,
  });

  final SalesNotasEntradaController controller;
  final AppLocalizations l10n;
  final String? boundUserId;
  final String? retryCountdownLabel;
  final Widget headerTrailing;

  @override
  Widget build(BuildContext context) {
    if (controller.loadFailure != null && controller.selectedAgentId == null) {
      return AgentQueryErrorPanelFactory.fromFailure(
        controller.loadFailure!,
        l10n,
        onRetry: () => unawaited(controller.bindUser(boundUserId)),
        retryCountdownLabel: retryCountdownLabel,
        supportContext: AgentQueryFailureSupportContext.environment(
          extra: const <String, String>{'screen': 'sales_notas_entrada'},
        ),
      );
    }
    if (controller.selectedAgentId == null) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        title: l10n.salesBranchRequiredTitle,
        message: l10n.salesBranchRequiredMessage,
      );
    }
    if (controller.missingClientToken) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        title: l10n.dashboardMissingClientTokenTitle,
        message: l10n.salesBranchFilterMissingClientTokenBanner,
      );
    }

    final selectedAgentId = controller.selectedAgentId!;
    return SalesNotasEntradaReportCard(
      l10n: l10n,
      view: controller.view,
      notesRows: controller.rows,
      summaryRows: controller.summaryRows,
      totalValorCompra: controller.totalValorCompra,
      isLoading: controller.isLoading,
      searchTerm: controller.searchTerm,
      supplierScopeName: controller.supplierScopeName,
      onSearchChanged: (term) => unawaited(controller.applySearch(term)),
      onViewChanged: (view) => unawaited(controller.selectView(view)),
      onClearSupplierScope: () => unawaited(controller.clearSupplierScope()),
      onSupplierSelected: (row) => unawaited(controller.openSupplierNotes(row)),
      headerTrailing: headerTrailing,
      loadErrorPanel: controller.loadFailure == null
          ? null
          : AgentQueryErrorPanelFactory.fromFailure(
              controller.loadFailure!,
              l10n,
              onRetry: () => unawaited(controller.reload()),
              retryCountdownLabel: retryCountdownLabel,
              supportContext: AgentQueryFailureSupportContext.environment(
                extra: <String, String>{
                  'agentId': selectedAgentId,
                  'screen': 'sales_notas_entrada',
                },
              ),
            ),
      paginationFooter: SalesNotasEntradaPaginationFooter(
        currentPage: controller.page,
        totalPages: controller.totalPages,
        pageSize: controller.pageSize,
        rangeStart: controller.rangeStart,
        rangeEnd: controller.rangeEnd,
        totalItems: controller.totalCount,
        entityLabel: switch (controller.view) {
          SalesNotasEntradaView.notes => l10n.salesNotasEntradaEntityLabel,
          SalesNotasEntradaView.bySupplier =>
            l10n.salesNotasEntradaSummaryEntityLabel,
        },
        enabled: !controller.isLoading,
        onPageSelected: (page) => unawaited(controller.showPage(page)),
        onPageSizeChanged: (pageSize) =>
            unawaited(controller.setPageSize(pageSize)),
      ),
    );
  }
}
