import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_diario_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements ResumoParcelaFormaPagamentoDiarioRepository {}

void main() {
  late _MockRepository repository;
  late LoadResumoParcelaFormaPagamentoDiarioUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelaFormaPagamentoDiarioFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    repository = _MockRepository();
    useCase = LoadResumoParcelaFormaPagamentoDiarioUseCase(repository);
  });

  test('forwards arguments to the repository', () async {
    final expectedRows = <ResumoVendaProdutoDiarioRow>[
      ResumoVendaProdutoDiarioRow(
        codEmpresa: 1,
        codFilial: 1,
        codProdutoVendido: 1,
        origem: 'OB',
        codOrigem: 1,
        dataVenda: DateTime(2026, 1, 5),
        anoMesDataVenda: '2026/01',
        nomeUsuario: 'U',
        codVendedor: 1,
        nomeVendedor: 'Pix',
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
          Success<List<ResumoVendaProdutoDiarioRow>, AppFailure>(
            expectedRows,
          ),
    );

    final filter = ResumoParcelaFormaPagamentoDiarioFilter(
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
