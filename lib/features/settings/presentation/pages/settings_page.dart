import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<CurrentUserContextController>();
    final tokens = theme.extension<AppThemeTokens>()!;
    final permissionsLabel = controller.permissions
        .map((permission) => permission.label)
        .join(', ');

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                controller.userScope.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.gapSm),
              Text(controller.userScope.roleLabel),
              SizedBox(height: tokens.contentSpacing),
              Text('Loja ativa: ${controller.activeStore.name}'),
              SizedBox(height: tokens.contentSpacing),
              Text(
                'Permissoes liberadas: $permissionsLabel',
              ),
              if (controller.errorMessage
                  case final String errorMessage) ...<Widget>[
                SizedBox(height: tokens.contentSpacing),
                Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Preferencias',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.gapMd),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.notifications_outlined),
                title: Text('Alertas em tempo real'),
                subtitle: Text('Preparado para a fase futura de socket'),
              ),
              const Divider(),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.palette_outlined),
                title: Text('Tema do app'),
                subtitle: Text(
                  'A identidade visual sera expandida no design system',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        FilledButton.tonalIcon(
          onPressed: context.read<AuthController>().signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    );
  }
}
