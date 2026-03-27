import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:flutter/foundation.dart';

@immutable
class AuthPresentationState {
  const AuthPresentationState({
    this.session,
    this.isLoading = false,
    this.isRestoringSession = false,
    this.errorMessage,
    this.successMessage,
  });

  final AuthSession? session;
  final bool isLoading;
  final bool isRestoringSession;
  final String? errorMessage;
  final String? successMessage;

  bool get isAuthenticated => session != null;

  AuthPresentationState copyWith({
    AuthSession? session,
    bool clearSession = false,
    bool? isLoading,
    bool? isRestoringSession,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return AuthPresentationState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
