import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFormValidators', () {
    test('should validate e-mail with value object rules', () {
      expect(
        AppFormValidators.email('invalid-email'),
        'Informe um e-mail valido.',
      );
      expect(AppFormValidators.email(' camila@example.com '), isNull);
    });

    test('should validate required and min password length', () {
      expect(AppFormValidators.password(null), 'Informe a senha');
      expect(
        AppFormValidators.password('123'),
        'A senha deve ter pelo menos 6 caracteres.',
      );
      expect(AppFormValidators.password('123456'), isNull);
    });

    test('should validate confirm password against source password', () {
      expect(
        AppFormValidators.confirmPassword(
          '123456',
          password: 'abcdef',
        ),
        'As senhas nao conferem.',
      );
      expect(
        AppFormValidators.confirmPassword(
          '123456',
          password: '123456',
        ),
        isNull,
      );
    });
  });
}
