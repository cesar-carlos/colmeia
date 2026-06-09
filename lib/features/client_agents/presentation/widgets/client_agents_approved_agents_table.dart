import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_shared_widgets.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const List<int> kClientAgentsApprovedTablePageSizeOptions = <int>[
  10,
  20,
  50,
  100,
];

abstract final class ClientAgentsApprovedAgentsTableLayout {
  static double _name(AppThemeTokens t) => math.max(160, t.gapMd * 14);
  static double _tradeName(AppThemeTokens t) => math.max(140, t.gapMd * 12);
  static double _catalog(AppThemeTokens t) => math.max(96, t.gapMd * 8);
  static double _connection(AppThemeTokens t) => math.max(120, t.gapMd * 10);
  static double _actions(AppThemeTokens t) => math.max(148, t.gapMd * 12);
  static double _select(AppThemeTokens t) => math.max(40, t.gapMd * 4);

  static double minWidth({
    required AppThemeTokens tokens,
    required bool showSelectionColumn,
  }) {
    var width = _name(tokens) +
        _tradeName(tokens) +
        _catalog(tokens) +
        _connection(tokens) +
        _actions(tokens);
    if (showSelectionColumn) {
      width += _select(tokens);
    }
    return width;
  }

  static double minScrollContentWidth({
    required AppThemeTokens tokens,
    required bool showSelectionColumn,
  }) =>
      minWidth(tokens: tokens, showSelectionColumn: showSelectionColumn) +
      2 * tokens.gapSm;
}

class ClientAgentsApprovedAgentsTable extends StatelessWidget {
  const ClientAgentsApprovedAgentsTable({
    required this.l10n,
    required this.agents,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.onPageSelected,
    required this.onPageSizeChanged,
    required this.selecting,
    required this.selectedAgentIds,
    required this.pendingRemoveAgentIds,
    required this.isMutating,
    required this.onAgentTap,
    required this.onAgentSelectionChanged,
    required this.onRemoveAccess,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ClientAgent> agents;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<int> onPageSizeChanged;
  final bool selecting;
  final Set<String> selectedAgentIds;
  final Set<String> pendingRemoveAgentIds;
  final bool isMutating;
  final ValueChanged<ClientAgent> onAgentTap;
  final void Function(ClientAgent agent, {required bool selected})
  onAgentSelectionChanged;
  final ValueChanged<ClientAgent> onRemoveAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final rowNumber = NumberFormat.decimalPattern(l10n.localeName);
    final totalPages = totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
    final rangeStart = totalCount == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final rangeEnd = totalCount == 0
        ? 0
        : math.min(currentPage * pageSize, totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (agents.isNotEmpty) ...<Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final minTable =
                  ClientAgentsApprovedAgentsTableLayout.minScrollContentWidth(
                    tokens: tokens,
                    showSelectionColumn: selecting,
                  );
              final outer = constraints.maxWidth;
              final contentWidth = outer.isFinite && outer > 0
                  ? math.max(outer, minTable)
                  : minTable;
              return ChartHorizontalScrollShell(
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ClientAgentsApprovedAgentsTableHeader(
                          l10n: l10n,
                          showSelectionColumn: selecting,
                        ),
                        Divider(
                          height: tokens.gapMd * 2,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: agents.length,
                          separatorBuilder: (_, _) => Divider(
                            height: tokens.gapMd * 2,
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final agent = agents[index];
                            return ClientAgentsApprovedAgentsTableRow(
                              agent: agent,
                              l10n: l10n,
                              selecting: selecting,
                              selected: selectedAgentIds.contains(agent.agentId),
                              pendingRemove: pendingRemoveAgentIds.contains(
                                agent.agentId,
                              ),
                              isMutating: isMutating,
                              onTap: selecting
                                  ? () => onAgentSelectionChanged(
                                      agent,
                                      selected: !selectedAgentIds.contains(
                                        agent.agentId,
                                      ),
                                    )
                                  : () => onAgentTap(agent),
                              onSelectionChanged: (selected) =>
                                  onAgentSelectionChanged(
                                    agent,
                                    selected: selected,
                                  ),
                              onRemoveAccess: () => onRemoveAccess(agent),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                semanticsHint: l10n.clientAgentsApprovedTableHorizontalScroll,
              );
            },
          ),
          SizedBox(height: tokens.contentSpacing),
          AppTablePaginationFooter(
            currentPage: currentPage,
            totalPages: totalPages,
            pageSize: pageSize,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            totalItems: totalCount,
            entityLabel: l10n.clientAgentsApprovedPaginationEntityLabel,
            pageSizeOptions: kClientAgentsApprovedTablePageSizeOptions,
            itemsPerPageLabel: l10n.salesProdutoTendenciaFilterPageSize,
            onPageSizeChanged: onPageSizeChanged,
            onPrevious: currentPage > 1
                ? () => onPageSelected(currentPage - 1)
                : null,
            onNext: currentPage < totalPages
                ? () => onPageSelected(currentPage + 1)
                : null,
            onPageSelected: onPageSelected,
          ),
          if (totalCount > pageSize) ...<Widget>[
            SizedBox(height: tokens.gapSm),
            Text(
              l10n.salesProdutoTendenciaDetailsNotice(
                rowNumber.format(pageSize),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class ClientAgentsApprovedAgentsTableHeader extends StatelessWidget {
  const ClientAgentsApprovedAgentsTableHeader({
    required this.l10n,
    required this.showSelectionColumn,
    super.key,
  });

  final AppLocalizations l10n;
  final bool showSelectionColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showSelectionColumn)
            SizedBox(
              width: ClientAgentsApprovedAgentsTableLayout._select(tokens),
            ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._name(tokens),
            child: Text(l10n.clientAgentsApprovedColName, style: style),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._tradeName(tokens),
            child: Text(l10n.clientAgentsApprovedColTradeName, style: style),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._catalog(tokens),
            child: Text(l10n.clientAgentsFilterCatalogLabel, style: style),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._connection(tokens),
            child: Text(l10n.clientAgentsFilterConnectionLabel, style: style),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._actions(tokens),
            child: Text(l10n.clientAgentsApprovedColActions, style: style),
          ),
        ],
      ),
    );
  }
}

class ClientAgentsApprovedAgentsTableRow extends StatelessWidget {
  const ClientAgentsApprovedAgentsTableRow({
    required this.agent,
    required this.l10n,
    required this.selecting,
    required this.selected,
    required this.pendingRemove,
    required this.isMutating,
    required this.onTap,
    required this.onSelectionChanged,
    required this.onRemoveAccess,
    super.key,
  });

  final ClientAgent agent;
  final AppLocalizations l10n;
  final bool selecting;
  final bool selected;
  final bool pendingRemove;
  final bool isMutating;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onRemoveAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final catalogLabel = switch (agent.catalogStatus) {
      AgentCatalogStatus.inactive => l10n.agentCatalogInactive,
      AgentCatalogStatus.active => l10n.agentCatalogActive,
    };
    final connectionLabel = switch (agent.connectionStatus) {
      AgentConnectionStatus.online => l10n.agentConnectionOnline,
      AgentConnectionStatus.offline => l10n.agentConnectionOffline,
      AgentConnectionStatus.unknown => l10n.agentConnectionUnknown,
    };

    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (selecting)
            SizedBox(
              width: ClientAgentsApprovedAgentsTableLayout._select(tokens),
              child: Checkbox(
                value: selected,
                onChanged: isMutating
                    ? null
                    : (value) => onSelectionChanged(value ?? false),
              ),
            ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._name(tokens),
            child: Text(
              agent.name,
              softWrap: true,
              maxLines: 4,
            ),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._tradeName(tokens),
            child: Text(
              agent.tradeName ?? l10n.clientAgentsNoTradeName,
              softWrap: true,
              maxLines: 4,
            ),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._catalog(tokens),
            child: ClientAgentsStatusChip(
              label: catalogLabel,
              kind: agent.catalogStatus == AgentCatalogStatus.active
                  ? ClientAgentsStatusChipKind.success
                  : ClientAgentsStatusChipKind.neutral,
            ),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._connection(tokens),
            child: ClientAgentsStatusChip(
              label: connectionLabel,
              kind: switch (agent.connectionStatus) {
                AgentConnectionStatus.online =>
                  ClientAgentsStatusChipKind.success,
                AgentConnectionStatus.offline => ClientAgentsStatusChipKind.error,
                AgentConnectionStatus.unknown =>
                  ClientAgentsStatusChipKind.neutral,
              },
            ),
          ),
          SizedBox(
            width: ClientAgentsApprovedAgentsTableLayout._actions(tokens),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (pendingRemove)
                  ClientAgentsStatusChip(
                    label: l10n.clientAgentsPendingChipRemove,
                    kind: ClientAgentsStatusChipKind.info,
                  ),
                if (agent.isStaleCache)
                  ClientAgentsStatusChip(
                    label: l10n.clientAgentsApprovedStaleCacheChip,
                    kind: ClientAgentsStatusChipKind.neutral,
                  ),
                if (!selecting)
                  AppSecondaryButton(
                    label: l10n.clientAgentsRemoveAccess,
                    onPressed: isMutating || pendingRemove
                        ? null
                        : onRemoveAccess,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: row,
        ),
      ),
    );
  }
}
