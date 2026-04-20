import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Banner inline de aviso "dados podem estar desatualizados" com acao de
/// atualizar. Use em listas, dashboards e snapshots quando a fonte estiver
/// `stale` mas ainda exibivel.
class AppDataStaleBanner extends StatelessWidget {
  const AppDataStaleBanner({
    required this.onRefresh,
    super.key,
    this.message = 'Dados podem estar desatualizados.',
    this.actionLabel = 'Atualizar',
    this.icon = Icons.update_rounded,
  });

  final VoidCallback onRefresh;
  final String message;
  final String actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final color = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        SizedBox(width: tokens.gapXs + 2),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
        TextButton(
          onPressed: onRefresh,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
