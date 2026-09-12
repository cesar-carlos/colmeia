import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_view.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_search_field.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

class SalesNotasEntradaReportToolbar extends StatelessWidget {
  const SalesNotasEntradaReportToolbar({
    required this.searchTerm,
    required this.onSearchChanged,
    required this.view,
    required this.onViewChanged,
    super.key,
    this.supplierScopeName,
    this.onClearSupplierScope,
    this.headerTrailing,
    this.enabled = true,
  });

  final String? searchTerm;
  final ValueChanged<String> onSearchChanged;
  final SalesNotasEntradaView view;
  final ValueChanged<SalesNotasEntradaView> onViewChanged;
  final String? supplierScopeName;
  final VoidCallback? onClearSupplierScope;
  final Widget? headerTrailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).appTokens;
    final searchField = SalesNotasEntradaSearchField(
      searchTerm: searchTerm,
      hintText: l10n.salesNotasEntradaSearchHint,
      onSearchChanged: onSearchChanged,
      enabled: enabled,
    );
    final trailing = headerTrailing;
    final searchRow = trailing == null
        ? searchField
        : Row(
            children: <Widget>[
              Expanded(child: searchField),
              SizedBox(width: tokens.gapSm),
              trailing,
            ],
          );

    final scopedSupplier = supplierScopeName?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        searchRow,
        if (scopedSupplier != null && scopedSupplier.isNotEmpty) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text(
                scopedSupplier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onDeleted: enabled ? onClearSupplierScope : null,
              deleteButtonTooltipMessage:
                  l10n.salesNotasEntradaClearSupplierScopeTooltip,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        SizedBox(height: tokens.contentSpacing),
        LayoutBuilder(
          builder: (context, constraints) {
            return AppSegmentedControl<SalesNotasEntradaView>(
              expandToFill: constraints.maxWidth < AppBreakpoints.mobile,
              value: view,
              onChanged: enabled ? onViewChanged : null,
              options: <AppSegmentedControlOption<SalesNotasEntradaView>>[
                AppSegmentedControlOption(
                  value: SalesNotasEntradaView.notes,
                  label: l10n.salesNotasEntradaViewNotes,
                ),
                AppSegmentedControlOption(
                  value: SalesNotasEntradaView.bySupplier,
                  label: l10n.salesNotasEntradaViewBySupplier,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
