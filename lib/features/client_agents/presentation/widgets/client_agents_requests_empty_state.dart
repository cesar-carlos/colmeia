import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

class ClientAgentsRequestsEmptyState extends StatelessWidget {
  const ClientAgentsRequestsEmptyState({
    required this.l10n,
    required this.message,
    required this.hasActiveFilters,
    super.key,
    this.onClearFilters,
    this.onNavigateToRequestAccess,
  });

  final AppLocalizations l10n;
  final String message;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onNavigateToRequestAccess;

  @override
  Widget build(BuildContext context) {
    final clearFilters = onClearFilters;
    final requestAccess = onNavigateToRequestAccess;
    final showClearFilters = hasActiveFilters && clearFilters != null;
    final showRequestAccess = !showClearFilters && requestAccess != null;

    return AppInlineErrorPanel(
      tone: AppInlinePanelTone.informational,
      variant: AppInlineErrorPanelVariant.plain,
      message: message,
      actions: showClearFilters || showRequestAccess
          ? Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: showClearFilters ? clearFilters : requestAccess,
                child: Text(
                  showClearFilters
                      ? l10n.reportEmptyClearFiltersAction
                      : l10n.clientAgentsEmptyRequestsAction,
                ),
              ),
            )
          : null,
    );
  }
}
