import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';

class ClientAgentsBulkSelectionBar extends StatelessWidget {
  const ClientAgentsBulkSelectionBar({
    required this.l10n,
    required this.selectedCount,
    required this.onCancel,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onRemoveSelected,
    super.key,
    this.isMutating = false,
  });

  final AppLocalizations l10n;
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onRemoveSelected;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.colorScheme;

    return Material(
      elevation: 8,
      color: colors.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.gapMd,
            vertical: tokens.gapSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.clientAgentsApprovedBulkSelectionModeHint(selectedCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.gapSm),
              Wrap(
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  AppSecondaryButton(
                    label: l10n.clientAgentsApprovedBulkCancel,
                    onPressed: isMutating ? null : onCancel,
                  ),
                  AppFlatButton(
                    label: l10n.clientAgentsApprovedBulkSelectAll,
                    fillWidth: false,
                    onPressed: isMutating ? null : onSelectAll,
                  ),
                  AppFlatButton(
                    label: l10n.clientAgentsApprovedBulkClearSelection,
                    fillWidth: false,
                    onPressed: isMutating || selectedCount == 0
                        ? null
                        : onClearSelection,
                  ),
                  if (selectedCount > 0)
                    AppPrimaryButton(
                      label: l10n.clientAgentsApprovedBulkRemove(selectedCount),
                      onPressed: isMutating ? null : onRemoveSelected,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
