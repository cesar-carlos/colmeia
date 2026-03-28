import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppSectionCardHeadingDemoPage extends StatelessWidget {
  const AppSectionCardHeadingDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Secoes',
          title: 'AppSectionCardWithHeading',
          subtitle:
              'Titulo, subtitulo, trailing, bloco extra abaixo do header e '
              'child.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          titleWidget: Row(
            children: <Widget>[
              Icon(Icons.view_day_outlined, color: theme.colorScheme.primary),
              SizedBox(width: tokens.gapSm),
              Text(
                'Heading rico',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          subtitle:
              'Heading com trailing, bloco extra abaixo e child reutilizavel.',
          headingTrailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          headingBottom: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: const <Widget>[
              Chip(label: Text('Filtros ativos')),
              Chip(label: Text('Atualizado agora')),
            ],
          ),
          child: Text(
            'Este card demonstra como montar uma secao mais rica '
            'sem perder o padrao do container compartilhado.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
