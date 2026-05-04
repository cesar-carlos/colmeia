import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockRepository extends Mock
    implements ProdutoVendidoTendenciaDeVendaMediaMovelRepository {}

void main() {
  late _MockRepository repository;
  late LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase useCase;

  const filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
    quantidadeDias: 7,
  );

  setUp(() {
    repository = _MockRepository();
    useCase = LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase(
      repository,
    );
  });

  test(
    'forwards to ProdutoVendidoTendenciaDeVendaMediaMovelRepository.loadSummary',
    () async {
      when(
        () => repository.loadSummary(
          userId: 'user-1',
          agentId: 'agent-1',
          filter: filter,
          clientToken: 'tok',
          bridgeTimeoutMs: 5000,
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
              AppFailure
            >(
              <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
                ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                  classificacao: 'CRESCENDO',
                  quantidadeProdutos: 2,
                  impactoLiquido: 4.5,
                ),
              ],
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
      check(out.getOrThrow().single.quantidadeProdutos).equals(2);
      verify(
        () => repository.loadSummary(
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
