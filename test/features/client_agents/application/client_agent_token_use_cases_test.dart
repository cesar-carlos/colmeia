import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentClientTokenRepository extends Mock
    implements AgentClientTokenRepository {}

void main() {
  late _MockAgentClientTokenRepository repository;

  setUp(() {
    repository = _MockAgentClientTokenRepository();
  });

  group('GetClientAgentTokenUseCase', () {
    test('forwards the call and returns repository snapshot', () async {
      when(
        () => repository.getToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot(token: 'tok'),
        ),
      );

      final useCase = GetClientAgentTokenUseCase(repository);
      final result = await useCase(userId: 'u', agentId: 'a');

      check(result.getOrNull()?.token).equals('tok');
      check(result.getOrNull()?.hasToken).equals(true);
      verify(
        () => repository.getToken(userId: 'u', agentId: 'a'),
      ).called(1);
    });

    test('propagates failure from repository', () async {
      when(
        () => repository.getToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Failure<ClientAgentTokenSnapshot, AppFailure>(
          NetworkFailure(message: 'boom', userMessage: 'fail'),
        ),
      );

      final useCase = GetClientAgentTokenUseCase(repository);
      final result = await useCase(userId: 'u', agentId: 'a');

      check(result.exceptionOrNull()).isNotNull();
    });
  });

  group('SaveClientAgentTokenUseCase', () {
    test('forwards the call and returns updated snapshot', () async {
      when(
        () => repository.saveToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot(token: 'saved'),
        ),
      );

      final useCase = SaveClientAgentTokenUseCase(repository);
      final result = await useCase(
        userId: 'u',
        agentId: 'a',
        clientToken: 'saved',
      );

      check(result.getOrNull()?.token).equals('saved');
      verify(
        () => repository.saveToken(
          userId: 'u',
          agentId: 'a',
          clientToken: 'saved',
        ),
      ).called(1);
    });
  });

  group('RemoveClientAgentTokenUseCase', () {
    test('forwards the call and returns repository result', () async {
      when(
        () => repository.removeToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Success<Unit, AppFailure>(unit),
      );

      final useCase = RemoveClientAgentTokenUseCase(repository);
      final result = await useCase(userId: 'u', agentId: 'a');

      check(result.isSuccess()).isTrue();
      verify(
        () => repository.removeToken(userId: 'u', agentId: 'a'),
      ).called(1);
    });

    test('propagates failure from repository', () async {
      when(
        () => repository.removeToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Failure<Unit, AppFailure>(
          AuthorizationFailure(message: 'forbidden', userMessage: 'no'),
        ),
      );

      final useCase = RemoveClientAgentTokenUseCase(repository);
      final result = await useCase(userId: 'u', agentId: 'a');

      check(result.exceptionOrNull()).isA<AuthorizationFailure>();
    });
  });
}
