import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/registration_status_page_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_form_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_brand_header.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_footer.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_glass_card.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/backgrounds/app_hex_screen_body.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegistrationStatusPage extends StatelessWidget {
  const RegistrationStatusPage({
    required this.readRegistrationStatusUseCase,
    super.key,
    this.initialToken,
  });

  final ReadRegistrationStatusUseCase readRegistrationStatusUseCase;
  final String? initialToken;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationStatusPageController(
        readRegistrationStatusUseCase: readRegistrationStatusUseCase,
        initialToken: initialToken,
      ),
      child: const _RegistrationStatusPageBody(),
    );
  }
}

class _RegistrationStatusPageBody extends StatefulWidget {
  const _RegistrationStatusPageBody();

  @override
  State<_RegistrationStatusPageBody> createState() =>
      _RegistrationStatusPageBodyState();
}

class _RegistrationStatusPageBodyState
    extends State<_RegistrationStatusPageBody> {
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    final initialToken = context.read<RegistrationStatusPageController>().token;
    _tokenController = TextEditingController(text: initialToken);
    if (initialToken.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          context.read<RegistrationStatusPageController>().loadStatus(),
        );
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegistrationStatusPageController>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final theme = Theme.of(context);
    final status = controller.status;

    return Scaffold(
      body: AppHexScreenBody(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.authLoginScrollPaddingHorizontal,
            vertical: tokens.authLoginScrollPaddingVertical,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.authLoginContentMaxWidth,
              ),
              child: Column(
                children: <Widget>[
                  const LoginBrandHeader(),
                  SizedBox(height: tokens.authLoginGapBrandToForm),
                  LoginGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Consultar status do cadastro',
                          style: theme.textTheme.headlineSmall,
                        ),
                        SizedBox(height: tokens.gapSm),
                        Text(
                          'Se voce recebeu um token de aprovacao, informe-o '
                          'abaixo para verificar se o cadastro continua '
                          'pendente, '
                          'foi aprovado, rejeitado ou expirou.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: tokens.authLoginGapMajorSection),
                        AuthFormTextField(
                          controller: _tokenController,
                          label: 'Token do cadastro',
                          icon: Icons.vpn_key_outlined,
                          enabled: !controller.isLoading,
                          onFieldSubmitted: (_) {
                            controller.setToken(_tokenController.text);
                            unawaited(controller.loadStatus());
                          },
                        ),
                        SizedBox(height: tokens.gapSm),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: controller.isLoading
                                ? null
                                : () {
                                    controller.setToken(_tokenController.text);
                                    unawaited(controller.loadStatus());
                                  },
                            child: controller.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Consultar status'),
                          ),
                        ),
                        if (controller.errorMessage
                            case final String message) ...<Widget>[
                          SizedBox(height: tokens.contentSpacing),
                          InlineAlertBanner(message: message),
                        ],
                        if (status != null) ...<Widget>[
                          SizedBox(height: tokens.authLoginGapMajorSection),
                          _RegistrationStatusCard(status: status),
                        ],
                        SizedBox(height: tokens.authLoginGapMajorSection),
                        Wrap(
                          spacing: tokens.gapSm,
                          runSpacing: tokens.gapSm,
                          children: <Widget>[
                            OutlinedButton(
                              onPressed: () => context.goTo(AppRoute.login),
                              child: const Text('Ir para o login'),
                            ),
                            TextButton(
                              onPressed: () => context.goTo(AppRoute.register),
                              child: const Text('Criar novo cadastro'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.authLoginGapBeforeFooter),
                  const LoginFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationStatusCard extends StatelessWidget {
  const _RegistrationStatusCard({
    required this.status,
  });

  final ClientRegistrationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (icon, title, message, color) = switch (status) {
      ClientRegistrationStatus.pending => (
        Icons.hourglass_top_rounded,
        'Cadastro pendente',
        'Sua solicitacao ainda esta aguardando a aprovacao do responsavel.',
        colorScheme.primary,
      ),
      ClientRegistrationStatus.approved => (
        Icons.check_circle_outline_rounded,
        'Cadastro aprovado',
        'Seu cadastro ja pode acessar o login com o e-mail e senha informados.',
        colorScheme.tertiary,
      ),
      ClientRegistrationStatus.rejected => (
        Icons.cancel_outlined,
        'Cadastro rejeitado',
        'A solicitacao foi rejeitada. Revise os dados e envie um novo '
            'cadastro.',
        colorScheme.error,
      ),
      ClientRegistrationStatus.expired => (
        Icons.timer_off_outlined,
        'Cadastro expirado',
        'O token consultado expirou. Envie um novo cadastro para continuar.',
        colorScheme.error,
      ),
      ClientRegistrationStatus.unknown => (
        Icons.help_outline_rounded,
        'Status desconhecido',
        'Nao foi possivel classificar o status retornado pela API.',
        colorScheme.secondary,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
