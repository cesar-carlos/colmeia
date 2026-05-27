import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

/// Marker-visual selector section of the sales live map filters sheet —
/// chooses between dot, bubble and store-icon presentations for the markers
/// rendered on the map.
class SalesLiveMapFiltersVisualSection extends StatelessWidget {
  const SalesLiveMapFiltersVisualSection({
    required this.l10n,
    required this.tokens,
    required this.theme,
    required this.markerVisual,
    required this.onMarkerVisualChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final SalesLiveMapMarkerVisual markerVisual;
  final ValueChanged<SalesLiveMapMarkerVisual> onMarkerVisualChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesFiltersSectionHeader(
          title: l10n.salesLiveMapVisualLabel,
          subtitle: l10n.salesLiveMapVisualSubtitle,
        ),
        SizedBox(height: tokens.gapSm),
        AppSectionCard(
          color: theme.colorScheme.surfaceContainerLow,
          child: AppSegmentedControl<SalesLiveMapMarkerVisual>(
            value: markerVisual,
            expandToFill: true,
            options: <AppSegmentedControlOption<SalesLiveMapMarkerVisual>>[
              AppSegmentedControlOption<SalesLiveMapMarkerVisual>(
                value: SalesLiveMapMarkerVisual.dot,
                label: l10n.salesLiveMapVisualDot,
              ),
              AppSegmentedControlOption<SalesLiveMapMarkerVisual>(
                value: SalesLiveMapMarkerVisual.bubble,
                label: l10n.salesLiveMapVisualBubble,
              ),
              AppSegmentedControlOption<SalesLiveMapMarkerVisual>(
                value: SalesLiveMapMarkerVisual.storeIcon,
                label: l10n.salesLiveMapVisualStoreIcon,
              ),
            ],
            onChanged: onMarkerVisualChanged,
          ),
        ),
      ],
    );
  }
}
