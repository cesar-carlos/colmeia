import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class SalesLiveMapEmptyNotice extends StatelessWidget {
  const SalesLiveMapEmptyNotice({
    required this.result,
    required this.hasSelectedBranches,
    required this.onClearSelectedBranches,
    required this.l10n,
    super.key,
  });

  final SalesLiveMapLoadResult result;
  final bool hasSelectedBranches;
  final VoidCallback onClearSelectedBranches;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final selectedWithoutRows =
        hasSelectedBranches &&
        result.totalBranchCount == 0 &&
        result.totalSalesCount == 0;
    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: selectedWithoutRows
          ? l10n.salesLiveMapEmptySelectionTitle
          : l10n.salesLiveMapEmptyNoSalesTitle,
      message: selectedWithoutRows
          ? l10n.salesLiveMapEmptySelectionMessage
          : l10n.salesLiveMapEmptyNoSalesMessage,
      actions: selectedWithoutRows
          ? Align(
              alignment: Alignment.centerLeft,
              child: AppSecondaryButton(
                label: l10n.salesLiveMapClearBranchSelectionAction,
                icon: const Icon(Icons.filter_alt_off_rounded),
                onPressed: onClearSelectedBranches,
              ),
            )
          : null,
    );
  }
}
