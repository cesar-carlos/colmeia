import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_auto_refresh_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_control.dart';
import 'package:flutter/material.dart';

class SalesAutoRefreshControl extends StatelessWidget {
  const SalesAutoRefreshControl({
    required this.value,
    required this.onChanged,
    required this.offLabel,
    required this.tooltipLabel,
    super.key,
    this.enabled = true,
  });

  final AutoRefreshOption? value;
  final ValueChanged<AutoRefreshOption?> onChanged;
  final String offLabel;
  final String tooltipLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AutoRefreshControl(
      options: SalesAutoRefreshOptions.values,
      optionLabelBuilder: (option) =>
          SalesAutoRefreshL10n.intervalLabel(l10n, option),
      value: value,
      onChanged: onChanged,
      offLabel: offLabel,
      tooltipLabel: tooltipLabel,
      enabled: enabled,
      keyPrefix: 'sales-auto-refresh',
    );
  }
}
