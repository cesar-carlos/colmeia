import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_anual_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_anual_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockResumoParcelasFormaPagamentoAnualRepository extends Mock
    implements ResumoParcelasFormaPagamentoAnualRepository {}

void main() {
  late _MockResumoParcelasFormaPagamentoAnualRepository repository;
  late LoadResumoParcelasFormaPagamentoAnualUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelasFormaPagamentoAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    repository = _MockResumoParcelasFormaPagamentoAnualRepository();
    useCase = LoadResumoParcelasFormaPagamentoAnualUseCase(repository);
  });

  test('forwards arguments to the repository', () async {
    const expectedRows = <ResumoParcelasFormaPagamentoAnualRow>[
      ResumoParcelasFormaPagamentoAnualRow(
        ano: 2026,
        descricaoFormaPagamento: 'Pix',
        quantidade: 1,
        valorTotal: 10,
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
          const Success<List<ResumoParcelasFormaPagamentoAnualRow>, AppFailure>(
            expectedRows,
          ),
    );

    final filter = ResumoParcelasFormaPagamentoAnualFilter(
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
