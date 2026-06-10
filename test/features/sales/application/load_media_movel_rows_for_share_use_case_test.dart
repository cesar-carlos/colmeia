import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:colmeia/features/sales/application/load_media_movel_rows_for_share_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements ProdutoVendidoTendenciaDeVendaMediaMovelRepository {}

ProdutoVendidoTendenciaDeVendaMediaMovelRow _row(int codProduto) {
  return ProdutoVendidoTendenciaDeVendaMediaMovelRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: 'Product $codProduto',
    codUnidadeMedida: 'UN',
    mediaAtual: 10,
    mediaAnterior: 8,
    diferenca: 2,
    tendenciaPercentual: 25,
    classificacao: 'CRESCENDO',
  );
}

void main() {
  late _MockRepository repository;
  late LoadMediaMovelRowsForShareUseCase useCase;

  const filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
    quantidadeDias: 7,
    pageSize: 100,
  );

  setUpAll(() {
    registerFallbackValue(filter);
  });

  setUp(() {
    repository = _MockRepository();
    useCase = LoadMediaMovelRowsForShareUseCase(repository);
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
      totalCount: 501,
    );

    expect(result.isError(), isTrue);
    final failure = result.exceptionOrNull();
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure! as ValidationFailure).message,
      'share_export_row_limit_exceeded',
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
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        return Success(
          ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
            items: List<ProdutoVendidoTendenciaDeVendaMediaMovelRow>.generate(
              100,
              (index) => _row(index + 1),
            ),
            totalCount: 250,
          ),
        );
      }
      return Success(
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: List<ProdutoVendidoTendenciaDeVendaMediaMovelRow>.generate(
            150,
            (index) => _row(index + 101),
          ),
          totalCount: 250,
        ),
      );
    });

    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      filter: filter,
      totalCount: 250,
      clientToken: 'token',
    );

    expect(result.isSuccess(), isTrue);
    expect(result.getOrNull(), hasLength(250));
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
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(2);
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
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(
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
