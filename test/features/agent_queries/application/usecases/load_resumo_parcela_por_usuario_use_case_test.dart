import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_por_usuario_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_por_usuario_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements ResumoParcelaPorUsuarioRepository {}

void main() {
  late _MockRepository repository;
  late LoadResumoParcelaPorUsuarioUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelaPorUsuarioFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );
  });

  setUp(() {
    repository = _MockRepository();
    useCase = LoadResumoParcelaPorUsuarioUseCase(repository);
  });

  test('should forward arguments to the repository', () async {
    final rows = <ResumoParcelaPorUsuarioRow>[
      const ResumoParcelaPorUsuarioRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeUsuario: 'X',
        qtdVendas: 1,
        valorParcela: 10,
      ),
    ];
    when(
      () => repository.load(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
      ),
    ).thenAnswer(
      (_) async => Success<List<ResumoParcelaPorUsuarioRow>, AppFailure>(rows),
    );

    final filter = ResumoParcelaPorUsuarioFilter(
      dataVendaInicio: DateTime.utc(2026, 4),
      dataVendaFim: DateTime.utc(2026, 4, 30),
    );

    final result = await useCase(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filter,
      clientToken: 'tok',
      bridgeTimeoutMs: 1000,
    );

    check(result.isSuccess()).isTrue();
    verify(
      () => repository.load(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: filter,
        clientToken: 'tok',
        bridgeTimeoutMs: 1000,
      ),
    ).called(1);
  });
}
