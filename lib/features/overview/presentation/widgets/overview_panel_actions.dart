import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';

/// Primary / secondary actions used on overview inline error panels.
class OverviewPanelActions extends StatelessWidget {
  const OverviewPanelActions({
    required this.manageAgentsLabel,
    this.onRetry,
    this.onManageAgents,
    this.onShowDetails,
    this.detailsLabel,
    this.detailsSemanticsLabel,
    this.retryLabel,
    this.primaryLabel,
    this.retryDisabledLabel,
    super.key,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onManageAgents;
  final VoidCallback? onShowDetails;
  final String? detailsLabel;

  /// Screen reader label for [onShowDetails]. Defaults to [detailsLabel].
  final String? detailsSemanticsLabel;
  final String? retryLabel;
  final String? primaryLabel;
  final String manageAgentsLabel;

  /// When non-null, the retry button is rendered in a disabled state
  /// using this label (e.g. a "Retry in 5s" countdown set by the
  /// overview controller's `RetryAfterGate`) regardless of [onRetry].
  /// Use this — instead of nulling [onRetry] — to keep the button
  /// visible while the cool-down window is open.
  final String? retryDisabledLabel;

  @override
  Widget build(BuildContext context) {
    assert(
      onShowDetails == null ||
          (detailsLabel != null && detailsLabel!.trim().isNotEmpty),
      'detailsLabel is required and non-empty when onShowDetails is set',
    );
    assert(
      onRetry == null ||
          retryDisabledLabel != null ||
          (retryLabel != null && retryLabel!.isNotEmpty),
      'retryLabel is required when onRetry is set',
    );
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final disabledLabel = retryDisabledLabel;
    final showRetryButton = onRetry != null || disabledLabel != null;
    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: <Widget>[
        if (showRetryButton)
          AppPrimaryButton(
            label: disabledLabel ?? primaryLabel ?? retryLabel!,
            onPressed: disabledLabel != null ? null : onRetry,
          ),
        if (onShowDetails != null &&
            detailsLabel != null &&
            detailsLabel!.trim().isNotEmpty)
          AppFlatButton(
            label: detailsLabel!.trim(),
            onPressed: onShowDetails,
            semanticsLabel: (detailsSemanticsLabel ?? detailsLabel)!.trim(),
          ),
        if (onManageAgents != null)
          (!showRetryButton
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
