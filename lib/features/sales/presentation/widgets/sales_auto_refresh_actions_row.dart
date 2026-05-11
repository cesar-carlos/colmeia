import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesAutoRefreshActionsRow extends StatelessWidget {
  const SalesAutoRefreshActionsRow({
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.lastUpdatedAt,
    required this.l10n,
    super.key,
  });

  final SalesAutoRefreshInterval? value;
  final ValueChanged<SalesAutoRefreshInterval?> onChanged;
  final bool enabled;
  final DateTime? lastUpdatedAt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final updatedAt = lastUpdatedAt;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.gapMd,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          if (updatedAt != null)
            Text(
              l10n.salesAutoRefreshLastUpdatedAt(
                DateFormat.Hm(l10n.localeName).format(updatedAt),
              ),
              style: theme.appTypography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          SalesAutoRefreshControl(
            value: value,
            onChanged: onChanged,
            offLabel: l10n.salesAutoRefreshOff,
            tooltipLabel: l10n.salesAutoRefreshTooltip,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
