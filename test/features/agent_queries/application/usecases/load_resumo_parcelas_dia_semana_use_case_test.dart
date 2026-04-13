import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements ResumoParcelasDiaSemanaRepository {}

void main() {
  late _MockRepository repository;
  late LoadResumoParcelasDiaSemanaUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    repository = _MockRepository();
    useCase = LoadResumoParcelasDiaSemanaUseCase(repository);
  });

  test('forwards arguments to the repository', () async {
    final expectedRows = <ResumoParcelasDiaSemanaRow>[
      const ResumoParcelasDiaSemanaRow(
        codEmpresa: 1,
        codFilial: 1,
        diaSemanaNumero: 2,
        diaSemana: 'Segunda',
        qtdVendas: 1,
        valorParcela: 10,
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
          Success<List<ResumoParcelasDiaSemanaRow>, AppFailure>(expectedRows),
    );

    final filter = ResumoParcelasDiaSemanaFilter(
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
