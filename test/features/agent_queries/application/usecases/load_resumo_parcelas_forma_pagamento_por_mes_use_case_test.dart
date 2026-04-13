import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockResumoParcelasFormaPagamentoPorMesRepository extends Mock
    implements ResumoParcelasFormaPagamentoPorMesRepository {}

void main() {
  late _MockResumoParcelasFormaPagamentoPorMesRepository repository;
  late LoadResumoParcelasFormaPagamentoPorMesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelasFormaPagamentoPorMesFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    repository = _MockResumoParcelasFormaPagamentoPorMesRepository();
    useCase = LoadResumoParcelasFormaPagamentoPorMesUseCase(repository);
  });

  test('forwards arguments to the repository', () async {
    const expectedRows = <ResumoParcelasFormaPagamentoPorMesRow>[
      ResumoParcelasFormaPagamentoPorMesRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeUsuario: 'U',
        anoMesDataVenda: '2026/01',
        codFormaPagamento: 'PX',
        descricaoFormaPagamento: 'Pix',
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
          const Success<
            List<ResumoParcelasFormaPagamentoPorMesRow>,
            AppFailure
          >(
            expectedRows,
          ),
    );

    final filter = ResumoParcelasFormaPagamentoPorMesFilter(
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
