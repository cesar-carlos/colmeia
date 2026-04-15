import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockResumoParcelasAnualRepository extends Mock
    implements ResumoParcelasAnualRepository {}

void main() {
  late _MockResumoParcelasAnualRepository repository;
  late LoadResumoParcelasAnualUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    repository = _MockResumoParcelasAnualRepository();
    useCase = LoadResumoParcelasAnualUseCase(repository);
  });

  test('forwards arguments to the repository', () async {
    const expectedRows = <ResumoParcelasAnualRow>[
      ResumoParcelasAnualRow(
        codEmpresa: 1,
        codFilial: 1,
        anoDataVenda: 2026,
        qtdVendas: 1,
        valorTotalVenda: 10,
      ),
    ];
    when(
      () => repository.load(
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<List<ResumoParcelasAnualRow>, AppFailure>(expectedRows),
    );

    final filter = ResumoParcelasAnualFilter(
      dataVendaInicio: DateTime.utc(2026),
      dataVendaFim: DateTime.utc(2026, 12, 31),
    );

    final result = await useCase(
      agentId: 'agent-1',
      filter: filter,
      clientToken: 'token',
      bridgeTimeoutMs: 8000,
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()).equals(expectedRows);
    verify(
      () => repository.load(
        agentId: 'agent-1',
        filter: filter,
        clientToken: 'token',
        bridgeTimeoutMs: 8000,
      ),
    ).called(1);
  });
}
