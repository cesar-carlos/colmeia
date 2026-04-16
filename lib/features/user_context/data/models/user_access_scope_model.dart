import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

class UserAccessScopeModel {
  const UserAccessScopeModel({
    required this.allowedStores,
    required this.permissions,
    this.dashboardGrants = const <DashboardAccessGrant>[],
  });

  factory UserAccessScopeModel.fromJson(Map<String, dynamic> json) {
    return UserAccessScopeModel(
      allowedStores: _parseAllowedStores(json),
      permissions: _parsePermissions(json),
      dashboardGrants: _parseDashboardGrants(json),
    );
  }

  final List<StoreScope> allowedStores;
  final Set<UserPermission> permissions;
  final List<DashboardAccessGrant> dashboardGrants;

  UserAccessScope toEntity() {
    final resolvedPermissions = {...permissions};
    _grantBundledShellModules(resolvedPermissions);
    return UserAccessScope(
      allowedStores: allowedStores,
      permissions: resolvedPermissions,
      dashboardGrants: dashboardGrants,
    );
  }

  static List<StoreScope> _parseAllowedStores(Map<String, dynamic> json) {
    final rawStores =
        json['allowedStores'] as List<dynamic>? ??
        json['stores'] as List<dynamic>? ??
        json['storeScopes'] as List<dynamic>?;
    if (rawStores == null) {
      return const <StoreScope>[];
    }

    return rawStores
        .whereType<Map<String, dynamic>>()
        .map(
          (store) => StoreScope(
            id:
                (store['id'] as String?) ??
                (store['storeId'] as String?) ??
                (store['store_id'] as String?) ??
                '',
            name:
                (store['name'] as String?) ??
                (store['storeName'] as String?) ??
                (store['store_name'] as String?) ??
                (store['label'] as String?) ??
                '',
          ),
        )
        .where((store) => store.id.isNotEmpty && store.name.isNotEmpty)
        .toList(growable: false);
  }

  static Set<UserPermission> _parsePermissions(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'] as List<dynamic>?;
    if (rawPermissions != null) {
      final parsed = parseUserPermissionNameSet(
        rawPermissions.whereType<String>(),
      );
      _grantBundledShellModules(parsed);
      return parsed;
    }

    final permissions = <UserPermission>{};
    if (json['viewDashboard'] == true) {
      permissions.add(UserPermission.viewDashboard);
    }
    if (json['manageAgents'] == true ||
        json['viewAgents'] == true ||
        json['viewClientAgents'] == true) {
      permissions.add(UserPermission.manageAgents);
    }
    if (_parseDashboardGrants(json).isNotEmpty) {
      permissions.add(UserPermission.viewDashboard);
    }
    _grantBundledShellModules(permissions);
    return permissions;
  }

  /// Until the API exposes each shell module separately, grant placeholder
  /// modules when the user can use the overview or agent management.
  static void _grantBundledShellModules(Set<UserPermission> permissions) {
    if (permissions.contains(UserPermission.viewDashboard) ||
        permissions.contains(UserPermission.manageAgents)) {
      permissions.addAll(<UserPermission>{
        UserPermission.viewSales,
        UserPermission.viewReturns,
        UserPermission.viewFinance,
        UserPermission.viewPurchases,
        UserPermission.viewInventory,
      });
    }
  }

  static List<DashboardAccessGrant> _parseDashboardGrants(
    Map<String, dynamic> json,
  ) {
    final rawGrants =
        json['dashboardGrants'] as List<dynamic>? ??
        json['dashboardAccess'] as List<dynamic>?;
    if (rawGrants != null) {
      return rawGrants
          .map(
            (grant) => _dashboardGrantFromJson(grant as Map<String, dynamic>),
          )
          .toList(growable: false);
    }

    final rawAllowedIds = json['allowedDashboardIds'] as List<dynamic>?;
    if (rawAllowedIds == null) {
      return const <DashboardAccessGrant>[];
    }

    return rawAllowedIds
        .map(
          (id) => DashboardAccessGrant(
            dashboardId: id as String,
          ),
        )
        .toList(growable: false);
  }

  static DashboardAccessGrant _dashboardGrantFromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardAccessGrant(
      dashboardId: json['dashboardId'] as String,
      allowedFilterKeys: _parseStringSet(json['allowedFilterKeys']),
      allowedActions: _parseStringSet(json['allowedActions']),
    );
  }

  static Set<String> _parseStringSet(Object? value) {
    final rawValues = value as List<dynamic>?;
    if (rawValues == null) {
      return const <String>{};
    }

    return rawValues.map((entry) => entry as String).toSet();
  }
}
