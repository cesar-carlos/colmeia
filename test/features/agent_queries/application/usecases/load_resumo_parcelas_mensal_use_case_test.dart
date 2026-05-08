import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockResumoParcelasMensalRepository extends Mock
    implements ResumoParcelasMensalRepository {}

void main() {
  late _MockResumoParcelasMensalRepository repository;
  late LoadResumoParcelasMensalUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    repository = _MockResumoParcelasMensalRepository();
    useCase = LoadResumoParcelasMensalUseCase(repository);
  });

  test('forwards arguments to the repository', () async {
    const expectedRows = <ResumoParcelasMensalRow>[
      ResumoParcelasMensalRow(
        codEmpresa: 1,
        codFilial: 1,
        ano: 2026,
        mes: 3,
        anoMes: '2026/03',
        qtdVendas: 1,
        valorParcela: 10,
      ),
    ];
    when(
      () => repository.load(
        userId: 'user-1',
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<ResumoParcelasMensalRow>, AppFailure>(
        expectedRows,
      ),
    );

    final filter = ResumoParcelasMensalFilter(
      dataVendaInicio: DateTime.utc(2026),
      dataVendaFim: DateTime.utc(2026, 12, 31),
    );

    final result = await useCase(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filter,
      clientToken: 'token',
      bridgeTimeoutMs: 8000,
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()).equals(expectedRows);
    verify(
      () => repository.load(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: filter,
        clientToken: 'token',
        bridgeTimeoutMs: 8000,
      ),
    ).called(1);
  });
}
