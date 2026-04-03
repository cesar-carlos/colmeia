import 'package:checks/checks.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/repositories/user_context_repository_impl.dart';
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

  setUp(() {
    local = _MockUserContextLocalDataSource();
    remote = _MockUserContextRemoteDataSource();
    repository = UserContextRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  test('should expose clearer message when user context returns 401', () async {
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
}
