import 'package:colmeia/features/dashboards/domain/entities/dashboard_ai_insight.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/app_editorial_media_card.dart';
import 'package:flutter/material.dart';

/// Stitch-style IA insight callout: tonal surface and operational CTA.
class DashboardAiInsightCard extends StatelessWidget {
  const DashboardAiInsightCard({
    required this.insight,
    this.onApply,
    super.key,
  });

  final DashboardAiInsight insight;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return AppEditorialMediaCard(
      heroHeight: 164,
      heroBackgroundColor: cs.surfaceContainerLowest,
      title: insight.title,
      description: insight.body,
      footer: AppPrimaryButton(
        label: insight.ctaLabel.toUpperCase(),
        onPressed: onApply,
        fillWidth: true,
      ),
      hero: _DashboardAiInsightArtwork(
        accentColor: cs.tertiary,
        highlightColor: cs.primary,
        tokens: tokens,
      ),
    );
  }
}

class _DashboardAiInsightArtwork extends StatelessWidget {
  const _DashboardAiInsightArtwork({
    required this.accentColor,
    required this.highlightColor,
    required this.tokens,
  });

  final Color accentColor;
  final Color highlightColor;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: -32,
          top: 16,
          bottom: 12,
          width: 116,
          child: Transform.rotate(
            angle: -0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(tokens.cardRadius + 8),
              ),
            ),
          ),
        ),
        Positioned(
          right: -26,
          top: -10,
          bottom: 10,
          width: 136,
          child: Transform.rotate(
            angle: 0.22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(tokens.cardRadius + 12),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 252,
            height: 128,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  accentColor.withValues(alpha: 0.92),
                  accentColor.withValues(alpha: 0.68),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(tokens.cardRadius + 10),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 26,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  SizedBox(height: tokens.gapSm),
                  Text(
                    'AI\nINSIGHT',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 72,
              height: 12,
              decoration: BoxDecoration(
                color: highlightColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
