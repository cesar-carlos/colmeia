import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/forms/app_checkbox_field.dart';
import 'package:colmeia/shared/widgets/forms/app_choice_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_email_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_password_field.dart';
import 'package:colmeia/shared/widgets/forms/app_radio_group.dart';
import 'package:colmeia/shared/widgets/forms/app_switch_field.dart';
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
  String _storeScope = 'matriz';
  String? _selectedHiveNode = 'alpha_core';
  List<String> _selectedTags = <String>['analytics', 'cloud'];

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
    final refLabel = refDate != null ? AppBrFormatters.shortDate(refDate) : '-';
    final rangeLabel = range != null
        ? '${AppBrFormatters.shortDate(range.start)} a '
              '${AppBrFormatters.shortDate(range.end)}'
        : '-';
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.formsDemoFormValidSnackbar(refLabel, rangeLabel)),
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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.formsDemoFormBuilderValidSnackbar(dLabel, rLabel)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

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
        _FormsShowcaseCard(
          fieldsEnabled: _fieldsEnabled,
          onChanged: (value) {
            setState(() {
              _fieldsEnabled = value;
            });
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Estado do formulario',
          subtitle: 'Desligue para inspecionar campos desabilitados.',
          child: AppSwitchField(
            label: 'Campos habilitados',
            helperText: 'Aplica o estado disabled em todos os exemplos abaixo.',
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
                title: l10n.formsDemoDatePickersFormTitle,
                subtitle: l10n.formsDemoDatePickersFormSubtitle,
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
            helperText: 'Envia alertas, resumos e atualizacoes de indicadores.',
            onChanged: (value) {
              setState(() {
                _newsletter = value ?? false;
              });
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppRadioGroup compacto',
          subtitle: 'Selecao unica no padrao inline do design system.',
          child: AppRadioGroup<String>(
            groupValue: _period,
            enabled: _fieldsEnabled,
            variant: AppRadioGroupVariant.compact,
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
                icon: Icons.today_outlined,
              ),
              AppRadioOption<String>(
                value: 'mensal',
                label: 'Mensal',
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
          title: 'AppChoiceChip',
          subtitle: 'Selecao pontual em chips para contexto, loja ou escopo.',
          child: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              AppChoiceChip(
                label: 'Matriz',
                selected: _storeScope == 'matriz',
                onSelected: _fieldsEnabled
                    ? () {
                        setState(() => _storeScope = 'matriz');
                      }
                    : null,
              ),
              AppChoiceChip(
                label: 'Loja Centro',
                selected: _storeScope == 'centro',
                onSelected: _fieldsEnabled
                    ? () {
                        setState(() => _storeScope = 'centro');
                      }
                    : null,
              ),
              AppChoiceChip(
                label: 'Loja Sul',
                selected: _storeScope == 'sul',
                onSelected: _fieldsEnabled
                    ? () {
                        setState(() => _storeScope = 'sul');
                      }
                    : null,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Dropdown menus',
          subtitle:
              'Selecao unica e multi-select search no mesmo padrao visual das '
              'referencias light/dark.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppDropdownField<String>(
                value: _selectedHiveNode,
                enabled: _fieldsEnabled,
                label: 'Standard Select',
                hintText: 'Select Hive Node...',
                options: const <AppDropdownOption<String>>[
                  AppDropdownOption(
                    value: 'alpha_core',
                    label: 'Alpha Core',
                  ),
                  AppDropdownOption(
                    value: 'delta_node',
                    label: 'Delta Node',
                  ),
                  AppDropdownOption(
                    value: 'sigma_grid',
                    label: 'Sigma Grid',
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedHiveNode = value);
                },
              ),
              SizedBox(height: tokens.gapMd),
              AppMultiSelectSearchField<String>(
                selectedValues: _selectedTags,
                enabled: _fieldsEnabled,
                label: 'Multi-Select Search',
                options: const <AppDropdownOption<String>>[
                  AppDropdownOption(
                    value: 'analytics',
                    label: 'Analytics',
                  ),
                  AppDropdownOption(
                    value: 'cloud',
                    label: 'Cloud',
                  ),
                  AppDropdownOption(
                    value: 'automation',
                    label: 'Automation',
                  ),
                  AppDropdownOption(
                    value: 'security',
                    label: 'Security',
                  ),
                ],
                onChanged: (values) {
                  setState(() => _selectedTags = values);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: l10n.formsDemoFormBuilderSectionTitle,
          subtitle: l10n.formsDemoFormBuilderSectionSubtitle,
          child: FormBuilder(
            key: _formBuilderKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFormBuilderDropdownField<String>(
                  name: 'fb_node',
                  label: 'Select node (FormBuilder)',
                  hintText: 'Select Hive Node...',
                  helperText: 'Selecao unica com o wrapper compartilhado.',
                  initialValue: 'delta_node',
                  enabled: _fieldsEnabled,
                  options: const <AppDropdownOption<String>>[
                    AppDropdownOption(
                      value: 'alpha_core',
                      label: 'Alpha Core',
                    ),
                    AppDropdownOption(
                      value: 'delta_node',
                      label: 'Delta Node',
                    ),
                    AppDropdownOption(
                      value: 'sigma_grid',
                      label: 'Sigma Grid',
                    ),
                  ],
                  validator: FormBuilderValidators.required(),
                ),
                SizedBox(height: tokens.gapMd),
                AppFormBuilderMultiSelectSearchField<String>(
                  name: 'fb_tags',
                  label: 'Tags (FormBuilder)',
                  helperText: 'Busca inline com chips removiveis.',
                  initialValue: const <String>['analytics'],
                  enabled: _fieldsEnabled,
                  options: const <AppDropdownOption<String>>[
                    AppDropdownOption(
                      value: 'analytics',
                      label: 'Analytics',
                    ),
                    AppDropdownOption(
                      value: 'cloud',
                      label: 'Cloud',
                    ),
                    AppDropdownOption(
                      value: 'automation',
                      label: 'Automation',
                    ),
                    AppDropdownOption(
                      value: 'security',
                      label: 'Security',
                    ),
                  ],
                ),
                SizedBox(height: tokens.gapMd),
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
                AppSecondaryButton(
                  variant: AppSecondaryButtonVariant.tonal,
                  onPressed: _fieldsEnabled ? _submitFormBuilder : null,
                  label: l10n.formsDemoValidateFormBuilderButton,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppPrimaryButton(
          onPressed: _fieldsEnabled ? _submit : null,
          label: l10n.formsDemoValidateFormSubmitButton,
        ),
      ],
    );
  }
}

class _FormsShowcaseCard extends StatelessWidget {
  const _FormsShowcaseCard({
    required this.fieldsEnabled,
    required this.onChanged,
  });

  final bool fieldsEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCardWithHeading(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing + tokens.gapSm,
      ),
      titleWidget: _FormsShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Campos base, seletores e wrappers de calendario no mesmo ritmo '
          'visual do sistema.',
      headingTrailing: const _FormsShowcaseBadge(),
      headingBottom: const _FormsShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: AppSwitchField(
        label: 'Campos habilitados',
        helperText: 'Ativa ou desativa toda a superficie de exemplos abaixo.',
        value: fieldsEnabled,
        onChanged: onChanged,
      ),
    );
  }
}

class _FormsShowcaseHeading extends StatelessWidget {
  const _FormsShowcaseHeading({required this.theme, required this.tokens});

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Field Library',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(Icons.tune_rounded, color: cs.primary, size: 18),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Shared Form Controls',
                style: theme.appTypography.sectionHeaderH2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormsShowcaseBadge extends StatelessWidget {
  const _FormsShowcaseBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 6),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          'Preview',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _FormsShowcaseLegend extends StatelessWidget {
  const _FormsShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _FormsShowcaseLegendChip(label: 'Input'),
        _FormsShowcaseLegendChip(label: 'Selection'),
        _FormsShowcaseLegendChip(label: 'Date'),
        _FormsShowcaseLegendChip(label: 'FormBuilder'),
      ],
    );
  }
}

class _FormsShowcaseLegendChip extends StatelessWidget {
  const _FormsShowcaseLegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
