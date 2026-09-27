import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_notas_entrada_controller.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_notas_entrada_itens_controller.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_itens_search.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_itens_table.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_search_field.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_data_grid_density.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesNotasEntradaItensPage extends StatefulWidget {
  const SalesNotasEntradaItensPage({super.key});

  @override
  State<SalesNotasEntradaItensPage> createState() =>
      _SalesNotasEntradaItensPageState();
}

class _SalesNotasEntradaItensPageState extends State<SalesNotasEntradaItensPage>
    with AgentQueryRetryAfterHost<SalesNotasEntradaItensPage> {
  late SalesNotasEntradaItensController _controller;
  var _isListeningToController = false;
  String? _boundUserId;
  bool _hasBoundUser = false;
  AppFailure? _lastArmedFailure;
  String _itemSearch = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<SalesNotasEntradaItensController>();
    if (!_isListeningToController) {
      _controller = controller;
      _controller.addListener(_onControllerTick);
      _isListeningToController = true;
    } else if (!identical(_controller, controller)) {
      _controller.removeListener(_onControllerTick);
      _controller = controller;
      _controller.addListener(_onControllerTick);
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
    super.dispose();
  }

  void _onControllerTick() {
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

  void _goBackToNotes() {
    context.goTo(
      AppRoute.salesCard,
      pathParameters: const <String, String>{
        'cardId': SalesNotasEntradaController.cardId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final controller = context.watch<SalesNotasEntradaItensController>();
    final note = controller.note;
    final documento = note?.numeroDocumento.trim();
    final title = documento != null && documento.isNotEmpty
        ? l10n.salesNotasEntradaItensTitle(documento)
        : l10n.salesNotasEntradaItensTitleById('${controller.compraId}');
    final subtitle = note == null
        ? l10n.salesNotasEntradaItensSubtitleFallback('${controller.compraId}')
        : l10n.salesNotasEntradaItensSubtitle(
            note.nomeFornecedor,
            _formatDate(note.dataEmissao),
            _formatDate(note.dataEntrada),
          );

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
            sectionLabel: l10n.salesCardNotasEntradaTitle,
            onSectionLabelTap: _goBackToNotes,
            title: title,
            subtitle: subtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          _ItensReportSurface(
            controller: controller,
            l10n: l10n,
            searchTerm: _itemSearch,
            onSearchChanged: (term) => setState(() => _itemSearch = term),
            retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return AppBrFormatters.shortDate(value.toLocal());
  }
}

class _ItensReportSurface extends StatelessWidget {
  const _ItensReportSurface({
    required this.controller,
    required this.l10n,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.retryCountdownLabel,
  });

  final SalesNotasEntradaItensController controller;
  final AppLocalizations l10n;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final String? retryCountdownLabel;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasValidCompraId) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        title: l10n.salesCardNotasEntradaTitle,
        message: l10n.salesNotasEntradaItensInvalidCompra,
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
    final notices = <Widget>[];
    if (controller.isCancelled) {
      notices.add(
        AppInlineErrorPanel(
          variant: AppInlineErrorPanelVariant.plain,
          tone: AppInlinePanelTone.informational,
          message: l10n.salesNotasEntradaItensCancelledBanner,
        ),
      );
    }
    final truncationLimit = controller.truncationLimit;
    if (truncationLimit != null) {
      notices.add(
        AppInlineErrorPanel(
          variant: AppInlineErrorPanelVariant.plain,
          tone: AppInlinePanelTone.informational,
          message: l10n.salesNotasEntradaItensTruncated(truncationLimit),
        ),
      );
    }

    final headerTotal = controller.note?.valorTotalCompra;
    final totalsMismatch =
        controller.totalsDifferFromNote && headerTotal != null
        ? AppInlineErrorPanel(
            variant: AppInlineErrorPanelVariant.plain,
            tone: AppInlinePanelTone.informational,
            message: l10n.salesNotasEntradaItensTotalMismatch(
              AppBrFormatters.currency(controller.totalValorItens),
              AppBrFormatters.currency(headerTotal),
            ),
          )
        : null;

    final tokens = context.appTokens;
    final theme = Theme.of(context);
    final loadErrorPanel = controller.loadFailure == null
        ? null
        : AgentQueryErrorPanelFactory.fromFailure(
            controller.loadFailure!,
            l10n,
            onRetry: () => unawaited(controller.reload()),
            retryCountdownLabel: retryCountdownLabel,
            supportContext: AgentQueryFailureSupportContext.environment(
              extra: <String, String>{
                'agentId': selectedAgentId,
                'screen': 'sales_notas_entrada_itens',
                'compraId': '${controller.compraId}',
              },
            ),
          );

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (loadErrorPanel != null) ...<Widget>[
            loadErrorPanel,
            SizedBox(height: tokens.sectionSpacing),
          ],
          for (final notice in notices) ...<Widget>[
            notice,
            SizedBox(height: tokens.gapSm),
          ],
          if (controller.isLoading && controller.rows.isEmpty)
            AppSkeleton(
              enabled: true,
              loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
              child: appDataGridSkeletonColumn(
                tokens: tokens,
                dividerColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.35,
                ),
              ),
            )
          else if (!controller.isLoading &&
              controller.rows.isEmpty &&
              loadErrorPanel == null)
            AppInlineErrorPanel(
              variant: AppInlineErrorPanelVariant.plain,
              tone: AppInlinePanelTone.informational,
              message: l10n.salesNotasEntradaItensEmpty,
            )
          else if (controller.rows.isNotEmpty) ...<Widget>[
            SalesNotasEntradaSearchField(
              searchTerm: searchTerm,
              hintText: l10n.salesNotasEntradaItensSearchHint,
              enabled: !controller.isLoading,
              onSearchChanged: onSearchChanged,
            ),
            SizedBox(height: tokens.contentSpacing),
            AppSkeleton(
              enabled: controller.isLoading,
              loadingSemanticsLabel: l10n.reportLoadingTableSemantics,
              child: _filteredItems(l10n),
            ),
            SizedBox(height: tokens.gapSm),
            if (totalsMismatch != null) ...<Widget>[
              totalsMismatch,
              SizedBox(height: tokens.gapSm),
            ],
            _ItensSummary(
              l10n: l10n,
              itemCount: controller.rows.length,
              shownCount: SalesNotasEntradaItensSearch.filter(
                controller.rows,
                searchTerm,
              ).length,
              searching: searchTerm.trim().isNotEmpty,
              totalValorItens: controller.totalValorItens,
              noteTotal: controller.note?.valorTotalCompra,
            ),
          ],
        ],
      ),
    );
  }

  Widget _filteredItems(AppLocalizations l10n) {
    final filtered = SalesNotasEntradaItensSearch.filter(
      controller.rows,
      searchTerm,
    );
    if (filtered.isEmpty) {
      return AppInlineErrorPanel(
        variant: AppInlineErrorPanelVariant.plain,
        tone: AppInlinePanelTone.informational,
        message: l10n.salesNotasEntradaItensEmptySearch,
      );
    }
    return SalesNotasEntradaItensGrid(
      l10n: l10n,
      rows: filtered,
    );
  }
}

class _ItensSummary extends StatelessWidget {
  const _ItensSummary({
    required this.l10n,
    required this.itemCount,
    required this.shownCount,
    required this.searching,
    required this.totalValorItens,
    required this.noteTotal,
  });

  final AppLocalizations l10n;
  final int itemCount;
  final int shownCount;
  final bool searching;
  final double totalValorItens;
  final double? noteTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final countLabel = searching
        ? l10n.salesNotasEntradaItensCountFiltered(shownCount, itemCount)
        : l10n.salesNotasEntradaItensCount(itemCount);
    final itemsAmount = AppBrFormatters.currency(totalValorItens);
    final headerAmount = noteTotal == null
        ? null
        : AppBrFormatters.currency(noteTotal!);

    return Semantics(
      label: l10n.salesNotasEntradaItensTotalsSemantics,
      value: itemsAmount,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.gapMd,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          Text(countLabel, style: theme.textTheme.titleSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _SummaryAmount(
                label: l10n.salesNotasEntradaItensTotalsAmountLabel,
                amount: itemsAmount,
                emphasize: true,
              ),
              if (headerAmount != null) ...<Widget>[
                SizedBox(height: tokens.gapXs),
                _SummaryAmount(
                  label: l10n.salesNotasEntradaItensNoteTotalLabel,
                  amount: headerAmount,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  const _SummaryAmount({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final String amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final amountStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: tabularFigures,
    );

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: '$label: ', style: labelStyle),
          TextSpan(text: amount, style: amountStyle),
        ],
      ),
      textAlign: TextAlign.end,
    );
  }
}
