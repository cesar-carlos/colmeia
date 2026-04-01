import 'package:colmeia/features/user_context/data/models/user_access_scope_model.dart';
import 'package:colmeia/features/user_context/data/models/user_profile_model.dart';
import 'package:colmeia/features/user_context/domain/entities/access/dashboard_access_grant.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_context.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';

class CurrentUserContextModel {
  const CurrentUserContextModel({
    required this.profile,
    required this.access,
    required this.activeStoreId,
  });

  factory CurrentUserContextModel.fromJson(Map<String, dynamic> json) {
    return CurrentUserContextModel(
      profile: UserProfileModel.fromJson(json),
      access: UserAccessScopeModel.fromJson(json),
      activeStoreId: json['activeStoreId'] as String,
    );
  }

  final UserProfileModel profile;
  final UserAccessScopeModel access;
  final String activeStoreId;

  String get userId => profile.id;
  String get name => profile.name;
  String get roleLabel => profile.roleLabel;
  String get corporateEmail => profile.corporateEmail;
  String get phone => profile.phone;
  List<StoreScope> get allowedStores => access.allowedStores;
  Set<UserPermission> get permissions => access.permissions;
  List<DashboardAccessGrant> get dashboardGrants => access.dashboardGrants;

  CurrentUserContext toEntity({String? persistedActiveStoreId}) {
    return CurrentUserContext(
      scope: CurrentUserScope(
        profile: profile.toEntity(),
        access: access.toEntity(),
      ),
      activeStoreId: persistedActiveStoreId ?? activeStoreId,
    );
  }
}
