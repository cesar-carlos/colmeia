import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/forms/registration_form_policy.dart';
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

    test('should validate registration password policy', () {
      expect(
        AppFormValidators.password(
          null,
          requiredMessage: 'Enter password',
        ),
        'Enter password',
      );
      expect(
        AppFormValidators.password(
          'short',
          tooShortMessage: (min) => 'Too short $min',
        ),
        'Too short 8',
      );
      expect(
        AppFormValidators.password(
          'alllowercase1',
          needsUppercaseMessage: 'Needs uppercase',
        ),
        'Needs uppercase',
      );
      expect(
        AppFormValidators.password(
          'NoNumbers',
          needsNumberMessage: 'Needs number',
        ),
        'Needs number',
      );
      expect(
        AppFormValidators.password('ValidPass1'),
        isNull,
      );
      expect(
        AppFormValidators.password(
          'a' * (RegistrationFormPolicy.passwordMaxLength + 1),
          tooLongMessage: 'Too long',
        ),
        'Too long',
      );
    });

    test('should validate optional brazilian mobile', () {
      expect(
        AppFormValidators.optionalBrazilianMobile(
          '',
          invalidMessage: 'Invalid mobile',
        ),
        isNull,
      );
      expect(
        AppFormValidators.optionalBrazilianMobile(
          '11888880000',
          invalidMessage: 'Invalid mobile',
        ),
        'Invalid mobile',
      );
      expect(
        AppFormValidators.optionalBrazilianMobile(
          '11999990000',
          invalidMessage: 'Invalid mobile',
        ),
        isNull,
      );
    });

    test('should validate registration poll token format', () {
      expect(
        AppFormValidators.registrationPollToken(
          'short',
          emptyMessage: 'Empty',
          invalidMessage: 'Invalid',
        ),
        'Invalid',
      );
      expect(
        AppFormValidators.registrationPollToken(
          'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr',
          emptyMessage: 'Empty',
          invalidMessage: 'Invalid',
        ),
        isNull,
      );
    });

    test('should validate employee id format', () {
      expect(AppFormValidators.employeeId(null), 'Informe a matrícula.');
      expect(AppFormValidators.employeeId(''), 'Informe a matrícula.');
      expect(AppFormValidators.employeeId('a'), 'Matrícula inválida.');
      expect(AppFormValidators.employeeId('ab 12'), isNotNull);
      expect(AppFormValidators.employeeId('AB-12'), isNull);
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
