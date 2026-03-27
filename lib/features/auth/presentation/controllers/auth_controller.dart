import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/state/auth_presentation_state.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RegisterUseCase registerUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _registerUseCase = registerUseCase,
       _restoreSessionUseCase = restoreSessionUseCase;

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RegisterUseCase _registerUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;

  AuthPresentationState _presentation = const AuthPresentationState();
  Future<void>? _restoreSessionFuture;

  AuthPresentationState get presentation => _presentation;

  bool get isAuthenticated => _presentation.isAuthenticated;
  AuthSession? get session => _presentation.session;
  bool get isLoading => _presentation.isLoading;
  bool get isRestoringSession => _presentation.isRestoringSession;
  String? get errorMessage => _presentation.errorMessage;
  String? get successMessage => _presentation.successMessage;

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
        'email': email,
      },
    );
    _presentation = _presentation.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    notifyListeners();

    final authEmail = _parseEmailAddress(email);
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
            'email': email,
          },
        );
      },
    );

    _presentation = _presentation.copyWith(isLoading: false);
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String employeeId,
    required String accessProfileLabel,
    required List<String> requestedStoreIds,
  }) async {
    AppLogger.debug(
      'Starting register flow',
      context: <String, Object?>{
        'operation': 'register',
        'email': email,
        'accessProfileLabel': accessProfileLabel,
        'requestedStoreCount': requestedStoreIds.length,
      },
    );

    _presentation = _presentation.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    notifyListeners();

    final authEmail = _parseEmailAddress(email);
    if (authEmail == null) {
      _presentation = _presentation.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    final result = await _registerUseCase(
      fullName: fullName.trim(),
      email: authEmail.value,
      password: password,
      employeeId: employeeId.trim(),
      accessProfileLabel: accessProfileLabel,
      requestedStoreIds: requestedStoreIds,
    );

    result.fold(
      (_) {
        _presentation = _presentation.copyWith(
          successMessage:
              'Solicitação enviada com sucesso. Aguarde a aprovação.',
          clearErrorMessage: true,
        );
      },
      (failure) {
        _presentation = _presentation.copyWith(
          clearSuccessMessage: true,
          errorMessage: failure.displayMessage,
        );
        AppLogger.warning(
          'Register flow failed in controller',
          context: <String, Object?>{
            'operation': 'register',
            'email': email,
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

  EmailAddress? _parseEmailAddress(String email) {
    try {
      return EmailAddress(email);
    } on Exception catch (error, stackTrace) {
      _presentation = _presentation.copyWith(
        clearSession: true,
        errorMessage: mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to validate e-mail',
          fallbackUserMessage: 'Informe um e-mail valido para continuar.',
          context: const <String, Object?>{
            'operation': 'signIn',
            'field': 'email',
          },
        ).displayMessage,
        clearSuccessMessage: true,
      );
      AppLogger.warning(
        'Invalid e-mail provided for sign in',
        context: <String, Object?>{
          'operation': 'signIn',
          'email': email,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
