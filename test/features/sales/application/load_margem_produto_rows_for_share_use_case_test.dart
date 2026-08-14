import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
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
    expect(captured.startRow, 1);
    expect(captured.endRow, 3);
    expect(captured.codEmpresa, 1);
    expect(captured.codFilial, 2);
    expect(captured.searchTerm, isNull);
  });

  test('keeps pageSize constant so later pages do not overlap', () async {
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
          invocation.namedArguments[#filter] as MargemProdutoFilter;
      final lastRow = pageFilter.endRow < totalCount
          ? pageFilter.endRow
          : totalCount;
      final items = <MargemProdutoRow>[
        for (var index = pageFilter.startRow; index <= lastRow; index++)
          _row(index),
      ];
      return Success(
        MargemProdutoPageResult(items: items, totalCount: totalCount),
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
    final rows = result.getOrNull()!;
    expect(rows, hasLength(totalCount));
    expect(rows.first.codProduto, 1);
    expect(rows[MargemProdutoFilter.maxPageSize - 1].codProduto, 500);
    expect(rows[MargemProdutoFilter.maxPageSize].codProduto, 501);
    expect(rows.last.codProduto, totalCount);

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
    ).captured.cast<MargemProdutoFilter>();
    expect(captured, hasLength(2));
    expect(captured[0].page, 1);
    expect(captured[0].pageSize, MargemProdutoFilter.maxPageSize);
    expect(captured[0].startRow, 1);
    expect(captured[0].endRow, 500);
    expect(captured[1].page, 2);
    expect(captured[1].pageSize, MargemProdutoFilter.maxPageSize);
    expect(captured[1].startRow, 501);
    expect(captured[1].endRow, 1000);
  });

  test('forwards searchTerm on every export page', () async {
    const searchFilter = MargemProdutoFilter(
      codEmpresa: 1,
      codFilial: 2,
      searchTerm: 'Mel',
    );
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
          invocation.namedArguments[#filter] as MargemProdutoFilter;
      final lastRow = pageFilter.endRow < 600 ? pageFilter.endRow : 600;
      final items = <MargemProdutoRow>[
        for (var index = pageFilter.startRow; index <= lastRow; index++)
          _row(index),
      ];
      return Success(
        MargemProdutoPageResult(items: items, totalCount: 600),
      );
    });

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: searchFilter,
      totalCount: 600,
      clientToken: 'token',
    );

    expect(result.isSuccess(), isTrue);
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
    ).captured.cast<MargemProdutoFilter>();
    expect(captured, hasLength(2));
    expect(captured[0].searchTerm, 'Mel');
    expect(captured[1].searchTerm, 'Mel');
    expect(captured[0].pageSize, MargemProdutoFilter.maxPageSize);
    expect(captured[1].pageSize, MargemProdutoFilter.maxPageSize);
  });

  test(
    'fails when a later page is shorter than the ROW_NUMBER window',
    () async {
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
              50,
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

      expect(result.isError(), isTrue);
      expect(
        (result.exceptionOrNull()! as ValidationFailure).message,
        'share_export_incomplete_catalog',
      );
    },
  );

  test('fails when a page overshoots totalCount', () async {
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

    expect(result.isError(), isTrue);
    expect(result.exceptionOrNull(), isA<ValidationFailure>());
    expect(
      (result.exceptionOrNull()! as ValidationFailure).message,
      'share_export_incomplete_catalog',
    );
  });

  test('fails when a later page returns no rows', () async {
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
      return const Success(
        MargemProdutoPageResult(
          items: <MargemProdutoRow>[],
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

    expect(result.isError(), isTrue);
    expect(result.exceptionOrNull(), isA<ValidationFailure>());
    expect(
      (result.exceptionOrNull()! as ValidationFailure).message,
      'share_export_incomplete_catalog',
    );
  });

  test('fails when the server totalCount diverges during paging', () async {
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
          items: <MargemProdutoRow>[_row(1), _row(2)],
          totalCount: 9,
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

    expect(result.isError(), isTrue);
    expect(
      (result.exceptionOrNull()! as ValidationFailure).message,
      'share_export_incomplete_catalog',
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
