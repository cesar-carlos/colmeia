import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:flutter/material.dart';

/// Full-width primary CTA; delegates to [AppPrimaryButton] with auth styling.
class LoginPrimaryButton extends StatelessWidget {
  const LoginPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final radius = tokens?.formFieldRadius ?? 4;
    final minHeight = tokens?.authLoginCtaMinHeight ?? 60;

    return AppPrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      fillWidth: true,
      minimumHeight: minHeight,
      showLabelWhileLoading: true,
      loadingIndicatorSize: 18,
      loadingIndicatorStrokeWidth: 2,
      loadingIndicatorColor: cs.onPrimaryContainer,
      trailing: isLoading
          ? null
          : const Icon(Icons.arrow_forward_rounded, size: 20),
      semanticsLabel: isLoading ? 'Carregando: $label' : label,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        disabledBackgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
        disabledForegroundColor: cs.onPrimaryContainer.withValues(alpha: 0.38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        padding: EdgeInsets.zero,
        minimumSize: Size(double.infinity, minHeight),
        maximumSize: Size(double.infinity, minHeight),
      ),
    );
  }
}
