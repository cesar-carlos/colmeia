import 'dart:convert';

import 'package:colmeia/core/storage/session_storage.dart';
import 'package:colmeia/features/user_context/domain/entities/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/report_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

final class FakeIdentityBackendStore {
  FakeIdentityBackendStore(this._sessionStorage);

  static const String _usersStorageKey = 'fake_backend_users_v1';

  final SessionStorage _sessionStorage;

  Future<List<FakeIdentityUserRecord>> loadUsers() async {
    final raw = await _sessionStorage.read(_usersStorageKey);
    if (raw == null || raw.isEmpty) {
      final defaultUsers = _defaultUsers;
      await _saveUsers(defaultUsers);
      return defaultUsers;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (entry) => FakeIdentityUserRecord.fromJson(
            entry as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<FakeIdentityUserRecord?> findByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await loadUsers();
    return users.where((user) => user.email == normalizedEmail).firstOrNull;
  }

  Future<FakeIdentityUserRecord?> findById(String userId) async {
    final users = await loadUsers();
    return users.where((user) => user.id == userId).firstOrNull;
  }

  Future<FakeIdentityUserRecord> register({
    required String fullName,
    required String email,
    required String storeName,
    required String password,
  }) async {
    final users = await loadUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final existingUser = users
        .where((user) => user.email == normalizedEmail)
        .firstOrNull;
    if (existingUser != null) {
      throw const FakeBackendConflictException('User already exists');
    }

    final createdUser = FakeIdentityUserRecord(
      id: 'user-${users.length + 1}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      password: password,
      roleLabel: 'Gestor de loja',
      allowedStores: <StoreScope>[
        StoreScope(id: 'store-${users.length + 1}', name: storeName.trim()),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
        UserPermission.viewReports,
      },
      dashboardGrants: const <DashboardAccessGrant>[
        DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      reportGrants: const <ReportAccessGrant>[
        ReportAccessGrant(
          reportId: 'sales_overview',
          allowedFilterKeys: <String>{
            'store',
            'seller',
            'referenceDate',
            'onlyPositiveMargin',
          },
        ),
      ],
      activeStoreId: 'store-${users.length + 1}',
    );

    final updatedUsers = <FakeIdentityUserRecord>[...users, createdUser];
    await _saveUsers(updatedUsers);
    return createdUser;
  }

  Future<FakeIdentityUserRecord> validateCredentials({
    required String email,
    required String password,
  }) async {
    final user = await findByEmail(email);
    if (user == null || user.password != password) {
      throw const FakeBackendUnauthorizedException('Invalid credentials');
    }

    return user;
  }

  Future<void> updateActiveStore({
    required String userId,
    required String storeId,
  }) async {
    final users = await loadUsers();
    final updatedUsers = users.map((user) {
      if (user.id != userId) {
        return user;
      }
      return user.copyWith(activeStoreId: storeId);
    }).toList();
    await _saveUsers(updatedUsers);
  }

  Future<void> _saveUsers(List<FakeIdentityUserRecord> users) {
    final encoded = jsonEncode(
      users.map((user) => user.toJson()).toList(),
    );
    return _sessionStorage.write(key: _usersStorageKey, value: encoded);
  }

  List<FakeIdentityUserRecord> get _defaultUsers => <FakeIdentityUserRecord>[
    const FakeIdentityUserRecord(
      id: 'demo-user',
      fullName: 'Camila Oliveira',
      email: 'camila@example.com',
      password: '123456',
      roleLabel: 'Gerente regional',
      allowedStores: <StoreScope>[
        StoreScope(id: '03', name: 'Loja Centro'),
        StoreScope(id: '08', name: 'Loja Norte'),
        StoreScope(id: '14', name: 'Loja Sul'),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
        UserPermission.viewReports,
      },
      dashboardGrants: <DashboardAccessGrant>[
        DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      reportGrants: <ReportAccessGrant>[
        ReportAccessGrant(
          reportId: 'sales_overview',
          allowedFilterKeys: <String>{
            'store',
            'seller',
            'referenceDate',
            'onlyPositiveMargin',
          },
        ),
        ReportAccessGrant(
          reportId: 'margin_audit',
          allowedFilterKeys: <String>{
            'store',
            'seller',
            'referenceDate',
            'onlyPositiveMargin',
          },
        ),
      ],
      activeStoreId: '03',
    ),
    const FakeIdentityUserRecord(
      id: 'store-manager',
      fullName: 'Bruno Martins',
      email: 'bruno@example.com',
      password: '123456',
      roleLabel: 'Gerente de loja',
      allowedStores: <StoreScope>[
        StoreScope(id: '08', name: 'Loja Norte'),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
        UserPermission.viewReports,
      },
      dashboardGrants: <DashboardAccessGrant>[
        DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      reportGrants: <ReportAccessGrant>[
        ReportAccessGrant(
          reportId: 'sales_overview',
          allowedFilterKeys: <String>{
            'store',
            'seller',
            'referenceDate',
            'onlyPositiveMargin',
          },
        ),
      ],
      activeStoreId: '08',
    ),
    const FakeIdentityUserRecord(
      id: 'ops-analyst',
      fullName: 'Amanda Souza',
      email: 'amanda@example.com',
      password: '123456',
      roleLabel: 'Analista operacional',
      allowedStores: <StoreScope>[
        StoreScope(id: '03', name: 'Loja Centro'),
        StoreScope(id: '14', name: 'Loja Sul'),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
      },
      dashboardGrants: <DashboardAccessGrant>[
        DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      reportGrants: <ReportAccessGrant>[],
      activeStoreId: '03',
    ),
  ];
}

final class FakeIdentityUserRecord {
  const FakeIdentityUserRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.roleLabel,
    required this.allowedStores,
    required this.permissions,
    required this.dashboardGrants,
    required this.reportGrants,
    required this.activeStoreId,
  });

  factory FakeIdentityUserRecord.fromJson(Map<String, dynamic> json) {
    return FakeIdentityUserRecord(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      roleLabel: json['roleLabel'] as String,
      allowedStores: (json['allowedStores'] as List<dynamic>)
          .map(
            (store) => StoreScope(
              id: (store as Map<String, dynamic>)['id'] as String,
              name: store['name'] as String,
            ),
          )
          .toList(),
      permissions: (json['permissions'] as List<dynamic>)
          .map(
            (permission) => UserPermission.values.byName(permission as String),
          )
          .toSet(),
      dashboardGrants:
          (json['dashboardGrants'] as List<dynamic>? ?? <dynamic>[])
              .map(
                (grant) {
                  final grantJson = grant as Map<String, dynamic>;
                  return DashboardAccessGrant(
                    dashboardId: grantJson['dashboardId'] as String,
                    allowedFilterKeys: _parseStringSet(
                      grantJson['allowedFilterKeys'],
                    ),
                    allowedActions: _parseStringSet(
                      grantJson['allowedActions'],
                    ),
                  );
                },
              )
              .toList(growable: false),
      reportGrants: (json['reportGrants'] as List<dynamic>? ?? <dynamic>[])
          .map(
            (grant) {
              final grantJson = grant as Map<String, dynamic>;
              return ReportAccessGrant(
                reportId: grantJson['reportId'] as String,
                allowedFilterKeys: _parseStringSet(
                  grantJson['allowedFilterKeys'],
                ),
                allowedActions: _parseStringSet(grantJson['allowedActions']),
              );
            },
          )
          .toList(growable: false),
      activeStoreId: json['activeStoreId'] as String,
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String password;
  final String roleLabel;
  final List<StoreScope> allowedStores;
  final Set<UserPermission> permissions;
  final List<DashboardAccessGrant> dashboardGrants;
  final List<ReportAccessGrant> reportGrants;
  final String activeStoreId;

  FakeIdentityUserRecord copyWith({
    String? activeStoreId,
  }) {
    return FakeIdentityUserRecord(
      id: id,
      fullName: fullName,
      email: email,
      password: password,
      roleLabel: roleLabel,
      allowedStores: allowedStores,
      permissions: permissions,
      dashboardGrants: dashboardGrants,
      reportGrants: reportGrants,
      activeStoreId: activeStoreId ?? this.activeStoreId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'roleLabel': roleLabel,
      'allowedStores': allowedStores
          .map(
            (store) => <String, Object?>{
              'id': store.id,
              'name': store.name,
            },
          )
          .toList(),
      'permissions': permissions.map((permission) => permission.name).toList(),
      'dashboardGrants': dashboardGrants
          .map(
            (grant) => <String, Object?>{
              'dashboardId': grant.dashboardId,
              'allowedFilterKeys': grant.allowedFilterKeys.toList(),
              'allowedActions': grant.allowedActions.toList(),
            },
          )
          .toList(growable: false),
      'reportGrants': reportGrants
          .map(
            (grant) => <String, Object?>{
              'reportId': grant.reportId,
              'allowedFilterKeys': grant.allowedFilterKeys.toList(),
              'allowedActions': grant.allowedActions.toList(),
            },
          )
          .toList(growable: false),
      'activeStoreId': activeStoreId,
    };
  }

  static Set<String> _parseStringSet(Object? value) {
    final rawValues = value as List<dynamic>? ?? <dynamic>[];
    return rawValues.map((entry) => entry as String).toSet();
  }
}

final class FakeBackendConflictException implements Exception {
  const FakeBackendConflictException(this.message);

  final String message;
}

final class FakeBackendUnauthorizedException implements Exception {
  const FakeBackendUnauthorizedException(this.message);

  final String message;
}
