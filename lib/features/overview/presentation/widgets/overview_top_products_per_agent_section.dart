import 'dart:async';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row_number_ordering.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Home dashboard block: top N products **per agent**, one tab per agent (no
/// cross-agent merge). Uses [LoadResumoProdutoVendaPageUseCase] with
/// [ResumoProdutoVendaRowNumberOrdering.metricGlobal].
class OverviewTopProductsPerAgentSection extends StatefulWidget {
  const OverviewTopProductsPerAgentSection({
    required this.userId,
    required this.overview,
    required this.filter,
    required this.availableAgents,
    required this.l10n,
    super.key,
  });

  static const int topProductCount = 15;

  final String userId;
  final Overview overview;
  final OverviewFilter filter;
  final List<OverviewAgentOption> availableAgents;
  final AppLocalizations l10n;

  @override
  State<OverviewTopProductsPerAgentSection> createState() =>
      _OverviewTopProductsPerAgentSectionState();
}

class _OverviewTopProductsPerAgentSectionState
    extends State<OverviewTopProductsPerAgentSection> {
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  final Set<String> _inFlight = <String>{};
  int _tabIndex = 0;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scheduleLoadForActiveTab(_resolveTabs());
    });
  }

  @override
  void didUpdateWidget(covariant OverviewTopProductsPerAgentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.overview, widget.overview) ||
        oldWidget.filter != widget.filter) {
      _cache.clear();
      _inFlight.clear();
      _tabIndex = 0;
      _loadGeneration++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleLoadForActiveTab(_resolveTabs());
        }
      });
    }
  }

  int _periodSignature(Overview o) {
    int ymd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
    return Object.hash(ymd(o.periodStart), ymd(o.periodEnd));
  }

  List<_AgentTab> _resolveTabs() {
    final selected = widget.filter.selectedAgentIds;
    if (selected != null) {
      final sorted = List<String>.from(selected)..sort();
      return <_AgentTab>[
        for (final id in sorted)
          _AgentTab(
            id: id,
            label: _labelForAgentId(id),
          ),
      ];
    }
    final tabs = <_AgentTab>[];
    for (final a in widget.availableAgents) {
      if (!a.missingLocalClientToken) {
        tabs.add(_AgentTab(id: a.agentId, label: a.name));
      }
    }
    tabs.sort((a, b) => a.label.compareTo(b.label));
    return tabs;
  }

  String _labelForAgentId(String agentId) {
    for (final a in widget.availableAgents) {
      if (a.agentId == agentId) {
        return a.name;
      }
    }
    return agentId;
  }

  ResumoProdutoVendaFilter _buildFilter() {
    final o = widget.overview;
    final start = DateTime(
      o.periodStart.year,
      o.periodStart.month,
      o.periodStart.day,
    );
    final end = DateTime(o.periodEnd.year, o.periodEnd.month, o.periodEnd.day);
    return ResumoProdutoVendaFilter(
      dataVendaInicio: start,
      dataVendaFim: end,
      pageSize: OverviewTopProductsPerAgentSection.topProductCount,
      rowNumberOrdering: ResumoProdutoVendaRowNumberOrdering.metricGlobal,
    );
  }

  Future<void> _ensureLoaded(String agentId) async {
    final sig = _periodSignature(widget.overview);
    final existing = _cache[agentId];
    if (existing != null &&
        existing.periodSig == sig &&
        !existing.loading &&
        (existing.result != null || existing.errorMessage != null)) {
      return;
    }
    if (_inFlight.contains(agentId)) {
      return;
    }

    final generation = _loadGeneration;
    _inFlight.add(agentId);
    setState(() {
      _cache[agentId] = _CacheEntry(periodSig: sig, loading: true);
    });

    final filter = _buildFilter();
    final validation = filter.validationError();
    if (validation != null) {
      _inFlight.remove(agentId);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _cache[agentId] = _CacheEntry(
          periodSig: sig,
          errorMessage: widget.l10n.overviewTopProductsInvalidPeriod,
        );
      });
      return;
    }

    final useCase = context.read<LoadResumoProdutoVendaPageUseCase>();
    final result = await useCase.call(
      userId: widget.userId,
      agentId: agentId,
      filter: filter,
    );

    _inFlight.remove(agentId);
    if (!mounted || generation != _loadGeneration) {
      return;
    }

    result.fold(
      (page) {
        setState(() {
          _cache[agentId] = _CacheEntry(periodSig: sig, result: page);
        });
      },
      (failure) {
        setState(() {
          _cache[agentId] = _CacheEntry(
            periodSig: sig,
            errorMessage: failure.displayMessage,
          );
        });
      },
    );
  }

  void _scheduleLoadForActiveTab(List<_AgentTab> tabs) {
    if (tabs.isEmpty) {
      return;
    }
    final idx = _tabIndex.clamp(0, tabs.length - 1);
    final id = tabs[idx].id;
    unawaited(_ensureLoaded(id));
  }

  Widget _buildPanel(
    BuildContext context,
    String agentId,
    AppThemeTokens tokens,
  ) {
    final l10n = widget.l10n;
    final entry = _cache[agentId];
    final sig = _periodSignature(widget.overview);

    if (entry == null || entry.periodSig != sig) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_ensureLoaded(agentId));
        }
      });
    }

    if (entry == null || entry.loading || entry.periodSig != sig) {
      return AppSkeleton(
        enabled: true,
        loadingSemanticsLabel: l10n.overviewTopProductsLoadingSemantics,
        child: SizedBox(
          height: AppComparisonBarChart.loadingBlockHeight(tokens),
        ),
      );
    }

    if (entry.errorMessage != null) {
      return AppInlineErrorPanel(
        title: l10n.overviewTopProductsLoadFailed,
        message: entry.errorMessage!,
        variant: AppInlineErrorPanelVariant.plain,
      );
    }

    final page = entry.result!;
    final items = page.items;
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
        child: Center(
          child: Text(
            l10n.overviewTopProductsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final localeName = l10n.localeName;
    final itemsFormat = NumberFormat('#,##0.##', localeName);
    final marginFormat = NumberFormat('#0.0', localeName);

    return AppComparisonBarChart<ResumoProdutoVendaRow>(
      items: items,
      plotFloorAccessibilityNotice: l10n.chartComparisonPlotFloorNotice,
      extremeSpreadAccessibilityNotice:
          l10n.chartComparisonExtremeValueSpreadNotice,
      labelBuilder: (r) => r.nomeProduto,
      valueBuilder: (r) => r.qtdVendas,
      tooltipLabelBuilder: (r, v) {
        final line = l10n.overviewTopProductsTooltipLine(
          r.qtdVendas,
          itemsFormat.format(r.qtdItensVendido),
          AppBrFormatters.smartCompactCurrencyForLocale(
            r.valorTotalItem,
            localeName,
          ),
          AppBrFormatters.smartCompactCurrencyForLocale(
            r.custoReposicao,
            localeName,
          ),
          marginFormat.format(r.percentualLucro),
        );
        return '${r.nomeProduto}\n$line';
      },
      dataLabelBuilder: (r, v) =>
          NumberFormat.compact(locale: localeName).format(v),
      style: overviewHomeComparisonBarChartStyle(
        tokens: tokens,
        kind: OverviewHomeBarChartKind.ranking,
        l10n: l10n,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final tabs = _resolveTabs();

    if (tabs.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: tokens.sectionSpacing),
        child: Text(
          widget.l10n.overviewTopProductsNoEligibleAgents,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    _tabIndex = _tabIndex.clamp(0, tabs.length - 1);

    final theme = Theme.of(context);
    final typography = theme.appTypography;

    return Padding(
      padding: EdgeInsets.only(top: tokens.sectionSpacing),
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.l10n.overviewTopProductsTitle,
              style: typography.sectionHeaderH2,
            ),
            SizedBox(height: tokens.gapXs),
            Text(
              widget.l10n.overviewTopProductsSubtitle(
                OverviewTopProductsPerAgentSection.topProductCount,
              ),
              style: typography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.gapMd),
            AppTabView(
              initialIndex: _tabIndex,
              onChanged: (i) {
                setState(() => _tabIndex = i);
                _scheduleLoadForActiveTab(tabs);
              },
              items: <AppTabViewItem>[
                for (final t in tabs)
                  AppTabViewItem(
                    label: t.label,
                    semanticLabel: t.label,
                    child: _buildPanel(context, t.id, tokens),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _AgentTab {
  const _AgentTab({required this.id, required this.label});
  final String id;
  final String label;
}

@immutable
class _CacheEntry {
  const _CacheEntry({
    required this.periodSig,
    this.loading = false,
    this.result,
    this.errorMessage,
  });

  final int periodSig;
  final bool loading;
  final ResumoProdutoVendaPageResult? result;
  final String? errorMessage;
}
