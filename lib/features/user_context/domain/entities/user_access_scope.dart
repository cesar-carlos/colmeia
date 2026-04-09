import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

class UserAccessScope {
  const UserAccessScope({
    required this.allowedStores,
    required this.permissions,
    this.dashboardGrants = const <DashboardAccessGrant>[],
  });

  final List<StoreScope> allowedStores;
  final Set<UserPermission> permissions;
  final List<DashboardAccessGrant> dashboardGrants;

  bool canAccessStore(String storeId) {
    return allowedStores.any((store) => store.id == storeId);
  }

  bool hasAnyDashboardAccess() {
    if (dashboardGrants.isNotEmpty) {
      return true;
    }

    return permissions.contains(UserPermission.viewDashboard);
  }

  bool canAccessDashboard(String dashboardId) {
    if (dashboardGrants.isEmpty) {
      return permissions.contains(UserPermission.viewDashboard);
    }

    return dashboardGrants.any((grant) => grant.dashboardId == dashboardId);
  }

  Set<String> allowedOverviewFilterKeys(String dashboardId) {
    final grant = dashboardGrants
        .where((entry) => entry.dashboardId == dashboardId)
        .firstOrNull;
    if (grant == null) {
      return <String>{};
    }

    return grant.allowedFilterKeys;
  }
}
