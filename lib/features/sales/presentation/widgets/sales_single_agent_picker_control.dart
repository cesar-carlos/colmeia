import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/bottom_sheet_compact_drag_handle.dart';
import 'package:flutter/material.dart';

/// Figma-style agent filter trigger: circular peach background + dark icon.
const double _kAgentFilterCircleSize = 44;
const Color _kAgentFilterCircleFill = Color(0xFFFFE5D9);
const Color _kAgentFilterCircleIcon = Color(0xFF5D4037);

OverviewAgentOption? _salesFindAgent(
  List<OverviewAgentOption> agents,
  String? id,
) {
  if (id == null) {
    return null;
  }
  for (final a in agents) {
    if (a.agentId == id) {
      return a;
    }
  }
  return null;
}

/// Sales hub: choose exactly one approved agent — same visuals as Overview home
/// agent sheet but single-select instead of multi.
class SalesSingleAgentPickerControl extends StatelessWidget {
  const SalesSingleAgentPickerControl({
    required this.l10n,
    required this.availableAgents,
    required this.selectedAgentId,
    required this.onSelectionChanged,
    super.key,
    this.enabled = true,
    this.showTrailingFilterButton = true,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;
  final String? selectedAgentId;
  final ValueChanged<String> onSelectionChanged;
  final bool enabled;
  final bool showTrailingFilterButton;

  Future<void> _openSheet(BuildContext context) async {
    if (!enabled || availableAgents.isEmpty) {
      return;
    }

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (ctx) => _SalesAgentSelectionSheet(
        l10n: l10n,
        availableAgents: availableAgents,
        initialSelectedId: selectedAgentId,
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }
    onSelectionChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final labelToFieldGap = tokens.gapXs;

    if (availableAgents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.dashboardHomeFiltersAgentsLabel.toUpperCase(),
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: labelToFieldGap),
          Text(
            l10n.dashboardHomeFiltersAgentsEmptyHint,
            style: typography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final selectedAgent = _salesFindAgent(availableAgents, selectedAgentId);
    final hasSelection = selectedAgent != null;

    void openSheet() => _openSheet(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.dashboardHomeFiltersAgentsLabel.toUpperCase(),
          style: typography.utilityOverline.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: labelToFieldGap),
        Semantics(
          button: true,
          label: hasSelection
              ? '${l10n.dashboardHomeFiltersAgentsLabel}: ${selectedAgent.name}'
              : l10n.salesAgentPickerEmpty,
          child: InkWell(
            onTap: enabled ? openSheet : null,
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: tokens.gapXs,
              ),
              child: Text(
                hasSelection ? selectedAgent.name : l10n.salesAgentPickerEmpty,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: typography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasSelection
                      ? scheme.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!showTrailingFilterButton) {
      return AppSectionCard(child: content);
    }

    return AppSectionCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: _kAgentFilterCircleSize + tokens.gapSm,
            ),
            child: content,
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Semantics(
              button: true,
              label: l10n.overviewAgentFilterEditAction,
              child: Material(
                color: _kAgentFilterCircleFill,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? openSheet : null,
                  child: SizedBox(
                    width: _kAgentFilterCircleSize,
                    height: _kAgentFilterCircleSize,
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 22,
                      color: enabled
                          ? _kAgentFilterCircleIcon
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesAgentSelectionSheet extends StatefulWidget {
  const _SalesAgentSelectionSheet({
    required this.l10n,
    required this.availableAgents,
    required this.initialSelectedId,
  });

  final AppLocalizations l10n;
  final List<OverviewAgentOption> availableAgents;
  final String? initialSelectedId;

  @override
  State<_SalesAgentSelectionSheet> createState() =>
      _SalesAgentSelectionSheetState();
}

class _SalesAgentSelectionSheetState extends State<_SalesAgentSelectionSheet> {
  static const Duration _searchDebounceDelay = Duration(milliseconds: 120);

  String? _selectedAgentId;
  late final TextEditingController _searchController;
  Timer? _searchDebounceTimer;
  Map<String, OverviewAgentOption> _agentById = <String, OverviewAgentOption>{};
  late String _appliedFilterQuery;

  List<OverviewAgentOption>? _memoFilteredAgents;
  Object? _memoAgentsListIdentity;
  String? _memoFilterQuery;

  @override
  void initState() {
    super.initState();
    _rebuildAgentByIdMap();
    _appliedFilterQuery = '';
    _selectedAgentId = reconcileSelectedSalesAgentId(
      agents: widget.availableAgents,
      previousSelectedId: widget.initialSelectedId,
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SalesAgentSelectionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.availableAgents, widget.availableAgents)) {
      return;
    }
    _rebuildAgentByIdMap();
    _invalidateFilteredCache();
    final nextId = reconcileSelectedSalesAgentId(
      agents: widget.availableAgents,
      previousSelectedId: _selectedAgentId,
    );
    if (nextId == _selectedAgentId) {
      return;
    }
    setState(() {
      _selectedAgentId = nextId;
    });
  }

  void _rebuildAgentByIdMap() {
    _agentById = <String, OverviewAgentOption>{
      for (final a in widget.availableAgents) a.agentId: a,
    };
  }

  void _invalidateFilteredCache() {
    _memoFilteredAgents = null;
    _memoAgentsListIdentity = null;
    _memoFilterQuery = null;
  }

  void _scheduleSearchFilterRebuild() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      if (!mounted) {
        return;
      }
      final next = _searchController.text.trim().toLowerCase();
      if (!mounted || next == _appliedFilterQuery) {
        return;
      }
      setState(() {
        _appliedFilterQuery = next;
      });
    });
  }

  List<OverviewAgentOption> _getFilteredAgents() {
    final agents = widget.availableAgents;
    final q = _appliedFilterQuery;
    if (identical(_memoAgentsListIdentity, agents) &&
        _memoFilterQuery == q &&
        _memoFilteredAgents != null) {
      return _memoFilteredAgents!;
    }
    final result = q.isEmpty
        ? agents
        : agents
              .where((a) => a.name.toLowerCase().contains(q))
              .toList(growable: false);
    _memoAgentsListIdentity = agents;
    _memoFilterQuery = q;
    _memoFilteredAgents = result;
    return result;
  }

  void _toggleAgent(String agentId, bool? checked) {
    if (checked ?? false) {
      setState(() => _selectedAgentId = agentId);
    } else {
      setState(() => _selectedAgentId = null);
    }
  }

  void _apply() {
    Navigator.of(context).pop(_selectedAgentId);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final filtered = _getFilteredAgents();

    final selectedAgentMissingToken =
        _selectedAgentId != null &&
        (_agentById[_selectedAgentId]?.missingLocalClientToken ?? false);

    final minChromePx = 232.0 + (selectedAgentMissingToken ? 88.0 : 0.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: draggableSheetMinChildFractionForChrome(
          viewportHeight: viewportHeight,
          minChromePixels: minChromePx,
        ),
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(560, MediaQuery.sizeOf(context).width),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BottomSheetCompactDragHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.contentSpacing,
                      0,
                      tokens.contentSpacing,
                      tokens.gapSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.l10n.overviewAgentFilterSheetTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _cancel,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.contentSpacing,
                      vertical: tokens.gapSm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            widget.l10n.overviewAgentFilterSheetSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                        ),
                      ),
                      onChanged: (_) => _scheduleSearchFilterRebuild(),
                    ),
                  ),
                  if (selectedAgentMissingToken)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.contentSpacing,
                        0,
                        tokens.contentSpacing,
                        tokens.gapSm,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            tokens.formFieldRadius,
                          ),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(tokens.gapSm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: scheme.primary,
                              ),
                              SizedBox(width: tokens.gapSm),
                              Expanded(
                                child: Text(
                                  widget
                                      .l10n
                                      .overviewAgentFilterMissingClientTokenBanner,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(
                                tokens.contentSpacing,
                              ),
                              child: Text(
                                widget.l10n.overviewAgentFilterNoSearchResults,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.contentSpacing,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final agent = filtered[index];
                              return _SalesAgentSheetCheckboxRow(
                                key: ValueKey(agent.agentId),
                                l10n: widget.l10n,
                                agent: agent,
                                scheme: scheme,
                                tokens: tokens,
                                theme: theme,
                                selected: _selectedAgentId == agent.agentId,
                                onChanged: (v) =>
                                    _toggleAgent(agent.agentId, v),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(tokens.contentSpacing),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancel,
                              child: Text(
                                widget.l10n.overviewAgentFilterCancel,
                              ),
                            ),
                          ),
                          SizedBox(width: tokens.gapMd),
                          Expanded(
                            child: FilledButton(
                              onPressed: _selectedAgentId != null
                                  ? _apply
                                  : null,
                              child: Text(widget.l10n.overviewAgentFilterApply),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SalesAgentSheetCheckboxRow extends StatelessWidget {
  const _SalesAgentSheetCheckboxRow({
    required this.l10n,
    required this.agent,
    required this.scheme,
    required this.tokens,
    required this.theme,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final OverviewAgentOption agent;
  final ColorScheme scheme;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final nameColor = _salesAgentNameColor(
      agent.connectionStatus,
      scheme,
    );
    final isOffline = agent.connectionStatus == AgentConnectionStatus.offline;

    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (isOffline) ...<Widget>[
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: scheme.error,
          ),
          SizedBox(width: tokens.gapXs),
        ],
        if (agent.missingLocalClientToken) ...<Widget>[
          Icon(
            Icons.vpn_key_off_outlined,
            size: 18,
            color: scheme.tertiary,
          ),
          SizedBox(width: tokens.gapXs),
        ],
        Expanded(
          child: Text(
            agent.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: nameColor),
          ),
        ),
      ],
    );

    final tooltipLines = <String>[
      if (isOffline) l10n.agentConnectionOffline,
      if (agent.missingLocalClientToken)
        l10n.overviewAgentFilterMissingClientTokenRowSubtitle,
    ];
    final titleWidget = tooltipLines.isEmpty
        ? title
        : Tooltip(
            message: tooltipLines.join('\n'),
            child: title,
          );

    return CheckboxListTile(
      title: titleWidget,
      subtitle: agent.missingLocalClientToken
          ? Text(
              l10n.overviewAgentFilterMissingClientTokenRowSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      dense: true,
      value: selected,
      onChanged: onChanged,
    );
  }
}

Color _salesAgentNameColor(
  AgentConnectionStatus status,
  ColorScheme scheme,
) {
  return switch (status) {
    AgentConnectionStatus.offline => scheme.error,
    AgentConnectionStatus.online ||
    AgentConnectionStatus.unknown => scheme.onSurface,
  };
}
