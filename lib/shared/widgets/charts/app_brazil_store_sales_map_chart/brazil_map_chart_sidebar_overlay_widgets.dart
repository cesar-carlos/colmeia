import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_chart/brazil_map_chart_sidebar_core.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_overlay_chrome.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:flutter/material.dart';

class BrazilMapChartDesktopBranchSidebarOverlay extends StatelessWidget {
  const BrazilMapChartDesktopBranchSidebarOverlay({
    required this.width,
    required this.maxHeight,
    required this.topInset,
    required this.horizontalInset,
    required this.entries,
    required this.allowCollapse,
    required this.onToggleCollapsed,
    required this.onSelectBranch,
    required this.onPreviewBranchStart,
    required this.onPreviewBranchEnd,
    super.key,
    this.selectedStoreId,
  });

  final double width;
  final double maxHeight;
  final double topInset;
  final double horizontalInset;
  final List<AppBrazilStoreSalesVisibleBranchListItem> entries;
  final bool allowCollapse;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<AppBrazilStoreSalesPoint> onSelectBranch;
  final ValueChanged<AppBrazilStoreSalesPoint> onPreviewBranchStart;
  final VoidCallback onPreviewBranchEnd;
  final String? selectedStoreId;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topInset,
      left: horizontalInset,
      child: KeyedSubtree(
        key: const ValueKey<String>('brazil-store-sales-map-sidebar-floating'),
        child: BrazilMapChartDesktopBranchSidebar(
          width: width,
          maxHeight: maxHeight,
          entries: entries,
          selectedStoreId: selectedStoreId,
          allowCollapse: allowCollapse,
          onToggleCollapsed: onToggleCollapsed,
          onSelectBranch: onSelectBranch,
          onPreviewBranchStart: onPreviewBranchStart,
          onPreviewBranchEnd: onPreviewBranchEnd,
        ),
      ),
    );
  }
}

class BrazilMapChartDesktopBranchSidebarCollapsedOverlay
    extends StatelessWidget {
  const BrazilMapChartDesktopBranchSidebarCollapsedOverlay({
    required this.topInset,
    required this.horizontalInset,
    required this.onExpand,
    super.key,
  });

  final double topInset;
  final double horizontalInset;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colorScheme = theme.colorScheme;
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);

    return AppBrazilStoreSalesMapOverlayTooltipScope(
      child: Positioned(
        top: topInset,
        left: horizontalInset,
        child: KeyedSubtree(
          key: const ValueKey<String>(
            'brazil-store-sales-map-sidebar-collapsed',
          ),
          child: Semantics(
            button: true,
            label: l10n.brazilStoreSalesMapSidebarExpandTooltip,
            child: AppSectionCard(
              color: colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(
                BrazilMapLayoutConstants.floatingMapOverlaySurfaceRadius,
              ),
              borderSide: BorderSide(
                color: appColors.secondary.withValues(alpha: 0.12),
              ),
              padding: EdgeInsets.zero,
              child: Tooltip(
                message: l10n.brazilStoreSalesMapSidebarExpandTooltip,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    BrazilMapLayoutConstants.floatingMapOverlaySurfaceRadius,
                  ),
                  onTap: onExpand,
                  child: Padding(
                    padding: EdgeInsets.all(tokens.gapSm),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: appColors.secondary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
