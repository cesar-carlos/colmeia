import 'package:colmeia/features/auth/data/register_store_catalog.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_form_section_title.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class RegisterStoreSelectionSection extends StatelessWidget {
  const RegisterStoreSelectionSection({
    required this.selectedIds,
    required this.onToggle,
    required this.showSelectionError,
    required this.enabled,
    super.key,
  });

  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final bool showSelectionError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RegisterFormSectionTitle(title: 'Solicitar acesso por loja'),
        if (showSelectionError) ...<Widget>[
          Text(
            'Selecione pelo menos uma unidade.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
          ),
          SizedBox(height: tokens.gapSm),
        ],
        ...RegisterStoreOption.stitchDefaults.map((store) {
          final selected = selectedIds.contains(store.id);
          return Padding(
            padding: EdgeInsets.only(bottom: tokens.gapSm),
            child: Material(
              color: selected
                  ? cs.primaryContainer.withValues(alpha: 0.35)
                  : cs.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(tokens.formFieldRadius),
              child: InkWell(
                onTap: enabled ? () => onToggle(store.id) : null,
                borderRadius: BorderRadius.circular(tokens.formFieldRadius),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.gapMd,
                    vertical: tokens.gapSm,
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        radius: 22,
                        child: Text(
                          store.stateCode,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              store.unitName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: tokens.gapXs),
                            Text(
                              store.cityLine,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        SizedBox(height: tokens.sectionSpacing),
      ],
    );
  }
}
