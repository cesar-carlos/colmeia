import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';

/// Primary / secondary actions used on overview inline error panels.
class OverviewPanelActions extends StatelessWidget {
  const OverviewPanelActions({
    required this.manageAgentsLabel,
    this.onRetry,
    this.onManageAgents,
    this.retryLabel,
    this.primaryLabel,
    super.key,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onManageAgents;
  final String? retryLabel;
  final String? primaryLabel;
  final String manageAgentsLabel;

  @override
  Widget build(BuildContext context) {
    assert(
      onRetry == null || (retryLabel != null && retryLabel!.isNotEmpty),
      'retryLabel is required when onRetry is set',
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: <Widget>[
        if (onRetry != null)
          AppPrimaryButton(
            label: primaryLabel ?? retryLabel!,
            onPressed: onRetry,
          ),
        if (onManageAgents != null)
          (onRetry == null
              ? AppPrimaryButton(
                  label: primaryLabel ?? manageAgentsLabel,
                  icon: const Icon(Icons.hub_rounded),
                  onPressed: onManageAgents,
                )
              : AppSecondaryButton(
                  label: manageAgentsLabel,
                  icon: const Icon(Icons.hub_outlined),
                  onPressed: onManageAgents,
                )),
      ],
    );
  }
}
