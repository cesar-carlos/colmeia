import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';

class AppShellUserSummary {
  const AppShellUserSummary({
    required this.name,
    required this.roleLabel,
    this.thumbnailUrl,
  });

  factory AppShellUserSummary.fromScope(CurrentUserScope scope) {
    return AppShellUserSummary(
      name: scope.name,
      roleLabel: scope.roleLabel,
      thumbnailUrl: scope.thumbnailUrl,
    );
  }

  final String name;
  final String roleLabel;
  final String? thumbnailUrl;
}

AppShellUserSummary selectAppShellUserSummary(
  CurrentUserContextController controller,
) {
  return AppShellUserSummary.fromScope(controller.userScope);
}
