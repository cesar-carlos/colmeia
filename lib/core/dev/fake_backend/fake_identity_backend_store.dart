import 'dart:convert';

import 'package:colmeia/core/storage/session_storage.dart';
import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

final class FakeIdentityBackendStore {
  FakeIdentityBackendStore(this._sessionStorage);

  static const String _usersStorageKey = 'fake_backend_users_v2';

  static const String _legacyUsersStorageKey = 'fake_backend_users_v1';

  static const List<DashboardAccessGrant> _migrationDefaultDashboardGrants =
      <DashboardAccessGrant>[
        DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ];

  final SessionStorage _sessionStorage;

  Future<List<FakeIdentityUserRecord>> loadUsers() async {
    var raw = await _sessionStorage.read(_usersStorageKey);
    if (raw == null || raw.isEmpty) {
      final legacy = await _sessionStorage.read(_legacyUsersStorageKey);
      if (legacy != null && legacy.isNotEmpty) {
        raw = legacy;
        await _sessionStorage.write(
          key: _usersStorageKey,
          value: legacy,
        );
        await _sessionStorage.delete(_legacyUsersStorageKey);
      }
    }
    if (raw == null || raw.isEmpty) {
      final defaultUsers = _defaultUsers;
      await _saveUsers(defaultUsers);
      return defaultUsers;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final users = decoded
        .map(
          (entry) => FakeIdentityUserRecord.fromJson(
            entry as Map<String, dynamic>,
          ),
        )
        .toList();

    final migratedUsers = users.map(_migrateLegacyEmptyGrants).toList();
    if (users.any(_needsGrantMigration)) {
      await _saveUsers(migratedUsers);
    }
    return migratedUsers;
  }

  bool _needsGrantMigration(FakeIdentityUserRecord user) {
    return user.dashboardGrants.isEmpty &&
        user.permissions.contains(UserPermission.viewDashboard);
  }

  FakeIdentityUserRecord _migrateLegacyEmptyGrants(
    FakeIdentityUserRecord user,
  ) {
    if (!_needsGrantMigration(user)) {
      return user;
    }

    return FakeIdentityUserRecord(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      password: user.password,
      employeeId: user.employeeId,
      roleLabel: user.roleLabel,
      allowedStores: user.allowedStores,
      permissions: user.permissions,
      dashboardGrants:
          user.dashboardGrants.isEmpty &&
              user.permissions.contains(UserPermission.viewDashboard)
          ? List<DashboardAccessGrant>.from(_migrationDefaultDashboardGrants)
          : user.dashboardGrants,
      activeStoreId: user.activeStoreId,
      phone: user.phone,
    );
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
    required String password,
    required String employeeId,
    required String accessProfileLabel,
    required List<StoreScope> allowedStores,
  }) async {
    if (allowedStores.isEmpty) {
      throw ArgumentError.value(
        allowedStores,
        'allowedStores',
        'Fake register requires at least one store scope',
      );
    }

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
      employeeId: employeeId.trim(),
      roleLabel: accessProfileLabel,
      allowedStores: allowedStores,
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
      },
      dashboardGrants: const <DashboardAccessGrant>[
        DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      activeStoreId: allowedStores.first.id,
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

  Future<FakeIdentityUserRecord> updateClientProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? thumbnailUrl,
    bool clearThumbnail = false,
  }) async {
    final users = await loadUsers();
    final targetUser = users.where((user) => user.id == userId).firstOrNull;
    if (targetUser == null) {
      throw const FakeBackendUnauthorizedException('Client profile not found');
    }

    final updatedUser = targetUser.copyWith(
      fullName: fullName,
      phone: phone,
      thumbnailUrl: clearThumbnail ? '' : thumbnailUrl,
    );
    final updatedUsers = users
        .map((user) => user.id == userId ? updatedUser : user)
        .toList(growable: false);
    await _saveUsers(updatedUsers);
    return updatedUser;
  }

  Future<void> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final users = await loadUsers();
    final targetUser = users.where((user) => user.id == userId).firstOrNull;
    if (targetUser == null) {
      throw const FakeBackendUnauthorizedException('Client account not found');
    }
    if (targetUser.password != currentPassword) {
      throw const FakeBackendUnauthorizedException(
        'Current password is invalid',
      );
    }

    final updatedUser = targetUser.copyWith(password: newPassword);
    final updatedUsers = users
        .map((user) => user.id == userId ? updatedUser : user)
        .toList(growable: false);
    await _saveUsers(updatedUsers);
  }

  Future<void> _saveUsers(List<FakeIdentityUserRecord> users) {
    final encoded = jsonEncode(
      users.map((user) => user.toJson()).toList(),
    );
    return _sessionStorage.write(key: _usersStorageKey, value: encoded);
  }

  List<FakeIdentityUserRecord> get _defaultUsers => <FakeIdentityUserRecord>[
    FakeIdentityUserRecord(
      id: 'demo-user',
      fullName: 'Camila Oliveira',
      email: 'camila@example.com',
      password: '123456',
      employeeId: '',
      roleLabel: 'Gerente regional',
      allowedStores: <StoreScope>[
        const StoreScope(id: '03', name: 'Loja Centro'),
        const StoreScope(id: '08', name: 'Loja Norte'),
        const StoreScope(id: '14', name: 'Loja Sul'),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
      },
      dashboardGrants: <DashboardAccessGrant>[
        const DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      activeStoreId: '03',
      phone: '+55 (11) 98765-4321',
    ),
    FakeIdentityUserRecord(
      id: 'store-manager',
      fullName: 'Bruno Martins',
      email: 'bruno@example.com',
      password: '123456',
      employeeId: '',
      roleLabel: 'Gerente de loja',
      allowedStores: <StoreScope>[
        const StoreScope(id: '08', name: 'Loja Norte'),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
      },
      dashboardGrants: <DashboardAccessGrant>[
        const DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      activeStoreId: '08',
      phone: '+55 (11) 91234-5678',
    ),
    FakeIdentityUserRecord(
      id: 'ops-analyst',
      fullName: 'Amanda Souza',
      email: 'amanda@example.com',
      password: '123456',
      employeeId: '',
      roleLabel: 'Analista operacional',
      allowedStores: <StoreScope>[
        const StoreScope(id: '03', name: 'Loja Centro'),
        const StoreScope(id: '14', name: 'Loja Sul'),
      ],
      permissions: <UserPermission>{
        UserPermission.viewDashboard,
      },
      dashboardGrants: <DashboardAccessGrant>[
        const DashboardAccessGrant(
          dashboardId: 'dashboard_main',
          allowedFilterKeys: <String>{'store', 'referenceDate'},
        ),
      ],
      activeStoreId: '03',
      phone: '+55 (21) 99876-5432',
    ),
  ];
}

final class FakeIdentityUserRecord {
  FakeIdentityUserRecord({
    required String id,
    required String fullName,
    required String email,
    required String password,
    required String employeeId,
    required String roleLabel,
    required List<StoreScope> allowedStores,
    required Set<UserPermission> permissions,
    required List<DashboardAccessGrant> dashboardGrants,
    required String activeStoreId,
    String phone = '',
    String thumbnailUrl = '',
  }) : this._(
         id: id,
         profile: FakeIdentityUserProfileRecord(
           fullName: fullName,
           email: email,
           employeeId: employeeId,
           roleLabel: roleLabel,
           phone: phone,
            thumbnailUrl: thumbnailUrl,
         ),
         access: FakeIdentityUserAccessRecord(
           allowedStores: allowedStores,
           permissions: permissions,
           dashboardGrants: dashboardGrants,
         ),
         password: password,
         activeStoreId: activeStoreId,
       );

  FakeIdentityUserRecord._({
    required this.id,
    required this.profile,
    required this.access,
    required this.password,
    required this.activeStoreId,
  });

  factory FakeIdentityUserRecord.fromJson(Map<String, dynamic> json) {
    final profile = FakeIdentityUserProfileRecord.fromJson(json);
    final access = FakeIdentityUserAccessRecord.fromJson(json);

    return FakeIdentityUserRecord(
      id: json['id'] as String,
      fullName: profile.fullName,
      email: profile.email,
      password: json['password'] as String,
      employeeId: profile.employeeId,
      roleLabel: profile.roleLabel,
      allowedStores: access.allowedStores,
      permissions: access.permissions,
      dashboardGrants: access.dashboardGrants,
      activeStoreId: json['activeStoreId'] as String,
      phone: profile.phone,
    );
  }

  final String id;
  final FakeIdentityUserProfileRecord profile;
  final FakeIdentityUserAccessRecord access;
  final String password;
  final String activeStoreId;

  String get fullName => profile.fullName;
  String get email => profile.email;
  String get phone => profile.phone;
  String get employeeId => profile.employeeId;
  String get roleLabel => profile.roleLabel;
  String get thumbnailUrl => profile.thumbnailUrl;
  List<StoreScope> get allowedStores => access.allowedStores;
  Set<UserPermission> get permissions => access.permissions;
  List<DashboardAccessGrant> get dashboardGrants => access.dashboardGrants;

  FakeIdentityUserRecord copyWith({
    String? activeStoreId,
    String? fullName,
    String? password,
    String? phone,
    String? thumbnailUrl,
  }) {
    return FakeIdentityUserRecord(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      password: password ?? this.password,
      employeeId: employeeId,
      roleLabel: roleLabel,
      allowedStores: allowedStores,
      permissions: permissions,
      dashboardGrants: dashboardGrants,
      activeStoreId: activeStoreId ?? this.activeStoreId,
      phone: phone ?? this.phone,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      ...profile.toJson(),
      'password': password,
      ...access.toJson(),
      'activeStoreId': activeStoreId,
    };
  }
}

final class FakeIdentityUserProfileRecord {
  const FakeIdentityUserProfileRecord({
    required this.fullName,
    required this.email,
    required this.employeeId,
    required this.roleLabel,
    this.phone = '',
    this.thumbnailUrl = '',
  });

  factory FakeIdentityUserProfileRecord.fromJson(Map<String, dynamic> json) {
    return FakeIdentityUserProfileRecord(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      employeeId: json['employeeId'] as String? ?? '',
      roleLabel: json['roleLabel'] as String,
      phone: json['phone'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    );
  }

  final String fullName;
  final String email;
  final String employeeId;
  final String roleLabel;
  final String phone;
  final String thumbnailUrl;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'thumbnailUrl': thumbnailUrl,
      'employeeId': employeeId,
      'roleLabel': roleLabel,
    };
  }
}

final class FakeIdentityUserAccessRecord {
  const FakeIdentityUserAccessRecord({
    required this.allowedStores,
    required this.permissions,
    required this.dashboardGrants,
  });

  factory FakeIdentityUserAccessRecord.fromJson(Map<String, dynamic> json) {
    return FakeIdentityUserAccessRecord(
      allowedStores: (json['allowedStores'] as List<dynamic>)
          .map(
            (store) => StoreScope(
              id: (store as Map<String, dynamic>)['id'] as String,
              name: store['name'] as String,
            ),
          )
          .toList(),
      permissions: parseUserPermissionNameSet(
        (json['permissions'] as List<dynamic>).map((entry) => entry as String),
      ),
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
    );
  }

  final List<StoreScope> allowedStores;
  final Set<UserPermission> permissions;
  final List<DashboardAccessGrant> dashboardGrants;

  Map<String, Object?> toJson() {
    return <String, Object?>{
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
