import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_header.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_menu_item.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer_menu_list.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_route_presentation.dart';
import 'package:colmeia/shared/widgets/navigation/show_app_sign_out_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppShellDrawer extends StatelessWidget {
  const AppShellDrawer({
    required this.currentRoute,
    required this.visibleShellRoutes,
    super.key,
  });

  final AppRoute currentRoute;
  final List<AppRoute> visibleShellRoutes;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.contentSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppShellDrawerHeader(),
              SizedBox(height: tokens.sectionSpacing),
              Expanded(
                child: AppShellDrawerMenuList(
                  children: visibleShellRoutes
                      .map(
                        (route) {
                          final selected =
                              route.shellIndex != null &&
                              route.shellIndex == currentRoute.shellIndex;
                          final subtitle = appShellRouteSubtitle(route);
                          return AppShellDrawerMenuItem(
                            icon: appShellRouteIcon(route, selected: selected),
                            title: appShellRouteLabel(route),
                            subtitle: subtitle,
                            selected: selected,
                            onTap: () {
                              Navigator.of(context).pop();
                              if (route != currentRoute) {
                                context.goTo(route);
                              }
                            },
                          );
                        },
                      )
                      .toList(growable: false),
                ),
              ),
              if (kDebugMode) ...<Widget>[
                const Divider(),
                AppFlatButton(
                  icon: const Icon(Icons.widgets_outlined),
                  label: 'Componentes (dev)',
                  semanticsLabel:
                      'Abrir catalogo de componentes de desenvolvimento',
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(
                      context.push(sharedComponentsDemoIndexLocation),
                    );
                  },
                ),
                SizedBox(height: tokens.gapMd),
              ],
              AppFlatButton(
                icon: const Icon(Icons.logout_rounded),
                label: 'Sair',
                semanticsLabel: 'Sair da conta',
                onPressed: () async {
                  final confirmed = await showAppSignOutConfirmDialog(context);
                  if (!context.mounted || !confirmed) {
                    return;
                  }
                  Navigator.of(context).pop();
                  await context.read<AuthController>().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
