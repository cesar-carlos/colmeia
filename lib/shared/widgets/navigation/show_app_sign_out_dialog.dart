import 'package:colmeia/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

/// Returns true if the user confirmed sign-out.
Future<bool> showAppSignOutConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AppConfirmDialog(
        title: 'Sair da conta?',
        confirmLabel: 'Sair',
        message: 'Voce precisara entrar novamente para acessar os dados.',
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
        onClose: () => Navigator.of(ctx).pop(false),
      );
    },
  );
  return result ?? false;
}
