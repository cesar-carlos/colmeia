import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render TextFormField with label', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Nome',
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatorio' : null,
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('should use compact vertical padding when density is compact', (
    tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Campo',
            density: AppTextFieldDensity.compact,
          ),
        ),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byType(TextFormField),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(
      decorator.decoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    controller.dispose();
  });

  testWidgets('should not accept input when disabled', (tester) async {
    final controller = TextEditingController(text: 'x');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Somente leitura',
            enabled: false,
          ),
        ),
      ),
    );

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.enabled, isFalse);

    controller.dispose();
  });
}
