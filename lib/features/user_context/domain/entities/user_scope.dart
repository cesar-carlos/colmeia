import 'package:colmeia/features/user_context/domain/entities/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/report_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

class UserScope {
  const UserScope({
    required this.userId,
    required this.name,
    required this.roleLabel,
    required this.allowedStores,
    required this.permissions,
    this.dashboardGrants = const <DashboardAccessGrant>[],
    this.reportGrants = const <ReportAccessGrant>[],
  });

  final String userId;
  final String name;
  final String roleLabel;
  final List<StoreScope> allowedStores;
  final Set<UserPermission> permissions;
  final List<DashboardAccessGrant> dashboardGrants;
  final List<ReportAccessGrant> reportGrants;

  bool canAccessStore(String storeId) {
    return allowedStores.any((store) => store.id == storeId);
  }

  bool hasAnyDashboardAccess() {
    if (dashboardGrants.isNotEmpty) {
      return true;
    }
    return permissions.contains(UserPermission.viewDashboard);
  }

  bool hasAnyReportAccess() {
    if (reportGrants.isNotEmpty) {
      return true;
    }
    return permissions.contains(UserPermission.viewReports);
  }

  bool canAccessDashboard(String dashboardId) {
    if (dashboardGrants.isEmpty) {
      return permissions.contains(UserPermission.viewDashboard);
    }

    return dashboardGrants.any((grant) => grant.dashboardId == dashboardId);
  }

  bool canAccessReport(String reportId) {
    if (reportGrants.isEmpty) {
      return permissions.contains(UserPermission.viewReports);
    }

    return reportGrants.any((grant) => grant.reportId == reportId);
  }

  Set<String> allowedReportFilterKeys(String reportId) {
    final grant = reportGrants
        .where((entry) => entry.reportId == reportId)
        .firstOrNull;
    if (grant == null) {
      return <String>{};
    }

    return grant.allowedFilterKeys;
  }

  Set<String> allowedDashboardFilterKeys(String dashboardId) {
    final grant = dashboardGrants
        .where((entry) => entry.dashboardId == dashboardId)
        .firstOrNull;
    if (grant == null) {
      return <String>{};
    }

    return grant.allowedFilterKeys;
  }
}
