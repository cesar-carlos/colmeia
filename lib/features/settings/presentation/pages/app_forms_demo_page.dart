import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/forms/app_checkbox_field.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_email_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_password_field.dart';
import 'package:colmeia/shared/widgets/forms/app_radio_group.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Interactive fake form using shared field widgets.
class AppFormsDemoPage extends StatefulWidget {
  const AppFormsDemoPage({super.key});

  @override
  State<AppFormsDemoPage> createState() => _AppFormsDemoPageState();
}

class _AppFormsDemoPageState extends State<AppFormsDemoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<DateTime?>> _referenceDateFieldKey =
      GlobalKey<FormFieldState<DateTime?>>();
  final GlobalKey<FormFieldState<DateTimeRange?>> _rangeFieldKey =
      GlobalKey<FormFieldState<DateTimeRange?>>();
  final GlobalKey<FormBuilderState> _formBuilderKey =
      GlobalKey<FormBuilderState>();

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
    final refDate = _referenceDateFieldKey.currentState?.value;
    final range = _rangeFieldKey.currentState?.value;
    final refLabel =
        refDate != null ? AppBrFormatters.shortDate(refDate) : '-';
    final rangeLabel = range != null
        ? '${AppBrFormatters.shortDate(range.start)} a '
            '${AppBrFormatters.shortDate(range.end)}'
        : '-';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Formulario valido (demo fake). Ref: $refLabel. '
          'Periodo: $rangeLabel.',
        ),
      ),
    );
  }

  void _submitFormBuilder() {
    final fb = _formBuilderKey.currentState;
    if (fb == null) {
      return;
    }
    if (!fb.saveAndValidate()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final d = fb.value['fb_date'] as DateTime?;
    final r = fb.value['fb_range'] as DateTimeRange?;
    final dLabel = d != null ? AppBrFormatters.shortDate(d) : '-';
    final rLabel = r != null
        ? '${AppBrFormatters.shortDate(r.start)} a '
            '${AppBrFormatters.shortDate(r.end)}'
        : '-';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'FormBuilder valido (demo fake). Data: $dLabel. '
          'Periodo: $rLabel.',
        ),
      ),
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
              'Validacao, estados habilitado/desabilitado, date pickers no '
              'Form, FormBuilder como nos relatorios e agrupamentos.',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSectionCardWithHeading(
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
              SizedBox(height: tokens.sectionSpacing),
              AppSectionCardWithHeading(
                title: 'Date pickers no Form',
                subtitle:
                    'Validacao ao enviar; limpe o campo e valide para ver '
                    'erro. Intervalo com datas explicitas na demo.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    FormField<DateTime?>(
                      key: _referenceDateFieldKey,
                      initialValue: DateTime(2026, 3, 30),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione a data de referencia.';
                        }
                        return null;
                      },
                      builder: (state) {
                        return AppDatePickerField(
                          label: 'Data de referencia',
                          helperText:
                              'Abre em bottom sheet com calendario estilizado.',
                          pickerTitle: 'Selecionar data de referencia',
                          value: state.value,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2027, 12, 31),
                          enabled: _fieldsEnabled,
                          errorText: state.errorText,
                          onChanged: state.didChange,
                        );
                      },
                    ),
                    SizedBox(height: tokens.gapMd),
                    FormField<DateTimeRange?>(
                      key: _rangeFieldKey,
                      initialValue: DateTimeRange(
                        start: DateTime(2026, 3),
                        end: DateTime(2026, 3, 30),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione o periodo de apuracao completo.';
                        }
                        return null;
                      },
                      builder: (state) {
                        return AppDateRangePickerField(
                          label: 'Periodo de apuracao',
                          helperText:
                              'Ideal para filtros e consultas analiticas.',
                          pickerTitle: 'Selecionar periodo',
                          value: state.value,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2027, 12, 31),
                          enabled: _fieldsEnabled,
                          errorText: state.errorText,
                          onChanged: state.didChange,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
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
        AppSectionCardWithHeading(
          title: 'FormBuilder + date pickers',
          subtitle:
              'Mesmos wrappers usados em relatorios parametrizados '
              '(AppFormBuilderDatePickerField).',
          child: FormBuilder(
            key: _formBuilderKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFormBuilderDatePickerField(
                  name: 'fb_date',
                  label: 'Data obrigatoria (FormBuilder)',
                  helperText: 'Validacao com form_builder_validators.',
                  pickerTitle: 'Selecionar data (FormBuilder)',
                  initialValue: DateTime(2026, 3, 15),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2027, 12, 31),
                  enabled: _fieldsEnabled,
                  validator: FormBuilderValidators.required(),
                ),
                SizedBox(height: tokens.gapMd),
                AppFormBuilderDateRangePickerField(
                  name: 'fb_range',
                  label: 'Periodo (FormBuilder)',
                  helperText: 'Opcional nesta demo.',
                  pickerTitle: 'Selecionar periodo (FormBuilder)',
                  initialValue: DateTimeRange(
                    start: DateTime(2026, 3),
                    end: DateTime(2026, 3, 20),
                  ),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2027, 12, 31),
                  enabled: _fieldsEnabled,
                ),
                SizedBox(height: tokens.gapMd),
                FilledButton.tonal(
                  onPressed: _fieldsEnabled ? _submitFormBuilder : null,
                  child: const Text('Validar FormBuilder'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        FilledButton(
          onPressed: _fieldsEnabled ? _submit : null,
          child: const Text('Validar envio (Form)'),
        ),
      ],
    );
  }
}
