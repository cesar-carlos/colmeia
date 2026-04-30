import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_context.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLoadCurrentUserContextUseCase extends Mock
    implements LoadCurrentUserContextUseCase {}

class _MockPersistActiveStoreUseCase extends Mock
    implements PersistActiveStoreUseCase {}

class _MockClearActiveStoreUseCase extends Mock
    implements ClearActiveStoreUseCase {}

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
        userScope: const CurrentUserScope(
          profile: UserProfile(
            id: 'test-user',
            name: 'Camila Nunes',
            roleLabel: 'Gerente regional',
          ),
          access: UserAccessScope(
            allowedStores: <StoreScope>[
              StoreScope(id: '03', name: 'Loja Centro'),
              StoreScope(id: '08', name: 'Loja Norte'),
            ],
            permissions: <UserPermission>{
              UserPermission.viewDashboard,
            },
          ),
        ),
        activeStoreId: '03',
      );

      final result = controller.selectStore('08');

      check(result.isSuccess()).isTrue();
      check(controller.activeStore.id).equals('08');
    });

    test('should allow fullscreen chart route for authenticated context', () {
      final controller = CurrentUserContextController.seeded();

      check(controller.canAccessRoute(AppRoute.chartFullscreen)).isTrue();
    });

    test('should preserve scope while reloading user context', () async {
      final authController = _MockAuthController();
      final loadUseCase = _MockLoadCurrentUserContextUseCase();
      final persistUseCase = _MockPersistActiveStoreUseCase();
      final clearUseCase = _MockClearActiveStoreUseCase();
      final session = _session();

      when(() => authController.addListener(any())).thenReturn(null);
      when(() => authController.removeListener(any())).thenReturn(null);
      when(() => authController.session).thenReturn(session);
      when(
        () => loadUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => Success<CurrentUserContext, AppFailure>(
          _context(name: 'Camila Oliveira', activeStoreId: '03'),
        ),
      );

      final controller = CurrentUserContextController(
        authController: authController,
        loadCurrentUserContextUseCase: loadUseCase,
        persistActiveStoreUseCase: persistUseCase,
        clearActiveStoreUseCase: clearUseCase,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      final refreshCompleter = Completer<AppResult<CurrentUserContext>>();
      when(
        () => loadUseCase(userId: any(named: 'userId')),
      ).thenAnswer((_) => refreshCompleter.future);

      final refreshFuture = controller.reloadUserContext();
      await Future<void>.delayed(Duration.zero);

      check(controller.isRefreshing).isTrue();
      check(controller.isLoadingInitial).isFalse();
      check(controller.userScope.name).equals('Camila Oliveira');

      refreshCompleter.complete(
        const Failure<CurrentUserContext, AppFailure>(
          NetworkFailure(
            message: 'technical',
            userMessage: 'Nao foi possivel atualizar o perfil.',
          ),
        ),
      );

      await refreshFuture;

      check(controller.isRefreshing).isFalse();
      check(controller.userScope.name).equals('Camila Oliveira');
      check(controller.errorMessage).equals(
        'Nao foi possivel atualizar o perfil.',
      );
    });

    test(
      'should ignore stale reload when newer reload completes later',
      () async {
        final authController = _MockAuthController();
        final loadUseCase = _MockLoadCurrentUserContextUseCase();
        final persistUseCase = _MockPersistActiveStoreUseCase();
        final clearUseCase = _MockClearActiveStoreUseCase();
        final session = _session();

        when(() => authController.addListener(any())).thenReturn(null);
        when(() => authController.removeListener(any())).thenReturn(null);
        when(() => authController.session).thenReturn(session);
        when(
          () => loadUseCase(userId: any(named: 'userId')),
        ).thenAnswer(
          (_) async => Success<CurrentUserContext, AppFailure>(
            _context(name: 'Camila Oliveira', activeStoreId: '03'),
          ),
        );

        final controller = CurrentUserContextController(
          authController: authController,
          loadCurrentUserContextUseCase: loadUseCase,
          persistActiveStoreUseCase: persistUseCase,
          clearActiveStoreUseCase: clearUseCase,
        );
        addTearDown(controller.dispose);

        await Future<void>.delayed(Duration.zero);

        final firstReloadCompleter = Completer<AppResult<CurrentUserContext>>();
        final secondReloadCompleter =
            Completer<AppResult<CurrentUserContext>>();
        var reloadCallCount = 0;
        when(
          () => loadUseCase(userId: any(named: 'userId')),
        ).thenAnswer((_) {
          reloadCallCount += 1;
          return reloadCallCount == 1
              ? firstReloadCompleter.future
              : secondReloadCompleter.future;
        });

        final firstReload = controller.reloadUserContext();
        final secondReload = controller.reloadUserContext();

        firstReloadCompleter.complete(
          Success<CurrentUserContext, AppFailure>(
            _context(name: 'Primeira resposta', activeStoreId: '03'),
          ),
        );

        await firstReload;

        check(controller.isRefreshing).isTrue();
        check(controller.userScope.name).equals('Camila Oliveira');

        secondReloadCompleter.complete(
          Success<CurrentUserContext, AppFailure>(
            _context(name: 'Segunda resposta', activeStoreId: '08'),
          ),
        );

        await secondReload;

        check(controller.isRefreshing).isFalse();
        check(controller.userScope.name).equals('Segunda resposta');
        check(controller.activeStore.id).equals('08');
      },
    );
  });
}

AuthSession _session() {
  return AuthSession(
    userId: 'client-1',
    email: EmailAddress('client@example.com'),
    accessToken: 'token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime(2099),
    accountStatus: ClientAccountStatus.active,
  );
}

CurrentUserContext _context({
  required String name,
  required String activeStoreId,
}) {
  return CurrentUserContext(
    scope: CurrentUserScope(
      profile: UserProfile(
        id: 'client-1',
        name: name,
        roleLabel: 'Gerente regional',
        corporateEmail: 'client@example.com',
        phone: '+55 11 99999-9999',
      ),
      access: const UserAccessScope(
        allowedStores: <StoreScope>[
          StoreScope(id: '03', name: 'Loja Centro'),
          StoreScope(id: '08', name: 'Loja Norte'),
        ],
        permissions: <UserPermission>{UserPermission.viewDashboard},
      ),
    ),
    activeStoreId: activeStoreId,
  );
}
