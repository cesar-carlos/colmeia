import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/features/user_context/data/models/user_context_model.dart';
import 'package:dio/dio.dart';

// ignore: one_member_abstracts — explicit remote contract for fake vs API swap.
abstract interface class UserContextRemoteDataSource {
  Future<UserContextModel> loadUserContext({
    required String userId,
  });
}

class ApiUserContextRemoteDataSource implements UserContextRemoteDataSource {
  ApiUserContextRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<UserContextModel> loadUserContext({
    required String userId,
  }) async {
    final meResponse = await _dio.get<Map<String, dynamic>>('/me');
    final permissionsResponse = await _dio.get<List<dynamic>>(
      '/me/permissions',
    );
    final storesResponse = await _dio.get<List<dynamic>>('/me/stores');

    final me = meResponse.data;
    final permissions = permissionsResponse.data;
    final stores = storesResponse.data;

    if (me == null || permissions == null || stores == null) {
      throw const FormatException('User context response is incomplete');
    }

    final defaultStore = stores.first as Map<String, dynamic>;

    return UserContextModel.fromJson(
      <String, dynamic>{
        'userId': me['id'] ?? userId,
        'name': me['name'],
        'roleLabel': me['roleLabel'] ?? me['role'] ?? 'Usuario',
        'allowedStores': stores,
        'permissions': permissions,
        'dashboardGrants':
            me['dashboardGrants'] ??
            (me['allowedDashboardIds'] == null
                ? null
                : (me['allowedDashboardIds'] as List<dynamic>)
                      .map(
                        (dashboardId) => <String, Object?>{
                          'dashboardId': dashboardId,
                        },
                      )
                      .toList(growable: false)),
        'reportGrants':
            me['reportGrants'] ??
            (me['allowedReportIds'] == null
                ? null
                : (me['allowedReportIds'] as List<dynamic>)
                      .map(
                        (reportId) => <String, Object?>{
                          'reportId': reportId,
                        },
                      )
                      .toList(growable: false)),
        'activeStoreId': me['activeStoreId'] ?? defaultStore['id'],
      },
    );
  }
}

class FakeUserContextRemoteDataSource implements UserContextRemoteDataSource {
  FakeUserContextRemoteDataSource(this._fakeBackendStore);

  final FakeIdentityBackendStore _fakeBackendStore;

  @override
  Future<UserContextModel> loadUserContext({
    required String userId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final user = await _fakeBackendStore.findById(userId);
    if (user == null) {
      throw const FormatException('Fake user context not found');
    }

    return UserContextModel(
      userId: user.id,
      name: user.fullName,
      roleLabel: user.roleLabel,
      allowedStores: user.allowedStores,
      permissions: user.permissions,
      activeStoreId: user.activeStoreId,
      dashboardGrants: user.dashboardGrants,
      reportGrants: user.reportGrants,
    );
  }
}
