import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/features/auth/data/models/client_auth_json_reader.dart';
import 'package:colmeia/features/auth/data/models/client_me_response_dto.dart';
import 'package:colmeia/features/user_context/data/models/current_user_context_model.dart';
import 'package:colmeia/features/user_context/data/models/user_access_scope_model.dart';
import 'package:colmeia/features/user_context/data/models/user_profile_model.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:dio/dio.dart';

// ignore: one_member_abstracts — explicit remote contract for fake vs API swap.
abstract interface class UserContextRemoteDataSource {
  Future<CurrentUserContextModel> loadUserContext({
    required String userId,
  });
}

class ApiUserContextRemoteDataSource implements UserContextRemoteDataSource {
  ApiUserContextRemoteDataSource(this._dio);

  static const String _clientScopeStoreId = 'client-account';

  final Dio _dio;

  @override
  Future<CurrentUserContextModel> loadUserContext({
    required String userId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAuthApiRoutes.me,
    );
    final responseBody = response.data;
    if (responseBody == null) {
      throw const FormatException('Current client profile response is null');
    }

    final payload = readWrappedPayload(
      responseBody,
      wrapperKeys: const <String>['data', 'profile'],
    );
    final accessPayload =
        readNestedMap(
          payload,
          const <String>['access', 'scope', 'userContext'],
        ) ??
        payload;
    final parsedAccess = UserAccessScopeModel.fromJson(accessPayload);
    final hasExplicitAccessData = _hasExplicitAccessData(accessPayload);
    final resolvedAccess = hasExplicitAccessData
        ? UserAccessScopeModel(
            allowedStores: parsedAccess.allowedStores.isEmpty
                ? const <StoreScope>[
                    StoreScope(
                      id: _clientScopeStoreId,
                      name: 'Conta do cliente',
                    ),
                  ]
                : parsedAccess.allowedStores,
            permissions: parsedAccess.permissions,
            dashboardGrants: parsedAccess.dashboardGrants,
          )
        : const UserAccessScopeModel(
            allowedStores: <StoreScope>[
              StoreScope(id: _clientScopeStoreId, name: 'Conta do cliente'),
            ],
            permissions: <UserPermission>{
              UserPermission.viewDashboard,
            },
          );
    final activeStoreId =
        (accessPayload['activeStoreId'] as String?) ??
        (accessPayload['active_store_id'] as String?) ??
        (resolvedAccess.allowedStores.firstOrNull?.id ?? _clientScopeStoreId);
    final profile = ClientMeResponseDto.fromJson(
      responseBody,
    ).user.toUserProfile();

    return CurrentUserContextModel(
      profile: UserProfileModel(
        id: profile.id,
        name: profile.name,
        roleLabel: profile.roleLabel,
        corporateEmail: profile.corporateEmail,
        phone: profile.phone,
        firstName: profile.firstName,
        lastName: profile.lastName,
        thumbnailUrl: profile.thumbnailUrl,
      ),
      access: resolvedAccess,
      activeStoreId: activeStoreId,
    );
  }

  bool _hasExplicitAccessData(Map<String, dynamic> json) {
    return json['allowedStores'] is List<dynamic> ||
        json['stores'] is List<dynamic> ||
        json['storeScopes'] is List<dynamic> ||
        json['permissions'] is List<dynamic> ||
        json['dashboardGrants'] is List<dynamic> ||
        json['dashboardAccess'] is List<dynamic> ||
        json['allowedDashboardIds'] is List<dynamic> ||
        json['viewDashboard'] is bool;
  }
}

class FakeUserContextRemoteDataSource implements UserContextRemoteDataSource {
  FakeUserContextRemoteDataSource(this._fakeBackendStore);

  final FakeIdentityBackendStore _fakeBackendStore;

  @override
  Future<CurrentUserContextModel> loadUserContext({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw const FormatException('Fake user context not found');
    }

    return CurrentUserContextModel(
      profile: UserProfileModel(
        id: user.id,
        name: user.fullName,
        roleLabel: user.roleLabel,
        corporateEmail: user.email,
        phone: user.phone,
        firstName: user.fullName.split(' ').first,
        lastName: user.fullName.split(' ').skip(1).join(' '),
        thumbnailUrl: user.thumbnailUrl.isEmpty ? null : user.thumbnailUrl,
      ),
      access: UserAccessScopeModel(
        allowedStores: user.allowedStores,
        permissions: user.permissions,
        dashboardGrants: user.dashboardGrants,
      ),
      activeStoreId: user.activeStoreId,
    );
  }
}
