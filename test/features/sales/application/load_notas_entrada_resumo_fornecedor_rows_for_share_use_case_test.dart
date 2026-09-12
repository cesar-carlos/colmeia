import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_resumo_fornecedor_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_resumo_fornecedor_repository.dart';
import 'package:colmeia/features/sales/application/load_notas_entrada_resumo_fornecedor_rows_for_share_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements NotasEntradaResumoFornecedorRepository {}

NotaEntradaResumoFornecedorRow _row(int code) {
  return NotaEntradaResumoFornecedorRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Loja',
    codFornecedor: code,
    nomeFornecedor: 'Fornecedor $code',
    qtdNotas: 2,
    ticketMedio: 5,
    valorTotalCompra: 10,
  );
}

void main() {
  late _MockRepository repository;
  late LoadNotasEntradaResumoFornecedorRowsForShareUseCase useCase;

  final filter = NotasEntradaFilter(
    dataLancamentoInicio: DateTime(2026, 9),
    dataLancamentoFim: DateTime(2026, 9, 12),
    searchTerm: 'Mel',
  );

  setUpAll(() {
    registerFallbackValue(filter);
  });

  setUp(() {
    repository = _MockRepository();
    useCase = LoadNotasEntradaResumoFornecedorRowsForShareUseCase(repository);
  });

  test('returns empty list when totalCount is zero', () async {
    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: 0,
    );

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull(), isEmpty);
    verifyNever(
      () => repository.loadPage(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
      ),
    );
  });

  test('fails when totalCount exceeds export cap', () async {
    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount:
          LoadNotasEntradaResumoFornecedorRowsForShareUseCase
              .maxExportRowCount +
          1,
    );

    expect(result.isError(), isTrue);
    expect(
      (result.exceptionOrNull()! as ValidationFailure).message,
      'share_export_row_limit_exceeded',
    );
  });

  test('forwards dates and searchTerm on every export page', () async {
    const totalCount = 600;
    when(
      () => repository.loadPage(
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
    ).thenAnswer((invocation) async {
      final pageFilter =
          invocation.namedArguments[#filter] as NotasEntradaFilter;
      final lastRow = pageFilter.endRow < totalCount
          ? pageFilter.endRow
          : totalCount;
      final items = <NotaEntradaResumoFornecedorRow>[
        for (var index = pageFilter.startRow; index <= lastRow; index++)
          _row(index),
      ];
      return Success(
        NotasEntradaResumoFornecedorPageResult(
          items: items,
          totalCount: totalCount,
          totalValorCompra: 1250.5,
        ),
      );
    });

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: totalCount,
      clientToken: 'token',
    );

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull(), hasLength(totalCount));
    final captured = verify(
      () => repository.loadPage(
        userId: 'u',
        agentId: 'a',
        filter: captureAny(named: 'filter'),
        clientToken: 'token',
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
      ),
    ).captured.cast<NotasEntradaFilter>();
    expect(captured, hasLength(2));
    expect(captured[0].searchTerm, 'Mel');
    expect(captured[1].page, 2);
    expect(captured[1].startRow, 501);
  });
}
