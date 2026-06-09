import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_target_warm_up_coordinator.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

void main() {
  late _MockAgentQueryTargetResolver resolver;
  late AgentQueryTargetWarmUpCoordinator coordinator;

  setUp(() {
    resolver = _MockAgentQueryTargetResolver();
    coordinator = AgentQueryTargetWarmUpCoordinator(targetResolver: resolver);
  });

  test('scheduleWarmUp resolves all approved agents once per user', () async {
    when(
      () => resolver.resolve(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
        AgentQueryTargetResolution(
          consideredApprovedTargets: [],
          missingClientTokenTargets: [],
          consideredApprovedAgentCount: 0,
        ),
      ),
    );

    coordinator
      ..scheduleWarmUp(userId: 'user-1')
      ..scheduleWarmUp(userId: 'user-1');
    await Future<void>.delayed(Duration.zero);

    verify(() => resolver.resolve(userId: 'user-1')).called(1);
  });

  test('invalidate allows warm-up for the same user again', () async {
    when(
      () => resolver.resolve(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
        AgentQueryTargetResolution(
          consideredApprovedTargets: [],
          missingClientTokenTargets: [],
          consideredApprovedAgentCount: 0,
        ),
      ),
    );

    coordinator.scheduleWarmUp(userId: 'user-1');
    await Future<void>.delayed(Duration.zero);
    coordinator
      ..invalidate()
      ..scheduleWarmUp(userId: 'user-1');
    await Future<void>.delayed(Duration.zero);

    verify(() => resolver.resolve(userId: 'user-1')).called(2);
  });

  test('swallows resolver failures without throwing', () async {
    when(
      () => resolver.resolve(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Failure<AgentQueryTargetResolution, AppFailure>(
        UnknownFailure(message: 'warm-up failed'),
      ),
    );

    coordinator.scheduleWarmUp(userId: 'user-1');
    await Future<void>.delayed(Duration.zero);

    verify(() => resolver.resolve(userId: 'user-1')).called(1);
  });
}
