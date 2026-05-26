import 'package:checks/checks.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/models/current_user_context_model.dart';
import 'package:colmeia/features/user_context/data/models/user_access_scope_model.dart';
import 'package:colmeia/features/user_context/data/models/user_profile_model.dart';
import 'package:colmeia/features/user_context/data/repositories/user_context_repository_impl.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserContextLocalDataSource extends Mock
    implements UserContextLocalDataSource {}

class _MockUserContextRemoteDataSource extends Mock
    implements UserContextRemoteDataSource {}

void main() {
  late _MockUserContextLocalDataSource local;
  late _MockUserContextRemoteDataSource remote;
  late UserContextRepositoryImpl repository;

  CurrentUserContextModel buildContextModel({String activeStoreId = 'store-1'}) {
    return CurrentUserContextModel(
      profile: const UserProfileModel(
        id: 'client-1',
        name: 'Alice',
        roleLabel: 'Owner',
      ),
      access: const UserAccessScopeModel(
        allowedStores: <StoreScope>[
          StoreScope(id: 'store-1', name: 'Loja 1'),
        ],
        permissions: <UserPermission>{UserPermission.viewDashboard},
      ),
      activeStoreId: activeStoreId,
    );
  }

  setUp(() {
    local = _MockUserContextLocalDataSource();
    remote = _MockUserContextRemoteDataSource();
    repository = UserContextRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  group('loadUserContext', () {
    test('returns Success with merged context when remote and local '
        'datasources both succeed', () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => 'store-1');
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenAnswer((_) async => buildContextModel());

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.activeStoreId).equals('store-1');
      check(result.getOrNull()?.scope.profile.id).equals('client-1');
    });

    test('uses remote activeStoreId as fallback when local has none', () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenAnswer((_) async => buildContextModel(activeStoreId: 'store-2'));

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.activeStoreId).equals('store-2');
    });

    test('should expose clearer message when user context returns 401',
        () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/me'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/client-auth/me'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Sua sessao expirou. Entre novamente para carregar seu contexto.',
      );
    });

    test('maps 403 to a tailored authorization message', () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/me'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/client-auth/me'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Sua conta nao possui acesso ao contexto solicitado no momento.',
      );
    });

    test('maps 404 to a tailored not-found message', () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/me'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/client-auth/me'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Nao foi possivel encontrar os dados da sua conta.',
      );
    });

    test('maps other status codes to a generic fallback message', () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/me'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/client-auth/me'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Nao foi possivel carregar permissoes e lojas do usuario.',
      );
    });

    test('maps unexpected errors to the generic fallback message', () async {
      when(
        () => local.readActiveStoreId(any()),
      ).thenAnswer((_) async => null);
      when(
        () => remote.loadUserContext(userId: any(named: 'userId')),
      ).thenThrow(StateError('unexpected boom'));

      final result = await repository.loadUserContext(userId: 'client-1');

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()?.displayMessage).equals(
        'Nao foi possivel carregar permissoes e lojas do usuario.',
      );
    });
  });

  group('persistActiveStoreId', () {
    test('delegates to the local datasource with the provided values',
        () async {
      when(
        () => local.saveActiveStoreId(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      ).thenAnswer((_) async {});

      await repository.persistActiveStoreId(
        userId: 'client-1',
        storeId: 'store-1',
      );

      verify(
        () => local.saveActiveStoreId(userId: 'client-1', storeId: 'store-1'),
      ).called(1);
    });

    test('swallows datasource errors and does not rethrow', () async {
      when(
        () => local.saveActiveStoreId(
          userId: any(named: 'userId'),
          storeId: any(named: 'storeId'),
        ),
      ).thenThrow(StateError('storage unavailable'));

      await repository.persistActiveStoreId(
        userId: 'client-1',
        storeId: 'store-1',
      );

      verify(
        () => local.saveActiveStoreId(userId: 'client-1', storeId: 'store-1'),
      ).called(1);
    });
  });

  group('clearPersistedActiveStoreId', () {
    test('delegates to the local datasource with the provided userId',
        () async {
      when(
        () => local.clearActiveStoreId(any()),
      ).thenAnswer((_) async {});

      await repository.clearPersistedActiveStoreId(userId: 'client-1');

      verify(() => local.clearActiveStoreId('client-1')).called(1);
    });

    test('swallows datasource errors and does not rethrow', () async {
      when(
        () => local.clearActiveStoreId(any()),
      ).thenThrow(StateError('storage unavailable'));

      await repository.clearPersistedActiveStoreId(userId: 'client-1');

      verify(() => local.clearActiveStoreId('client-1')).called(1);
    });
  });
}
