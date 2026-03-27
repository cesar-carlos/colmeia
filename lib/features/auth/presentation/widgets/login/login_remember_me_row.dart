import 'package:colmeia/shared/widgets/forms/app_checkbox_field.dart';
import 'package:flutter/material.dart';

class LoginRememberMeRow extends StatelessWidget {
  const LoginRememberMeRow({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.primary;
            }
            return null;
          }),
        ),
      ),
      child: AppCheckboxField(
        value: value,
        onChanged: onChanged,
        label: 'Manter conectado',
        semanticLabel: 'Manter conectado',
      ),
    );
  }
}
