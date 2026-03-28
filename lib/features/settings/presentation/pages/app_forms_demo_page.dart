import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/forms/app_checkbox_field.dart';
import 'package:colmeia/shared/widgets/forms/app_email_field.dart';
import 'package:colmeia/shared/widgets/forms/app_password_field.dart';
import 'package:colmeia/shared/widgets/forms/app_radio_group.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

/// Interactive fake form using shared field widgets.
class AppFormsDemoPage extends StatefulWidget {
  const AppFormsDemoPage({super.key});

  @override
  State<AppFormsDemoPage> createState() => _AppFormsDemoPageState();
}

class _AppFormsDemoPageState extends State<AppFormsDemoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;

  bool _obscurePassword = true;
  bool _newsletter = true;
  bool _fieldsEnabled = true;
  String _period = 'mensal';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Maria Silva');
    _emailController = TextEditingController(text: 'maria.silva@empresa.com');
    _passwordController = TextEditingController(text: 'SenhaFake123');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario valido (demo fake).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Formularios',
          title: 'Campos compartilhados',
          subtitle:
              'Validacao, estados habilitado/desabilitado e agrupamentos.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Estado do formulario',
          subtitle: 'Desligue para inspecionar campos desabilitados.',
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Campos habilitados'),
            value: _fieldsEnabled,
            onChanged: (value) {
              setState(() {
                _fieldsEnabled = value;
              });
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        Form(
          key: _formKey,
          child: AppSectionCardWithHeading(
            title: 'AppTextField, e-mail e senha',
            subtitle: 'Dados fake; enviar dispara validacao.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _nameController,
                  label: 'Nome completo',
                  hintText: 'Como no cadastro',
                  prefixIcon: Icons.person_outline_rounded,
                  enabled: _fieldsEnabled,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Informe pelo menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: tokens.gapMd),
                AppEmailField(
                  controller: _emailController,
                  label: 'E-mail corporativo',
                  enabled: _fieldsEnabled,
                  density: AppTextFieldDensity.compact,
                ),
                SizedBox(height: tokens.gapMd),
                AppPasswordField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  label: 'Senha',
                  enabled: _fieldsEnabled,
                ),
                SizedBox(height: tokens.gapMd),
                AppTextField(
                  controller: _notesController,
                  label: 'Observacoes',
                  hintText: 'Opcional',
                  maxLines: 3,
                  minLines: 2,
                  enabled: _fieldsEnabled,
                  density: AppTextFieldDensity.compact,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppCheckboxField',
          subtitle: 'Aceite ficticio.',
          child: AppCheckboxField(
            value: _newsletter,
            enabled: _fieldsEnabled,
            label: 'Receber resumo semanal por e-mail',
            onChanged: (value) {
              setState(() {
                _newsletter = value ?? false;
              });
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppRadioGroup',
          subtitle: 'Frequencia de relatorio fake.',
          child: AppRadioGroup<String>(
            groupValue: _period,
            enabled: _fieldsEnabled,
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  _period = value;
                }
              });
            },
            options: const <AppRadioOption<String>>[
              AppRadioOption<String>(
                value: 'diario',
                label: 'Diario',
                subtitle: 'Atualizado todo dia as 08h',
                icon: Icons.today_outlined,
              ),
              AppRadioOption<String>(
                value: 'mensal',
                label: 'Mensal',
                subtitle: 'Fechamento no ultimo dia util',
                icon: Icons.calendar_month_outlined,
              ),
              AppRadioOption<String>(
                value: 'trimestral',
                label: 'Trimestral',
                icon: Icons.date_range_outlined,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        FilledButton(
          onPressed: _fieldsEnabled ? _submit : null,
          child: const Text('Validar envio'),
        ),
      ],
    );
  }
}
