import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/pagination/app_inline_pagination_bar.dart';
import 'package:flutter/material.dart';

class AppInlinePaginationDemoPage extends StatelessWidget {
  const AppInlinePaginationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Paginacao',
          title: 'AppInlinePaginationBar',
          subtitle:
              'Anterior / proximo, rotulos, tooltips e centro customizavel '
              '(AppInlinePaginationBarStyle).',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Exemplo',
          child: AppInlinePaginationBar(
            center: Column(
              children: <Widget>[
                Text(
                  'Pagina 2 de 8',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '152 resultados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            previousLabel: 'Anterior',
            nextLabel: 'Proxima',
            previousTooltip: 'Voltar uma pagina',
            nextTooltip: 'Avancar uma pagina',
            onPrevious: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pagina anterior')),
              );
            },
            onNext: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proxima pagina')),
              );
            },
            style: AppInlinePaginationBarStyle(
              buttonsExpanded: false,
              spacing: tokens.contentSpacing,
              centerTextStyle: theme.textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }
}
