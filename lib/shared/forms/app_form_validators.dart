import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';

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
    int minLength = 6,
  }) {
    final requiredValidation = requiredText(
      value,
      message: 'Informe a senha',
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    if (value!.length < minLength) {
      return 'A senha deve ter pelo menos $minLength caracteres.';
    }

    return null;
  }

  static String? confirmPassword(
    String? value, {
    required String password,
  }) {
    final requiredValidation = requiredText(
      value,
      message: 'Confirme sua senha.',
    );
    if (requiredValidation != null) {
      return requiredValidation;
    }

    if (value != password) {
      return 'As senhas nao conferem.';
    }

    return null;
  }
}
