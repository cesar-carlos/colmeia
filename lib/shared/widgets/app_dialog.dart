import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_destructive_button.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    super.key,
    this.message,
    this.content,
    this.actions = const <Widget>[],
    this.leadingIcon,
    this.onClose,
    this.maxWidth = 460,
    this.surfaceColor,
  }) : assert(
         message != null || content != null,
         'Provide message or content.',
       );

  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final IconData? leadingIcon;
  final VoidCallback? onClose;
  final double maxWidth;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AppDialogSurface(
          title: title,
          message: message,
          content: content,
          actions: actions,
          leadingIcon: leadingIcon,
          onClose: onClose,
          surfaceColor: surfaceColor,
        ),
      ),
    );
  }
}

class AppDialogSurface extends StatelessWidget {
  const AppDialogSurface({
    required this.title,
    super.key,
    this.message,
    this.content,
    this.actions = const <Widget>[],
    this.leadingIcon,
    this.onClose,
    this.surfaceColor,
  }) : assert(
         message != null || content != null,
         'Provide message or content.',
       );

  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;
  final IconData? leadingIcon;
  final VoidCallback? onClose;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final scheme = theme.colorScheme;
    final resolvedSurface =
        surfaceColor ??
        theme.dialogTheme.backgroundColor ??
        scheme.surfaceContainerHigh;

    return Material(
      color: resolvedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(tokens.contentSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(width: tokens.gapSm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: typography.sectionHeaderH2.copyWith(
                      fontSize: theme.textTheme.titleLarge?.fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onClose != null)
                  AppFlatButton(
                    onPressed: onClose,
                    fillWidth: false,
                    semanticsLabel: 'Fechar diálogo',
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
            SizedBox(height: tokens.contentSpacing),
            if (content != null)
              content!
            else
              Text(
                message!,
                style: typography.body.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            if (actions.isNotEmpty) ...<Widget>[
              SizedBox(height: tokens.sectionSpacing),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    super.key,
    this.message,
    this.content,
    this.cancelLabel = 'Cancelar',
    this.onCancel,
    this.onClose,
    this.leadingIcon,
    this.maxWidth = 460,
    this.surfaceColor,
  }) : assert(
         message != null || content != null,
         'Provide message or content.',
       );

  final String title;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String? message;
  final Widget? content;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final IconData? leadingIcon;
  final double maxWidth;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      message: message,
      content: content,
      leadingIcon: leadingIcon,
      onClose: onClose,
      maxWidth: maxWidth,
      surfaceColor: surfaceColor,
      actions: <Widget>[
        AppSecondaryButton(
          onPressed: onCancel,
          label: cancelLabel,
        ),
        AppPrimaryButton(
          onPressed: onConfirm,
          label: confirmLabel,
        ),
      ],
    );
  }
}

class AppDestructiveDialog extends StatelessWidget {
  const AppDestructiveDialog({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    super.key,
    this.message,
    this.content,
    this.cancelLabel = 'Cancelar',
    this.onCancel,
    this.onClose,
    this.leadingIcon = Icons.warning_amber_rounded,
    this.maxWidth = 460,
    this.surfaceColor,
  }) : assert(
         message != null || content != null,
         'Provide message or content.',
       );

  final String title;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String? message;
  final Widget? content;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final IconData? leadingIcon;
  final double maxWidth;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      message: message,
      content: content,
      leadingIcon: leadingIcon,
      onClose: onClose,
      maxWidth: maxWidth,
      surfaceColor: surfaceColor,
      actions: <Widget>[
        AppSecondaryButton(
          onPressed: onCancel,
          label: cancelLabel,
        ),
        AppDestructiveButton(
          onPressed: onConfirm,
          label: confirmLabel,
        ),
      ],
    );
  }
}
