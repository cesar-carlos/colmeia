import 'package:colmeia/features/user_context/domain/entities/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/report_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_context_snapshot.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_scope.dart';

class UserContextModel {
  const UserContextModel({
    required this.userId,
    required this.name,
    required this.roleLabel,
    required this.allowedStores,
    required this.permissions,
    required this.activeStoreId,
    this.dashboardGrants = const <DashboardAccessGrant>[],
    this.reportGrants = const <ReportAccessGrant>[],
  });

  factory UserContextModel.fromJson(Map<String, dynamic> json) {
    final allowedStores = (json['allowedStores'] as List<dynamic>)
        .map(
          (store) => StoreScope(
            id: (store as Map<String, dynamic>)['id'] as String,
            name: store['name'] as String,
          ),
        )
        .toList(growable: false);
    final permissions = _parsePermissions(json);
    final dashboardGrants = _parseDashboardGrants(json);
    final reportGrants = _parseReportGrants(json);

    return UserContextModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      roleLabel: json['roleLabel'] as String,
      allowedStores: allowedStores,
      permissions: permissions,
      activeStoreId: json['activeStoreId'] as String,
      dashboardGrants: dashboardGrants,
      reportGrants: reportGrants,
    );
  }

  final String userId;
  final String name;
  final String roleLabel;
  final List<StoreScope> allowedStores;
  final Set<UserPermission> permissions;
  final String activeStoreId;
  final List<DashboardAccessGrant> dashboardGrants;
  final List<ReportAccessGrant> reportGrants;

  UserContextSnapshot toSnapshot({String? persistedActiveStoreId}) {
    return UserContextSnapshot(
      userScope: UserScope(
        userId: userId,
        name: name,
        roleLabel: roleLabel,
        allowedStores: allowedStores,
        permissions: permissions,
        dashboardGrants: dashboardGrants,
        reportGrants: reportGrants,
      ),
      activeStoreId: persistedActiveStoreId ?? activeStoreId,
    );
  }

  static Set<UserPermission> _parsePermissions(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'] as List<dynamic>?;
    if (rawPermissions != null) {
      return rawPermissions
          .map(
            (permission) => UserPermission.values.byName(permission as String),
          )
          .toSet();
    }

    final permissions = <UserPermission>{};
    if (_parseDashboardGrants(json).isNotEmpty) {
      permissions.add(UserPermission.viewDashboard);
    }
    if (_parseReportGrants(json).isNotEmpty) {
      permissions.add(UserPermission.viewReports);
    }
    return permissions;
  }

  static List<DashboardAccessGrant> _parseDashboardGrants(
    Map<String, dynamic> json,
  ) {
    final rawGrants = json['dashboardGrants'] as List<dynamic>?;
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

  static List<ReportAccessGrant> _parseReportGrants(Map<String, dynamic> json) {
    final rawGrants = json['reportGrants'] as List<dynamic>?;
    if (rawGrants != null) {
      return rawGrants
          .map((grant) => _reportGrantFromJson(grant as Map<String, dynamic>))
          .toList(growable: false);
    }

    final rawAllowedIds = json['allowedReportIds'] as List<dynamic>?;
    if (rawAllowedIds == null) {
      return const <ReportAccessGrant>[];
    }

    return rawAllowedIds
        .map(
          (id) => ReportAccessGrant(
            reportId: id as String,
          ),
        )
        .toList(growable: false);
  }

  static ReportAccessGrant _reportGrantFromJson(Map<String, dynamic> json) {
    return ReportAccessGrant(
      reportId: json['reportId'] as String,
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
