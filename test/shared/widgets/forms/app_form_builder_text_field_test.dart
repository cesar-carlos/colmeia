import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_text_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should build FormBuilderTextField inside FormBuilder', (
    tester,
  ) async {
    final formKey = GlobalKey<FormBuilderState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FormBuilder(
            key: formKey,
            child: const AppFormBuilderTextField(
              name: 'q',
              label: 'Busca',
              density: AppTextFieldDensity.compact,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FormBuilderTextField), findsOneWidget);
    expect(find.text('Busca'), findsOneWidget);
  });
}
