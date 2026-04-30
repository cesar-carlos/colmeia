import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';

class SalesFiltersSheetScaffold extends StatelessWidget {
  const SalesFiltersSheetScaffold({
    required this.title,
    required this.bodyBuilder,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
    super.key,
    this.description,
    this.canPrimaryAction = true,
    this.initialChildSize = 0.82,
    this.minChildSize = 0.52,
    this.maxChildSize = 0.94,
  });

  final String title;
  final String? description;
  final Widget Function(ScrollController scrollController) bodyBuilder;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;
  final bool canPrimaryAction;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.contentSpacing,
                  tokens.gapSm,
                  tokens.contentSpacing,
                  tokens.gapSm,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ],
                ),
              ),
              if (description != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.contentSpacing,
                    0,
                    tokens.contentSpacing,
                    tokens.gapMd,
                  ),
                  child: Text(
                    description!,
                    style: theme.appTypography.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(child: bodyBuilder(scrollController)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.contentSpacing,
                  tokens.gapSm,
                  tokens.contentSpacing,
                  tokens.contentSpacing,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AppSecondaryButton(
                        fillWidth: true,
                        label: secondaryActionLabel,
                        onPressed: onSecondaryAction,
                      ),
                    ),
                    SizedBox(width: tokens.gapMd),
                    Expanded(
                      child: AppPrimaryButton(
                        fillWidth: true,
                        label: primaryActionLabel,
                        onPressed: canPrimaryAction ? onPrimaryAction : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SalesFiltersSectionHeader extends StatelessWidget {
  const SalesFiltersSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.requiredBadgeLabel,
  });

  final String title;
  final String? subtitle;
  final String? requiredBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: theme.appTypography.utilityOverline.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (requiredBadgeLabel != null)
              AppTagChip(
                label: requiredBadgeLabel!,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          SizedBox(height: tokens.gapXs),
          Text(
            subtitle!,
            style: theme.appTypography.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
