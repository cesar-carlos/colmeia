import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Returns `true` when the user chooses to discard unsaved edits and proceed.
Future<bool> confirmDiscardClientAgentUnsavedChanges(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.clientAgentDetailUnsavedChangesTitle),
        content: Text(l10n.clientAgentDetailUnsavedChangesMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.clientAgentDetailUnsavedChangesStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.clientAgentDetailUnsavedChangesDiscard),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
