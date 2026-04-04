import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientAgentDetailPage extends StatefulWidget {
  const ClientAgentDetailPage({
    required this.agentId,
    super.key,
  });

  final String agentId;

  @override
  State<ClientAgentDetailPage> createState() => _ClientAgentDetailPageState();
}

class _ClientAgentDetailPageState extends State<ClientAgentDetailPage> {
  late final ClientAgentDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ClientAgentDetailController>();
    unawaited(_controller.load(widget.agentId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return ChangeNotifierProvider<ClientAgentDetailController>.value(
      value: _controller,
      child: Consumer<ClientAgentDetailController>(
        builder: (context, controller, _) {
          final agent = controller.agent;
          return ListView(
            padding: context.pageScrollPadding(tokens),
            children: <Widget>[
              const AppShellPageIntro(
                eyebrow: 'Detalhe',
                title: 'Agente',
                subtitle:
                    'Informacoes detalhadas da fonte de dados selecionada.',
              ),
              SizedBox(height: tokens.sectionSpacing),
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (controller.errorMessage != null)
                AppInlineErrorPanel(
                  title: 'Nao foi possivel carregar o agente',
                  message: controller.errorMessage!,
                  onRetry: controller.reload,
                )
              else if (agent != null)
                AppSectionCardWithHeading(
                  title: agent.name,
                  subtitle: agent.tradeName ?? 'Sem nome fantasia',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Documento: ${agent.registrationDocument ?? 'N/A'}'),
                      Text('Email: ${agent.email ?? 'N/A'}'),
                      Text('Telefone: ${agent.phone ?? agent.mobile ?? 'N/A'}'),
                      Text('Cidade: ${agent.address?.shortLabel ?? 'N/A'}'),
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
