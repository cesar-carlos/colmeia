import 'dart:math' as math;

import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/bottom_sheet_compact_drag_handle.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

part 'overview_home_agent_filter_rows.dart';
part 'overview_home_agent_filter_sheet.dart';

const int _kMaxInlineChips = 3;

/// Visual radius applied to the tappable surface that wraps the inline agent
/// chips. Slightly looser than [AppThemeTokens.formFieldRadius] so the round
/// corners read clearly against the surrounding form fields, which use
/// straight token radius.
const double _kAgentFilterSurfaceExtraRadius = 2;

/// [InputChip] avatar slot width from Material; dual-status icons must fit here.
const double _kAgentFilterChipAvatarSize = 20;

/// Home overview agent filter: compact summary, sheet for bulk selection.
///
/// The summary row, the "many selected" condensed row and the inline chips
/// live in [`overview_home_agent_filter_rows.dart`]; the bulk-selection
/// modal lives in [`overview_home_agent_filter_sheet.dart`]. All three are
/// `part` files of this library so they keep using the library-private
/// helpers (`_overviewAgentNameColor`, `_agentFilterChipAvatar`).
class OverviewHomeAgentFilterControl extends StatelessWidget {
  const OverviewHomeAgentFilterControl({
    required this.l10n,
    required this.availableAgents,
    required this.selectedAgentIds,
    required this.onSelectionChanged,
    super.key,
    this.enabled = true,
  });

  final AppLocalizations l10n;
  final List<DashboardAgentOption> availableAgents;

  /// Domain: `null` means all approved agents.
  final Set<String>? selectedAgentIds;

  /// Emits domain-level selection: `null` when equivalent to “all agents”.
  final ValueChanged<Set<String>?> onSelectionChanged;
  final bool enabled;

  Set<String> get _allIds => availableAgents.map((e) => e.agentId).toSet();

  void _emitNormalized(Set<String> explicit) {
    final all = _allIds;
    if (explicit.length == all.length && explicit.containsAll(all)) {
      onSelectionChanged(null);
      return;
    }
    onSelectionChanged(explicit);
  }

  Future<void> _openSheet(BuildContext context) async {
    if (!enabled || availableAgents.isEmpty) {
      return;
    }
    final initial = selectedAgentIds == null
        ? Set<String>.from(_allIds)
        : Set<String>.from(selectedAgentIds!);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (ctx) => _OverviewAgentSelectionSheet(
        l10n: l10n,
        availableAgents: availableAgents,
        initialSelected: initial,
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }
    _emitNormalized(result);
  }

  void _removeOne(BuildContext context, String agentId) {
    final explicit = Set<String>.from(selectedAgentIds ?? _allIds)
      ..remove(agentId);
    if (explicit.isEmpty) {
      return;
    }
    _emitNormalized(explicit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(
      tokens.formFieldRadius + _kAgentFilterSurfaceExtraRadius,
    );
    final labelToFieldGap = tokens.gapXs;

    if (availableAgents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.dashboardHomeFiltersBranchesLabel,
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: labelToFieldGap),
          Text(
            l10n.dashboardHomeFiltersBranchesEmptyHint,
            style: typography.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final explicitIds = selectedAgentIds == null ? _allIds : selectedAgentIds!;
    final count = explicitIds.length;
    final allCount = availableAgents.length;
    final isImplicitAll = selectedAgentIds == null;
    final showManySummary = !isImplicitAll && count > _kMaxInlineChips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.dashboardHomeFiltersBranchesLabel,
          style: typography.utilityOverline.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: labelToFieldGap),
        Semantics(
          container: true,
          label: isImplicitAll
              ? l10n.overviewHomeBranchFilterAllBranchesSummary(allCount)
              : l10n.overviewHomeBranchFilterSelectedCount(count),
          child: Material(
            color: scheme.surfaceContainerLowest,
            borderRadius: borderRadius,
            child: InkWell(
              onTap: enabled ? () => _openSheet(context) : null,
              borderRadius: borderRadius,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.54),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.formFieldPaddingHorizontal,
                  vertical: tokens.gapSm,
                ),
                child: isImplicitAll
                    ? _AllAgentsSummaryRow(
                        l10n: l10n,
                        totalCount: allCount,
                        refineLabel: l10n.overviewHomeBranchFilterRefineAction,
                        enabled: enabled,
                        onRefine: () => _openSheet(context),
                      )
                    : showManySummary
                    ? _ManySelectedSummaryRow(
                        l10n: l10n,
                        count: count,
                        editLabel: l10n.overviewHomeBranchFilterEditAction,
                        enabled: enabled,
                        onEdit: () => _openSheet(context),
                      )
                    : _InlineChipsRow(
                        availableAgents: availableAgents,
                        selectedIds: explicitIds,
                        enabled: enabled,
                        onRemove: (id) => _removeOne(context, id),
                        onAddOrEdit: () => _openSheet(context),
                        editLabel: l10n.overviewHomeBranchFilterEditAction,
                        scheme: scheme,
                        tokens: tokens,
                        typography: typography,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Color _overviewAgentNameColor(
  AgentConnectionStatus status,
  ColorScheme scheme,
) {
  return switch (status) {
    AgentConnectionStatus.offline => scheme.error,
    AgentConnectionStatus.online ||
    AgentConnectionStatus.unknown => scheme.onSurface,
  };
}

Widget? _agentFilterChipAvatar(DashboardAgentOption agent, ColorScheme scheme) {
  final offline = agent.connectionStatus == AgentConnectionStatus.offline;
  final noToken = agent.missingLocalClientToken;
  if (offline && noToken) {
    return SizedBox(
      width: _kAgentFilterChipAvatarSize,
      height: _kAgentFilterChipAvatarSize,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, size: 14, color: scheme.error),
            const SizedBox(width: 3),
            Icon(
              Icons.vpn_key_off_outlined,
              size: 14,
              color: scheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
  if (offline) {
    return Icon(
      Icons.cloud_off_outlined,
      size: 16,
      color: scheme.error,
    );
  }
  if (noToken) {
    return Icon(
      Icons.vpn_key_off_outlined,
      size: 16,
      color: scheme.tertiary,
    );
  }
  return null;
}
