import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:colmeia/features/sales/application/load_margem_produto_rows_for_share_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock implements MargemProdutoRepository {}

MargemProdutoRow _row(int codProduto) {
  return MargemProdutoRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Loja',
    codProduto: codProduto,
    nomeProduto: 'Product $codProduto',
    custoReposicao: 10,
    precoVendaProduto: 20,
    percentualMarkupCustoCompraProduto: 100,
    margemLucroProduto: 50,
  );
}

void main() {
  late _MockRepository repository;
  late LoadMargemProdutoRowsForShareUseCase useCase;

  const filter = MargemProdutoFilter(
    codEmpresa: 1,
    codFilial: 2,
    sortBy: MargemProdutoSortBy.margemLucroProduto,
    sortDirection: ResumoProdutoVendaSortDirection.descending,
  );

  setUpAll(() {
    registerFallbackValue(filter);
  });

  setUp(() {
    repository = _MockRepository();
    useCase = LoadMargemProdutoRowsForShareUseCase(repository);
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
      totalCount: LoadMargemProdutoRowsForShareUseCase.maxExportRowCount + 1,
    );

    expect(result.isError(), isTrue);
    final failure = result.exceptionOrNull();
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure! as ValidationFailure).message,
      'share_export_row_limit_exceeded',
    );
  });

  test('loads a single page when totalCount fits one request', () async {
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
    ).thenAnswer(
      (_) async => Success(
        MargemProdutoPageResult(
          items: <MargemProdutoRow>[_row(1), _row(2), _row(3)],
          totalCount: 3,
        ),
      ),
    );

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: 3,
      clientToken: 'token',
    );

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull(), hasLength(3));
    final captured =
        verify(
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
            ).captured.single
            as MargemProdutoFilter;
    expect(captured.page, 1);
    expect(captured.pageSize, 3);
    expect(captured.sortBy, MargemProdutoSortBy.margemLucroProduto);
    expect(
      captured.sortDirection,
      ResumoProdutoVendaSortDirection.descending,
    );
  });

  test('loads multiple pages until totalCount is reached', () async {
    var callCount = 0;
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
    ).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        return Success(
          MargemProdutoPageResult(
            items: List<MargemProdutoRow>.generate(
              MargemProdutoFilter.maxPageSize,
              (index) => _row(index + 1),
            ),
            totalCount: 600,
          ),
        );
      }
      return Success(
        MargemProdutoPageResult(
          items: List<MargemProdutoRow>.generate(
            100,
            (index) => _row(index + MargemProdutoFilter.maxPageSize + 1),
          ),
          totalCount: 600,
        ),
      );
    });

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: 600,
      clientToken: 'token',
    );

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull(), hasLength(600));
    verify(
      () => repository.loadPage(
        userId: 'u',
        agentId: 'a',
        filter: any(named: 'filter'),
        clientToken: 'token',
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
      ),
    ).called(2);
  });

  test('drops extra rows when a page overshoots totalCount', () async {
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
    ).thenAnswer(
      (_) async => Success(
        MargemProdutoPageResult(
          items: <MargemProdutoRow>[_row(1), _row(2), _row(3), _row(4)],
          totalCount: 3,
        ),
      ),
    );

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: 3,
      clientToken: 'token',
    );

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull(), hasLength(3));
    expect(
      result.getOrNull()?.map((row) => row.codProduto).toList(),
      <int>[1, 2, 3],
    );
  });

  test('propagates repository failure', () async {
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
    ).thenAnswer(
      (_) async => const Failure<MargemProdutoPageResult, AppFailure>(
        ValidationFailure(message: 'load_failed'),
      ),
    );

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: 10,
    );

    expect(result.isError(), isTrue);
    expect(result.exceptionOrNull(), isA<ValidationFailure>());
  });
}
