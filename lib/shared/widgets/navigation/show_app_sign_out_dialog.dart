import 'package:flutter/material.dart';

/// Returns true if the user confirmed sign-out.
Future<bool> showAppSignOutConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Voce precisara entrar novamente para acessar os dados.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
