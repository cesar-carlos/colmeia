import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:flutter/foundation.dart';

@immutable
class AuthPresentationState {
  const AuthPresentationState({
    this.session,
    this.isLoading = false,
    this.isRestoringSession = false,
    this.errorMessage,
    this.successMessage,
    this.registrationSubmission,
  });

  final AuthSession? session;
  final bool isLoading;
  final bool isRestoringSession;
  final String? errorMessage;
  final String? successMessage;
  final ClientRegistrationSubmission? registrationSubmission;

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
    ClientRegistrationSubmission? registrationSubmission,
    bool clearRegistrationSubmission = false,
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
      registrationSubmission: clearRegistrationSubmission
          ? null
          : (registrationSubmission ?? this.registrationSubmission),
    );
  }
}
