import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_filters_sheet_scaffold.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

/// Detail-level selector section of the sales live map filters sheet —
/// chooses between branches, municipalities and states granularity for the
/// map markers.
class SalesLiveMapFiltersDetailSection extends StatelessWidget {
  const SalesLiveMapFiltersDetailSection({
    required this.l10n,
    required this.tokens,
    required this.theme,
    required this.detailLevel,
    required this.onDetailLevelChanged,
    super.key,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ThemeData theme;
  final SalesLiveMapMapDetail detailLevel;
  final ValueChanged<SalesLiveMapMapDetail> onDetailLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SalesFiltersSectionHeader(
          title: l10n.salesLiveMapDetailLabel,
          subtitle: l10n.salesLiveMapDetailSubtitle,
        ),
        SizedBox(height: tokens.gapSm),
        AppSectionCard(
          color: theme.colorScheme.surfaceContainerLow,
          child: AppSegmentedControl<SalesLiveMapMapDetail>(
            value: detailLevel,
            expandToFill: true,
            options: <AppSegmentedControlOption<SalesLiveMapMapDetail>>[
              AppSegmentedControlOption<SalesLiveMapMapDetail>(
                value: SalesLiveMapMapDetail.branches,
                label: l10n.salesLiveMapDetailBranches,
              ),
              AppSegmentedControlOption<SalesLiveMapMapDetail>(
                value: SalesLiveMapMapDetail.municipalities,
                label: l10n.salesLiveMapDetailMunicipalities,
              ),
              AppSegmentedControlOption<SalesLiveMapMapDetail>(
                value: SalesLiveMapMapDetail.states,
                label: l10n.salesLiveMapDetailStates,
              ),
            ],
            onChanged: onDetailLevelChanged,
          ),
        ),
      ],
    );
  }
}
