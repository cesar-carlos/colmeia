import 'package:colmeia/features/user_context/domain/entities/user_scope.dart';

class UserContextSnapshot {
  const UserContextSnapshot({
    required this.userScope,
    required this.activeStoreId,
  });

  final UserScope userScope;
  final String activeStoreId;
}
