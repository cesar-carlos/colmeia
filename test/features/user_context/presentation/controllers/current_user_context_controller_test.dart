import 'package:checks/checks.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/user_context/domain/entities/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_scope.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUserContextController', () {
    test('should resolve preferred store when it is allowed', () {
      final controller = CurrentUserContextController.seeded();

      final result = controller.resolveStore(
        preferredStoreId: StoreId('08'),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.id).equals('08');
    });

    test('should return failure when preferred store is outside scope', () {
      final controller = CurrentUserContextController.seeded();

      final result = controller.resolveStore(
        preferredStoreId: StoreId('99'),
      );

      check(result.isError()).isTrue();
      check(controller.errorMessage).equals(
        'A loja solicitada nao esta disponivel para este usuario.',
      );
    });

    test('should update active store when selection is valid', () {
      final controller = CurrentUserContextController(
        userScope: const UserScope(
          userId: 'test-user',
          name: 'Camila Nunes',
          roleLabel: 'Gerente regional',
          allowedStores: <StoreScope>[
            StoreScope(id: '03', name: 'Loja Centro'),
            StoreScope(id: '08', name: 'Loja Norte'),
          ],
          permissions: <UserPermission>{
            UserPermission.viewDashboard,
          },
        ),
        activeStoreId: '03',
      );

      final result = controller.selectStore('08');

      check(result.isSuccess()).isTrue();
      check(controller.activeStore.id).equals('08');
    });
  });
}
