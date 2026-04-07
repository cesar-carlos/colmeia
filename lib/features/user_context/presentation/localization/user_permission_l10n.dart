import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/l10n/app_localizations.dart';

extension UserPermissionL10n on UserPermission {
  String displayLabel(AppLocalizations l10n) => switch (this) {
    UserPermission.viewDashboard => l10n.userPermissionViewDashboard,
    UserPermission.manageAgents => l10n.userPermissionManageAgents,
  };
}
