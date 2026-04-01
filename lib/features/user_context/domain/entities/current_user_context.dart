import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';

class CurrentUserContext {
  const CurrentUserContext({
    required this.scope,
    required this.activeStoreId,
  });

  final CurrentUserScope scope;
  final String activeStoreId;

  CurrentUserScope get userScope => scope;
}
