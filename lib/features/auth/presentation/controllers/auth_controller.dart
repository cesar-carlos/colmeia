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
import 'package:result_dart/result_dart.dart';

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
  Future<void>? _signInFuture;
  Future<void>? _signOutFuture;
  int _sessionGeneration = 0;
  bool _disposed = false;
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
    if (_disposed ||
        event.type != AuthSessionEventType.invalidated ||
        _signOutFuture != null) {
      return;
    }
    _sessionGeneration++;
    if (!_presentation.isAuthenticated &&
        !_presentation.isRestoringSession &&
        !_presentation.isLoading) {
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
    if (_disposed) return;
    _presentation = _presentation.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    notifyListeners();
  }

  Future<void> initialize() {
    if (_disposed || _signOutFuture != null) return Future.value();
    AppLogger.debug(
      'Initializing authentication controller',
      context: const <String, Object?>{
        'operation': 'initializeAuthController',
      },
    );
    return _restoreSessionFuture ??= _restoreSession();
  }

  Future<void> _restoreSession() async {
    final generation = _sessionGeneration;
    _presentation = _presentation.copyWith(
      isRestoringSession: true,
      clearErrorMessage: true,
    );
    notifyListeners();

    if (!_isCurrent(generation)) return;
    final result = await Future.sync(_restoreSessionUseCase.call)
        .onError<Object>(
          (error, stack) => Failure<AuthSession, AppFailure>(
            mapToAppFailure(error, stackTrace: stack),
          ),
        );
    if (!_isCurrent(generation)) return;

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
  }) {
    if (_disposed || _signOutFuture != null) return Future.value();
    return _signInFuture ??= _signIn(
      email: email,
      password: password,
    ).whenComplete(() => _signInFuture = null);
  }

  Future<void> _signIn({
    required String email,
    required String password,
  }) async {
    final generation = _sessionGeneration;
    final restoreSessionFuture = _restoreSessionFuture;
    if (restoreSessionFuture != null) {
      await restoreSessionFuture;
    }
    if (!_isCurrent(generation)) return;

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

    if (!_isCurrent(generation)) return;
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

    final result =
        await Future.sync(
          () => _loginUseCase(email: authEmail.value, password: password),
        ).onError<Object>(
          (error, stack) => Failure<AuthSession, AppFailure>(
            mapToAppFailure(error, stackTrace: stack),
          ),
        );
    if (!_isCurrent(generation)) return;

    result.fold(
      (session) {
        unawaited(
          _registrationPreferencesService.clearPollToken().catchError((
            Object error,
            StackTrace stack,
          ) {
            AppLogger.warning(
              'Unable to clear registration poll token',
              error: error,
              stackTrace: stack,
            );
          }),
        );
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

  Future<void> signOut() {
    if (_disposed) return Future.value();
    return _signOutFuture ??= _signOut().whenComplete(
      () => _signOutFuture = null,
    );
  }

  Future<void> _signOut() async {
    final generation = ++_sessionGeneration;
    AppLogger.debug(
      'Starting sign out flow',
      context: const <String, Object?>{
        'operation': 'signOut',
      },
    );
    _presentation = _presentation.copyWith(
      clearSession: true,
      isLoading: true,
      isRestoringSession: false,
      clearSuccessMessage: true,
    );
    notifyListeners();

    // Let pending authentication writes finish before clearing persisted data.
    await _restoreSessionFuture;
    await _signInFuture;
    final result = await Future.sync(_logoutUseCase.call).onError<Object>(
      (error, stack) => Failure<Unit, AppFailure>(
        mapToAppFailure(error, stackTrace: stack),
      ),
    );
    if (!_isCurrent(generation)) return;
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
    _disposed = true;
    _sessionGeneration++;
    unawaited(_authSessionEventsSubscription.cancel());
    super.dispose();
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _sessionGeneration;

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
