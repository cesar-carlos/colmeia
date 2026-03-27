import 'package:colmeia/features/auth/presentation/models/register_access_profile.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_form_section_title.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_radio_group.dart';
import 'package:flutter/material.dart';

class RegisterAccessProfileSection extends StatelessWidget {
  const RegisterAccessProfileSection({
    required this.groupValue,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final RegisterAccessProfile groupValue;
  final ValueChanged<RegisterAccessProfile?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RegisterFormSectionTitle(title: 'Perfil de acesso'),
        AppRadioGroup<RegisterAccessProfile>(
          groupValue: groupValue,
          onChanged: onChanged,
          enabled: enabled,
          options: RegisterAccessProfile.values
              .map(
                (p) => AppRadioOption<RegisterAccessProfile>(
                  value: p,
                  label: p.label,
                  icon: p.icon,
                ),
              )
              .toList(),
        ),
        SizedBox(height: tokens.sectionSpacing),
      ],
    );
  }
}
