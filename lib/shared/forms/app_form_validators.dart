import 'package:colmeia/core/value_objects/brazilian_celular.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';
import 'package:colmeia/shared/forms/registration_form_policy.dart';

/// Reusable form validators aligned with [EmailAddress] and common UX copy.
abstract final class AppFormValidators {
  static String? requiredText(
    String? value, {
    required String message,
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  static String? personName(
    String? value, {
    required String requiredMessage,
    required String tooLongMessage,
    int maxLength = RegistrationFormPolicy.personNameMaxLength,
  }) {
    final requiredValidation = requiredText(
      value,
      message: requiredMessage,
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    if (value!.trim().length > maxLength) {
      return tooLongMessage;
    }

    return null;
  }

  static String? fullName(String? value) {
    final requiredValidation = requiredText(
      value,
      message: 'Informe seu nome completo.',
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    if (value!.trim().length < 3) {
      return 'Informe seu nome completo.';
    }

    return null;
  }

  static String? storeName(String? value) {
    return requiredText(
      value,
      message: 'Informe sua loja principal.',
    );
  }

  static String? employeeId(String? value) {
    final requiredValidation = requiredText(
      value,
      message: 'Informe a matrícula.',
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final trimmed = value!.trim();
    if (trimmed.length < 2) {
      return 'Matrícula inválida.';
    }

    final ok = RegExp(r'^[A-Za-z0-9\-.]+$').hasMatch(trimmed);
    if (!ok) {
      return 'Use apenas letras, números, hífen ou ponto.';
    }

    return null;
  }

  static String? email(
    String? value, {
    String emptyMessage = 'Informe o e-mail',
    String invalidMessage = 'Informe um e-mail valido.',
  }) {
    final requiredValidation = requiredText(
      value,
      message: emptyMessage,
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    try {
      EmailAddress(value!);
      return null;
    } on ValueObjectValidationException {
      return invalidMessage;
    }
  }

  static String? password(
    String? value, {
    int minLength = RegistrationFormPolicy.passwordMinLength,
    int maxLength = RegistrationFormPolicy.passwordMaxLength,
    String? requiredMessage,
    String? Function(int minLength)? tooShortMessage,
    String? tooLongMessage,
    String? needsUppercaseMessage,
    String? needsNumberMessage,
  }) {
    final requiredValidation = requiredText(
      value,
      message: requiredMessage ?? 'Informe a senha',
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final password = value!;
    if (password.length < minLength) {
      return tooShortMessage?.call(minLength) ??
          'A senha deve ter pelo menos $minLength caracteres.';
    }

    if (password.length > maxLength) {
      return tooLongMessage ??
          'A senha deve ter no maximo $maxLength caracteres.';
    }

    if (!RegExp('[A-Z]').hasMatch(password)) {
      return needsUppercaseMessage ??
          'A senha deve conter pelo menos uma letra maiuscula.';
    }

    if (!RegExp('[0-9]').hasMatch(password)) {
      return needsNumberMessage ?? 'A senha deve conter pelo menos um numero.';
    }

    return null;
  }

  static String? confirmPassword(
    String? value, {
    required String password,
    String? requiredMessage,
    String? mismatchMessage,
  }) {
    final requiredValidation = requiredText(
      value,
      message: requiredMessage ?? 'Confirme sua senha.',
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    if (value != password) {
      return mismatchMessage ?? 'As senhas nao conferem.';
    }

    return null;
  }

  static String? optionalBrazilianMobile(
    String? value, {
    required String invalidMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      BrazilianCelular(value);
      return null;
    } on ValueObjectValidationException {
      return invalidMessage;
    }
  }

  static String? registrationPollToken(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
    int minLength = RegistrationFormPolicy.pollTokenMinLength,
  }) {
    final requiredValidation = requiredText(
      value,
      message: emptyMessage,
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    final token = value!.trim();
    if (token.length < minLength ||
        !RegistrationFormPolicy.pollTokenPattern.hasMatch(token)) {
      return invalidMessage;
    }

    return null;
  }
}
