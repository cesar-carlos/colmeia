import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PwaSettingsPanel extends StatelessWidget {
  const PwaSettingsPanel({super.key});
  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<PwaPlatform>() || !getIt<PwaPlatform>().supported) {
      return const SizedBox.shrink();
    }
    return AppSectionCard(
      child: ListTile(
        leading: const Icon(Icons.offline_pin_outlined),
        title: const Text('Disponível offline'),
        subtitle: const Text('Pacotes por loja, instalação e notificações'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(pwaOfflineRouteName),
      ),
    );
  }
}
