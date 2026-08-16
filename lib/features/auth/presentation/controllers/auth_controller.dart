import 'dart:async';

import 'package:colmeia/app/authentication_gate.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/logging/log_redaction.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/state/auth_presentation_state.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier implements AuthenticationGate {
  AuthController({
    required this._loginUseCase,
    required this._logoutUseCase,
    required this._restoreSessionUseCase,
    required this._authSessionEvents,
    required this._registrationPreferencesService,
  }) {
    _authSessionEventsSubscription = _authSessionEvents.stream.listen(
      _handleAuthSessionEvent,
    );
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;
  final AuthSessionEvents _authSessionEvents;
  final AuthRegistrationPreferencesService _registrationPreferencesService;

  AuthPresentationState _presentation = const AuthPresentationState();
  Future<void>? _restoreSessionFuture;
  late final StreamSubscription<AuthSessionEvent>
  _authSessionEventsSubscription;

  AuthPresentationState get presentation => _presentation;

  @override
  bool get isAuthenticated => _presentation.isAuthenticated;
  AuthSession? get session => _presentation.session;
  bool get isLoading => _presentation.isLoading;
  bool get isRestoringSession => _presentation.isRestoringSession;
  String? get errorMessage => _presentation.errorMessage;
  String? get successMessage => _presentation.successMessage;

  void _handleAuthSessionEvent(AuthSessionEvent event) {
    if (event.type != AuthSessionEventType.invalidated ||
        !_presentation.isAuthenticated) {
      return;
    }

    _presentation = _presentation.copyWith(
      clearSession: true,
      isLoading: false,
      isRestoringSession: false,
      errorMessage: 'Sua sessao expirou. Entre novamente.',
      clearSuccessMessage: true,
    );
    notifyListeners();
  }

  void clearTransientFeedback() {
    _presentation = _presentation.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    notifyListeners();
  }

  Future<void> initialize() {
    AppLogger.debug(
      'Initializing authentication controller',
      context: const <String, Object?>{
        'operation': 'initializeAuthController',
      },
    );
    return _restoreSessionFuture ??= _restoreSession();
  }

  Future<void> _restoreSession() async {
    _presentation = _presentation.copyWith(
      isRestoringSession: true,
      clearErrorMessage: true,
    );
    notifyListeners();

    final result = await _restoreSessionUseCase();

    result.fold(
      (session) {
        _presentation = _presentation.copyWith(
          session: session,
          isRestoringSession: false,
          clearErrorMessage: true,
        );
        AppLogger.info(
          'Session restored in controller',
          context: <String, Object?>{
            'operation': 'restoreSession',
            'userId': session.userId,
          },
        );
      },
      (failure) {
        _presentation = _presentation.copyWith(
          clearSession: true,
          isRestoringSession: false,
          clearErrorMessage: true,
        );
        AppLogger.debug(
          'No active session restored in controller',
          context: <String, Object?>{
            'operation': 'restoreSession',
            'reason': failure.message,
          },
        );
      },
    );

    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final restoreSessionFuture = _restoreSessionFuture;
    if (restoreSessionFuture != null) {
      await restoreSessionFuture;
    }

    AppLogger.debug(
      'Starting sign in flow',
      context: <String, Object?>{
        'operation': 'signIn',
        'email': LogRedaction.redactEmail(email),
      },
    );
    _presentation = _presentation.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    notifyListeners();

    final authEmail = _parseEmailAddress(
      email,
      operation: 'signIn',
      field: 'email',
    );
    if (authEmail == null) {
      _presentation = _presentation.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    final result = await _loginUseCase(
      email: authEmail.value,
      password: password,
    );

    result.fold(
      (session) {
        unawaited(_registrationPreferencesService.clearPollToken());
        _presentation = _presentation.copyWith(
          session: session,
          clearErrorMessage: true,
          clearSuccessMessage: true,
        );
        AppLogger.info(
          'User authenticated in controller',
          context: <String, Object?>{
            'operation': 'signIn',
            'userId': session.userId,
          },
        );
      },
      (failure) {
        _presentation = _presentation.copyWith(
          clearSession: true,
          errorMessage: failure.displayMessage,
          clearSuccessMessage: true,
        );
        AppLogger.warning(
          'Sign in failed in controller',
          context: <String, Object?>{
            'operation': 'signIn',
            'email': LogRedaction.redactEmail(email),
          },
        );
      },
    );

    _presentation = _presentation.copyWith(isLoading: false);
    notifyListeners();
  }

  Future<void> signOut() async {
    AppLogger.debug(
      'Starting sign out flow',
      context: const <String, Object?>{
        'operation': 'signOut',
      },
    );
    _presentation = _presentation.copyWith(
      isLoading: true,
      clearSuccessMessage: true,
    );
    notifyListeners();

    final result = await _logoutUseCase();
    result.fold(
      (_) {
        _presentation = _presentation.copyWith(
          clearSession: true,
          isLoading: false,
          clearErrorMessage: true,
          clearSuccessMessage: true,
        );
        AppLogger.info(
          'User signed out in controller',
          context: const <String, Object?>{
            'operation': 'signOut',
          },
        );
      },
      (failure) {
        _presentation = _presentation.copyWith(
          isLoading: false,
          errorMessage: failure.displayMessage,
        );
        AppLogger.warning(
          'Sign out failed in controller',
          context: const <String, Object?>{
            'operation': 'signOut',
          },
        );
      },
    );

    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSessionEventsSubscription.cancel());
    super.dispose();
  }

  EmailAddress? _parseEmailAddress(
    String email, {
    required String operation,
    required String field,
  }) {
    try {
      return EmailAddress(email);
    } on Exception catch (error, stackTrace) {
      _presentation = _presentation.copyWith(
        clearSession: operation == 'signIn',
        errorMessage: mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to validate e-mail',
          fallbackUserMessage: 'Informe um e-mail valido para continuar.',
          context: <String, Object?>{
            'operation': operation,
            'field': field,
          },
        ).displayMessage,
        clearSuccessMessage: true,
      );
      AppLogger.warning(
        'Invalid e-mail provided for $operation',
        context: <String, Object?>{
          'operation': operation,
          'field': field,
          'email': LogRedaction.redactEmail(email),
        },
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
