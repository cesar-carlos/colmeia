import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/retry_client_registration_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:flutter/foundation.dart';

class RegistrationStatusPageController extends ChangeNotifier {
  RegistrationStatusPageController({
    required ReadRegistrationStatusUseCase readRegistrationStatusUseCase,
    required RetryClientRegistrationUseCase retryClientRegistrationUseCase,
    required AuthRegistrationPreferencesService preferencesService,
    String? initialToken,
  }) : _readRegistrationStatusUseCase = readRegistrationStatusUseCase,
       _retryClientRegistrationUseCase = retryClientRegistrationUseCase,
       _preferencesService = preferencesService,
       _token = initialToken?.trim() ?? '';

  static const Duration _minPollDelay = Duration(seconds: 2);
  static const Duration _maxPollDelay = Duration(seconds: 30);

  final ReadRegistrationStatusUseCase _readRegistrationStatusUseCase;
  final RetryClientRegistrationUseCase _retryClientRegistrationUseCase;
  final AuthRegistrationPreferencesService _preferencesService;

  String _token;
  ClientRegistrationStatus? _status;
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;
  bool _isRetrying = false;
  bool _showRetryForm = false;
  Timer? _pollTimer;
  int _pollAttempt = 0;
  bool _disposed = false;

  String get token => _token;
  ClientRegistrationStatus? get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  bool get showRetryForm => _showRetryForm;
  bool get hasResolvedStatus => _status != null;

  bool get canRetry =>
      _status == ClientRegistrationStatus.rejected ||
      _status == ClientRegistrationStatus.expired;

  Future<void> loadStoredPollToken() async {
    final stored = _preferencesService.readPollToken();
    if (stored == null || stored.isEmpty || _token.isNotEmpty) {
      return;
    }
    _token = stored;
    notifyListeners();
  }

  void setToken(String value) {
    _token = value.trim();
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void toggleRetryForm() {
    _showRetryForm = !_showRetryForm;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadStatus({
    required String emptyTokenMessage,
    required String invalidTokenMessage,
    required String Function(AppFailure failure) mapFailure,
    bool startPolling = true,
  }) async {
    final validationError = _validateToken(
      emptyTokenMessage: emptyTokenMessage,
      invalidTokenMessage: invalidTokenMessage,
    );
    if (validationError != null) {
      _stopPolling();
      _status = null;
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    await _fetchStatus(mapFailure: mapFailure);

    _isLoading = false;
    notifyListeners();

    if (startPolling) {
      _startPollingIfNeeded(mapFailure: mapFailure);
    }
  }

  Future<void> retryRegistration({
    required String ownerEmail,
    required String email,
    required String password,
    required String genericSuccessMessage,
    required String emptyTokenMessage,
    required String invalidTokenMessage,
    required String Function(AppFailure failure) mapFailure,
  }) async {
    _isRetrying = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _retryClientRegistrationUseCase(
      ownerEmail: ownerEmail.trim(),
      email: email.trim(),
      password: password,
    );

    String? retrySuccessMessage;
    result.fold(
      (message) {
        retrySuccessMessage = message.trim().isEmpty
            ? genericSuccessMessage
            : message;
        _showRetryForm = false;
        _errorMessage = null;
      },
      (failure) {
        _errorMessage = mapFailure(failure);
      },
    );

    _isRetrying = false;

    if (retrySuccessMessage != null && _token.isNotEmpty) {
      await _fetchStatus(mapFailure: mapFailure);
      _successMessage = retrySuccessMessage;
      _startPollingIfNeeded(mapFailure: mapFailure);
    } else if (retrySuccessMessage != null) {
      _successMessage = retrySuccessMessage;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }

  String? _validateToken({
    required String emptyTokenMessage,
    required String invalidTokenMessage,
  }) {
    if (_token.isEmpty) {
      return emptyTokenMessage;
    }
    if (_token.length < 32 || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(_token)) {
      return invalidTokenMessage;
    }
    return null;
  }

  Future<void> _fetchStatus({
    required String Function(AppFailure failure) mapFailure,
  }) async {
    final result = await _readRegistrationStatusUseCase(token: _token);
    result.fold(
      (resolvedStatus) {
        _status = resolvedStatus;
        _errorMessage = null;
        _showRetryForm = false;
        unawaited(_preferencesService.persistPollToken(_token));
      },
      (failure) {
        final statusCode = failure.context['statusCode'];
        if (statusCode == 429 && _status == ClientRegistrationStatus.pending) {
          _errorMessage = mapFailure(failure);
          return;
        }
        _status = null;
        _errorMessage = mapFailure(failure);
        _stopPolling();
      },
    );
  }

  void _startPollingIfNeeded({
    required String Function(AppFailure failure) mapFailure,
  }) {
    if (_status != ClientRegistrationStatus.pending || _token.isEmpty) {
      _stopPolling();
      return;
    }
    _pollAttempt = 0;
    _scheduleNextPoll(mapFailure: mapFailure);
  }

  void _scheduleNextPoll({
    required String Function(AppFailure failure) mapFailure,
  }) {
    _pollTimer?.cancel();
    final seconds = math.min(
      _minPollDelay.inSeconds * math.pow(2, _pollAttempt).toInt(),
      _maxPollDelay.inSeconds,
    );
    _pollTimer = Timer(Duration(seconds: seconds), () {
      if (_disposed) {
        return;
      }
      unawaited(_pollOnce(mapFailure: mapFailure));
    });
  }

  Future<void> _pollOnce({
    required String Function(AppFailure failure) mapFailure,
  }) async {
    if (_status != ClientRegistrationStatus.pending) {
      _stopPolling();
      return;
    }

    final result = await _readRegistrationStatusUseCase(token: _token);
    if (_disposed) {
      return;
    }

    result.fold(
      (resolvedStatus) {
        _status = resolvedStatus;
        _errorMessage = null;
        if (resolvedStatus == ClientRegistrationStatus.pending) {
          _pollAttempt++;
          _scheduleNextPoll(mapFailure: mapFailure);
        } else {
          _stopPolling();
        }
      },
      (failure) {
        final statusCode = failure.context['statusCode'];
        if (statusCode == 429) {
          _errorMessage = mapFailure(failure);
          _pollAttempt++;
          _scheduleNextPoll(mapFailure: mapFailure);
          return;
        }
        _errorMessage = mapFailure(failure);
        _stopPolling();
      },
    );
    notifyListeners();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollAttempt = 0;
  }
}
