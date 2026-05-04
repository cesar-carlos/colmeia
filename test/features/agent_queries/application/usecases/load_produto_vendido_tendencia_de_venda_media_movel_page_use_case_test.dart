import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements ProdutoVendidoTendenciaDeVendaMediaMovelRepository {}

void main() {
  late _MockRepository repository;
  late LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase useCase;

  const filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
    quantidadeDias: 7,
  );

  setUp(() {
    repository = _MockRepository();
    useCase = LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase(
      repository,
    );
  });

  test(
    'forwards to ProdutoVendidoTendenciaDeVendaMediaMovelRepository.loadPage',
    () async {
      when(
        () => repository.loadPage(
          userId: 'user-1',
          agentId: 'agent-1',
          filter: filter,
          clientToken: 'tok',
          bridgeTimeoutMs: 5000,
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
              AppFailure
            >(
              ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
                items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
                totalCount: 0,
              ),
            ),
      );

      final out = await useCase.call(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: filter,
        clientToken: 'tok',
        bridgeTimeoutMs: 5000,
      );

      check(out.isSuccess()).isTrue();
      check(out.getOrThrow().totalCount).equals(0);
      verify(
        () => repository.loadPage(
          userId: 'user-1',
          agentId: 'agent-1',
          filter: filter,
          clientToken: 'tok',
          bridgeTimeoutMs: 5000,
        ),
      ).called(1);
    },
  );
}
