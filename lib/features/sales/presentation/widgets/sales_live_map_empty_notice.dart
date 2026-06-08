import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class SalesLiveMapEmptyNotice extends StatelessWidget {
  const SalesLiveMapEmptyNotice({
    required this.result,
    required this.hasSelectedBranches,
    required this.l10n,
    this.hasPartialIssue = false,
    this.onClearSelectedBranches,
    super.key,
  });

  final SalesLiveMapLoadResult result;
  final bool hasSelectedBranches;
  final bool hasPartialIssue;
  final VoidCallback? onClearSelectedBranches;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final selectedWithoutRows =
        hasSelectedBranches &&
        result.totalBranchCount == 0 &&
        result.totalSalesCount == 0;
    final message = selectedWithoutRows
        ? l10n.salesLiveMapEmptySelectionMessage
        : hasPartialIssue
        ? l10n.salesLiveMapEmptyNoSalesWithPartialMessage
        : l10n.salesLiveMapEmptyNoSalesMessage;
    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      title: selectedWithoutRows
          ? l10n.salesLiveMapEmptySelectionTitle
          : l10n.salesLiveMapEmptyNoSalesTitle,
      message: message,
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
