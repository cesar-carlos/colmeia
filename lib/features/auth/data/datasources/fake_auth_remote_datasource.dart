import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:dio/dio.dart';

final class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource(this._fakeBackendStore, this._sessionAccessor);

  final FakeIdentityBackendStore _fakeBackendStore;
  final AuthSessionAccessor _sessionAccessor;
  final Map<String, String> _recoveryTokens = <String, String>{};

  @override
  Future<ClientRegistrationSubmission> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      await _fakeBackendStore.register(
        fullName: '$firstName $lastName'.trim(),
        email: email,
        password: password,
        employeeId: '',
        accessProfileLabel: 'Cliente vinculado',
        allowedStores: const <StoreScope>[
          StoreScope(id: 'client', name: 'Conta do cliente'),
        ],
      );
      return ClientRegistrationSubmission(
        status: ClientRegistrationStatus.pending,
        message: 'Cadastro enviado e aguardando aprovacao.',
        pollToken: 'fake-client-poll-${email.trim().toLowerCase()}',
      );
    } on FakeBackendConflictException {
      return const ClientRegistrationSubmission(
        status: ClientRegistrationStatus.pending,
        message:
            'If eligible, your registration request will be processed.',
      );
    }
  }

  @override
  Future<String> retryClientRegistration({
    required String ownerEmail,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'If eligible, a new approval request will be sent.';
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    try {
      final user = await _fakeBackendStore.validateCredentials(
        email: email,
        password: password,
      );

      return AuthSessionModel(
        userId: user.id,
        email: user.email,
        accessToken: 'fake-access-token-${user.id}',
        refreshToken: 'fake-refresh-token-${user.id}',
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        role: 'client',
        accountStatus: ClientAccountStatus.active,
      );
    } on FakeBackendUnauthorizedException catch (error) {
      throw DioException(
        requestOptions: RequestOptions(path: ClientAuthApiRoutes.login),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: ClientAuthApiRoutes.login),
          statusCode: 401,
        ),
        message: error.message,
      );
    }
  }

  @override
  Future<ClientRegistrationStatus> readRegistrationStatus({
    required String token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return ClientRegistrationStatus.pending;
  }

  @override
  Future<AuthSessionModel> refreshSession({
    required AuthSessionModel currentSession,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final userId = currentSession.refreshToken.replaceFirst(
      'fake-refresh-token-',
      '',
    );
    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ClientAuthApiRoutes.refresh),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: ClientAuthApiRoutes.refresh),
          statusCode: 401,
        ),
        message: 'Invalid refresh token',
      );
    }

    final refreshedAccessToken =
        'fake-access-token-${user.id}'
        '-${DateTime.now().millisecondsSinceEpoch}';

    return AuthSessionModel(
      userId: user.id,
      email: user.email,
      accessToken: refreshedAccessToken,
      refreshToken: 'fake-refresh-token-${user.id}',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      role: currentSession.role,
      accountStatus: currentSession.accountStatus,
    );
  }

  @override
  Future<void> logout({
    required String refreshToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<UserProfile> readCurrentUserProfile() async {
    final user = await _requireActiveUser(path: ClientAuthApiRoutes.me);
    return _toUserProfile(user);
  }

  @override
  Future<UserProfile> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? mobile,
    bool removeThumbnail = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final user = await _requireActiveUser(path: ClientAuthApiRoutes.me);
    final fullName = <String>[
      firstName ?? '',
      lastName ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    final updatedUser = await _fakeBackendStore.updateClientProfile(
      userId: user.id,
      fullName: fullName.isEmpty ? null : fullName,
      phone: mobile,
      clearThumbnail: removeThumbnail,
    );
    return _toUserProfile(updatedUser);
  }

  @override
  Future<UserProfile> uploadThumbnail({
    required String filePath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final user = await _requireActiveUser(path: ClientAuthApiRoutes.thumbnail);
    final updatedUser = await _fakeBackendStore.updateClientProfile(
      userId: user.id,
      thumbnailUrl:
          'https://plug-server.se7esistemassinop.com.br/uploads/'
          '${user.id}/thumbnail.webp',
    );
    return _toUserProfile(updatedUser);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final user = await _requireActiveUser(path: ClientAuthApiRoutes.password);
    try {
      await _fakeBackendStore.updatePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on FakeBackendUnauthorizedException catch (error) {
      throw DioException(
        requestOptions: RequestOptions(path: ClientAuthApiRoutes.password),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: ClientAuthApiRoutes.password),
          statusCode: 401,
        ),
        message: error.message,
      );
    }
  }

  @override
  Future<String> requestPasswordRecovery({
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final user = await _fakeBackendStore.findByEmail(email);
    if (user != null) {
      _recoveryTokens['fake-recovery-${user.id}'] = user.id;
    }
    return 'If the account exists, a password recovery email will be sent '
        'shortly.';
  }

  @override
  Future<ClientPasswordRecoveryStatus> readPasswordRecoveryStatus({
    required String token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (_recoveryTokens.containsKey(token)) {
      return ClientPasswordRecoveryStatus.pending;
    }

    throw DioException(
      requestOptions: RequestOptions(
        path: ClientAuthApiRoutes.passwordRecoveryStatus,
      ),
      type: DioExceptionType.badResponse,
      response: Response<void>(
        requestOptions: RequestOptions(
          path: ClientAuthApiRoutes.passwordRecoveryStatus,
        ),
        statusCode: 404,
      ),
      message: 'Recovery token not found',
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final userId = _recoveryTokens[token];
    if (userId == null) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ClientAuthApiRoutes.passwordRecoveryReset,
        ),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(
            path: ClientAuthApiRoutes.passwordRecoveryReset,
          ),
          statusCode: 404,
        ),
        message: 'Recovery token not found',
      );
    }

    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ClientAuthApiRoutes.passwordRecoveryReset,
        ),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(
            path: ClientAuthApiRoutes.passwordRecoveryReset,
          ),
          statusCode: 404,
        ),
        message: 'Client account not found',
      );
    }

    await _fakeBackendStore.updatePassword(
      userId: user.id,
      currentPassword: user.password,
      newPassword: newPassword,
    );
    _recoveryTokens.remove(token);
  }

  Future<FakeIdentityUserRecord> _requireActiveUser({
    required String path,
  }) async {
    final storedSession = await _sessionAccessor.read();
    if (storedSession == null) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(path: path),
          statusCode: 401,
        ),
        message: 'No active client session found',
      );
    }

    final user = await _fakeBackendStore.findById(storedSession.userId);
    if (user != null) {
      return user;
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response<void>(
        requestOptions: RequestOptions(path: path),
        statusCode: 404,
      ),
      message: 'Client profile not found',
    );
  }

  UserProfile _toUserProfile(FakeIdentityUserRecord user) {
    final parts = user.fullName
        .split(RegExp(r'\s+'))
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length < 2 ? '' : parts.skip(1).join(' ');

    return UserProfile(
      id: user.id,
      name: user.fullName,
      roleLabel: 'client (active)',
      corporateEmail: user.email,
      phone: user.phone,
      firstName: firstName,
      lastName: lastName,
      thumbnailUrl: user.thumbnailUrl.isEmpty ? null : user.thumbnailUrl,
    );
  }
}
