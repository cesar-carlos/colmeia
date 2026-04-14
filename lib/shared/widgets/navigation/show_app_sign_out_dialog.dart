import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

/// Returns true if the user confirmed sign-out.
Future<bool> showAppSignOutConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AppConfirmDialog(
        title: l10n.shellSignOutDialogTitle,
        confirmLabel: l10n.shellSignOutDialogConfirm,
        message: l10n.shellSignOutDialogMessage,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
        onClose: () => Navigator.of(ctx).pop(false),
      );
    },
  );
  return result ?? false;
}
