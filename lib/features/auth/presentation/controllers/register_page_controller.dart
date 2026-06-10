import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/logging/log_redaction.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:flutter/foundation.dart';

class RegisterPageController extends ChangeNotifier {
  RegisterPageController({
    required RegisterUseCase registerUseCase,
    required AuthRegistrationPreferencesService preferencesService,
  }) : _registerUseCase = registerUseCase,
       _preferencesService = preferencesService;

  final RegisterUseCase _registerUseCase;
  final AuthRegistrationPreferencesService _preferencesService;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  ClientRegistrationSubmission? _submission;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  ClientRegistrationSubmission? get submission => _submission;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void clearTransientFeedback() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearSubmission() {
    _submission = null;
    notifyListeners();
  }

  Future<void> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String genericSuccessMessage,
    required String invalidEmailMessage,
    required String Function(AppFailure failure) mapFailure,
    String? mobile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _submission = null;
    notifyListeners();

    final ownerAuthEmail = _parseEmailAddress(
      ownerEmail,
      invalidEmailMessage: invalidEmailMessage,
    );
    if (ownerAuthEmail == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final authEmail = _parseEmailAddress(
      email,
      invalidEmailMessage: invalidEmailMessage,
    );
    if (authEmail == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final result = await _registerUseCase(
      ownerEmail: ownerAuthEmail.value,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: authEmail.value,
      password: password,
      mobile: mobile?.trim().isEmpty ?? true ? null : mobile?.trim(),
    );

    await result.fold(
      (submission) async {
        _submission = submission;
        _successMessage = submission.message ?? genericSuccessMessage;
        _errorMessage = null;
        if (submission.canPollStatus) {
          await _preferencesService.persistPollToken(submission.pollToken!);
        }
      },
      (failure) async {
        _submission = null;
        _successMessage = null;
        _errorMessage = mapFailure(failure);
        AppLogger.warning(
          'Register flow failed in controller',
          context: <String, Object?>{
            'operation': 'register',
            'ownerEmail': LogRedaction.redactEmail(ownerEmail),
            'email': LogRedaction.redactEmail(email),
          },
        );
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  EmailAddress? _parseEmailAddress(
    String email, {
    required String invalidEmailMessage,
  }) {
    try {
      return EmailAddress(email);
    } on Exception {
      _errorMessage = invalidEmailMessage;
      return null;
    }
  }
}
