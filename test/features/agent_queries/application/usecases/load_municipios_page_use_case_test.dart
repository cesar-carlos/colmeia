import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_municipios_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockMunicipioListRepository extends Mock
    implements MunicipioListRepository {}

void main() {
  late _MockMunicipioListRepository repository;
  late LoadMunicipiosPageUseCase useCase;

  setUp(() {
    repository = _MockMunicipioListRepository();
    useCase = LoadMunicipiosPageUseCase(repository);
  });

  test('forwards to MunicipioListRepository.loadPage', () async {
    when(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const MunicipioListFilter(),
        clientToken: 'tok',
        bridgeTimeoutMs: 5000,
      ),
    ).thenAnswer(
      (_) async => const Success<MunicipioListPageResult, AppFailure>(
        MunicipioListPageResult(items: <MunicipioRow>[], totalCount: 0),
      ),
    );

    final out = await useCase.call(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MunicipioListFilter(),
      clientToken: 'tok',
      bridgeTimeoutMs: 5000,
    );

    check(out.isSuccess()).isTrue();
    check(out.getOrThrow().totalCount).equals(0);
    verify(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const MunicipioListFilter(),
        clientToken: 'tok',
        bridgeTimeoutMs: 5000,
      ),
    ).called(1);
  });
}
