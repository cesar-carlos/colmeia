import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockCadastroFilialRepository extends Mock
    implements CadastroFilialRepository {}

void main() {
  late _MockCadastroFilialRepository repository;
  late LoadCadastroFilialPageUseCase useCase;

  setUp(() {
    repository = _MockCadastroFilialRepository();
    useCase = LoadCadastroFilialPageUseCase(repository);
  });

  test('forwards to CadastroFilialRepository.loadPage', () async {
    when(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(codEmpresa: 1),
        clientToken: 'tok',
        bridgeTimeoutMs: 5000,
        hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
        hubConnectedFromApprovedCatalogRow: true,
      ),
    ).thenAnswer(
      (_) async => const Success<CadastroFilialPageResult, AppFailure>(
        CadastroFilialPageResult(items: <CadastroFilialRow>[], totalCount: 0),
      ),
    );

    final out = await useCase.call(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const CadastroFilialFilter(codEmpresa: 1),
      clientToken: 'tok',
      bridgeTimeoutMs: 5000,
      hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
      hubConnectedFromApprovedCatalogRow: true,
    );

    check(out.isSuccess()).isTrue();
    check(out.getOrThrow().totalCount).equals(0);
    verify(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(codEmpresa: 1),
        clientToken: 'tok',
        bridgeTimeoutMs: 5000,
        hubPresenceOnlineAgentIdsSnapshot: const <String>{'agent-1'},
        hubConnectedFromApprovedCatalogRow: true,
      ),
    ).called(1);
  });
}
