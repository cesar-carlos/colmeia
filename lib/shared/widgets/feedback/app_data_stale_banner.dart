import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Banner inline de aviso "dados podem estar desatualizados" com acao de
/// atualizar. Use em listas, dashboards e snapshots quando a fonte estiver
/// `stale` mas ainda exibivel.
class AppDataStaleBanner extends StatelessWidget {
  const AppDataStaleBanner({
    required this.onRefresh,
    super.key,
    this.message,
    this.actionLabel,
    this.icon = Icons.update_rounded,
  });

  final VoidCallback onRefresh;

  /// Banner message. When null a localized default is used.
  final String? message;

  /// Refresh action label. When null a localized default is used.
  final String? actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final resolvedMessage = message ?? l10n.dataStaleBannerMessage;
    final resolvedActionLabel = actionLabel ?? l10n.appRefreshAction;

    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        SizedBox(width: tokens.gapXs + 2),
        Expanded(
          child: Text(
            resolvedMessage,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
        TextButton(
          onPressed: onRefresh,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
          ),
          child: Text(resolvedActionLabel),
        ),
      ],
    );
  }
}
