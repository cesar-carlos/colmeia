import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class SalesProdutoTendenciaFilteredEmptyState extends StatelessWidget {
  const SalesProdutoTendenciaFilteredEmptyState({
    required this.l10n,
    required this.message,
    required this.hasActiveDetailFilters,
    super.key,
    this.onClearFilters,
    this.onOpenFilters,
  });

  final AppLocalizations l10n;
  final String message;
  final bool hasActiveDetailFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final clearFilters = onClearFilters;
    final openFilters = onOpenFilters;
    final showClearFilters = hasActiveDetailFilters && clearFilters != null;
    final showOpenFilters = !showClearFilters && openFilters != null;

    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      variant: AppInlineErrorPanelVariant.plain,
      message: message,
      actions: showClearFilters || showOpenFilters
          ? Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: showClearFilters ? clearFilters : openFilters,
                child: Text(
                  showClearFilters
                      ? l10n.reportEmptyClearFiltersAction
                      : l10n.salesProdutoTendenciaEmptyAdjustPeriodAction,
                ),
              ),
            )
          : null,
    );
  }
}
