import 'package:checks/checks.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/repositories/client_registration_repository_impl.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockAuthRemoteDataSource remote;
  late ClientRegistrationRepositoryImpl repository;

  setUp(() {
    remote = _MockAuthRemoteDataSource();
    repository = ClientRegistrationRepositoryImpl(remoteDataSource: remote);
  });

  group('ClientRegistrationRepositoryImpl', () {
    test(
      'returns Success with registration submission on happy path',
      () async {
        const submission = ClientRegistrationSubmission(
          status: ClientRegistrationStatus.pending,
          message: 'Pending approval',
          pollToken: 'token-abc',
        );
        when(
          () => remote.register(
            ownerEmail: any(named: 'ownerEmail'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            mobile: any(named: 'mobile'),
          ),
        ).thenAnswer((_) async => submission);

        final result = await repository.register(
          ownerEmail: 'owner@corp.com',
          firstName: 'Alice',
          lastName: 'Doe',
          email: 'client@corp.com',
          password: 'Password1',
        );

        check(result.isSuccess()).isTrue();
        check(result.getOrNull()?.pollToken).equals('token-abc');
      },
    );

    test('returns unknown status on 200 without mapping to failure', () async {
      when(
        () => remote.readRegistrationStatus(token: any(named: 'token')),
      ).thenAnswer((_) async => ClientRegistrationStatus.unknown);

      final result = await repository.readRegistrationStatus(
        token: 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()).equals(ClientRegistrationStatus.unknown);
    });
  });
}
