import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_initials.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppShellAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final userContext = context.watch<CurrentUserContextController>();
    final userScope = userContext.userScope;

    return AppBar(
      titleSpacing: 0,
      title: Semantics(
        header: true,
        label: 'Colmeia',
        child: Text(
          'Colmeia',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Notificações',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notificações em breve.'),
              ),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.goTo(AppRoute.settings),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Text(
                  appShellUserInitials(userScope.name),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
