@Tags(['e2e'])
library;

import 'dart:convert';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/cadastro_filial_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/margem_produto_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/notas_entrada_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/notas_entrada_resumo_fornecedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_media_movel_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl_v2.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_por_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_diagnostics.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'support/e2e_dependency_bootstrap.dart';

const _enabled = bool.fromEnvironment('E2E_PROGRESSIVE_VALIDATION');
const _pageSize = int.fromEnvironment(
  'E2E_PROGRESSIVE_PAGE_SIZE',
  defaultValue: 500,
);
const _marginSearch = String.fromEnvironment('E2E_PROGRESSIVE_MARGIN_SEARCH');
const _reportTimeout = Timeout(
  Duration(
    seconds: int.fromEnvironment(
      'E2E_PROGRESSIVE_TEST_TIMEOUT_SECONDS',
      defaultValue: 1800,
    ),
  ),
);

void main() {
  group('Strict progressive report equivalence', () {
    if (!_enabled) {
      test('explicitly enabled against the real agent', () {}, skip: true);
      return;
    }
    setUpAll(() async {
      await e2eSetupDependencies();
      expect(missingE2eRepositoryKeys(), isEmpty);
    });
    tearDownAll(e2eTeardownDependencies);
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 14));
    test(
      'cadastro_filial: full and progressive results are equivalent',
      () async {
        final repository = CadastroFilialRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        const filter = CadastroFilialFilter(pageSize: _pageSize);
        await _verify<CadastroFilialRow>(
          name: 'cadastro_filial',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.nomeFilial,
            row.nomeFantasia,
            row.cnpj,
            row.endereco,
            row.numeroEndereco,
            row.bairro,
            row.cep,
            row.codMunicipio,
            row.nomeMunicipio,
            row.codigoIbge,
            row.ufMunicipio,
          ],
          baseline: () => _pages(
            load: (page) => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              bridgeTimeoutMs: 60000,
              hubConnectedFromApprovedCatalogRow: true,
              filter: CadastroFilialFilter(pageSize: _pageSize, page: page),
            ),
            items: (page) => page.items,
            total: (page) => page.totalCount,
          ),
          progressive: () => repository.loadPagesProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test(
      'margem_produto: full and progressive results are equivalent',
      () async {
        final repository = MargemProdutoRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        const filter = MargemProdutoFilter(
          pageSize: _pageSize,
          searchTerm: _marginSearch,
        );
        await _verify<MargemProdutoRow>(
          name: 'margem_produto',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.nomeFilial,
            row.nomeFantasiaFilial,
            row.codProduto,
            row.nomeProduto,
            row.codGrupoProduto,
            row.nomeGrupoProduto,
            row.codMarca,
            row.nomeMarca,
            row.custoReposicao,
            row.precoVendaProduto,
            row.percentualMarkupCustoCompraProduto,
            row.margemLucroProduto,
          ],
          baseline: () => _pages(
            load: (page) => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              bridgeTimeoutMs: 60000,
              hubConnectedFromApprovedCatalogRow: true,
              filter: MargemProdutoFilter(
                pageSize: _pageSize,
                page: page,
                searchTerm: _marginSearch,
              ),
            ),
            items: (page) => page.items,
            total: (page) => page.totalCount,
          ),
          progressive: () => repository.loadPagesProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test(
      'notas_entrada: full and progressive results are equivalent',
      () async {
        final repository = NotasEntradaRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        final filter = NotasEntradaFilter(
          dataLancamentoInicio: start,
          dataLancamentoFim: end,
          pageSize: _pageSize,
        );
        await _verify<NotaEntradaRow>(
          name: 'notas_entrada',
          signature: (row) => [
            row.compraId,
            row.codEmpresa,
            row.codFilial,
            row.nomeFilial,
            row.nomeFantasiaFilial,
            row.codTipoOperacaoCompra,
            row.descricaoTipoOperacaoCompra,
            row.numeroDocumento,
            row.dataEmissao,
            row.dataEntrada,
            row.dataLancamento,
            row.codFornecedor,
            row.nomeFornecedor,
            row.nomeFantasiaFornecedor,
            row.cnpjCpfFornecedor,
            row.valorTotalCompra,
            row.chaveAcesso,
          ],
          baseline: () => _pages(
            load: (page) => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              bridgeTimeoutMs: 60000,
              hubConnectedFromApprovedCatalogRow: true,
              filter: NotasEntradaFilter(
                dataLancamentoInicio: start,
                dataLancamentoFim: end,
                pageSize: _pageSize,
                page: page,
              ),
            ),
            items: (page) => page.items,
            total: (page) => page.totalCount,
          ),
          progressive: () => repository.loadPagesProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test('notas_entrada_resumo_fornecedor: full and progressive results are equivalent', () async {
      final repository = NotasEntradaResumoFornecedorRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = NotasEntradaFilter(
        dataLancamentoInicio: start,
        dataLancamentoFim: end,
        pageSize: _pageSize,
      );
      await _verify<NotaEntradaResumoFornecedorRow>(
        name: 'notas_entrada_resumo_fornecedor',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.nomeFilial,
          row.nomeFantasiaFilial,
          row.codFornecedor,
          row.nomeFornecedor,
          row.nomeFantasiaFornecedor,
          row.cnpjCpfFornecedor,
          row.qtdNotas,
          row.ticketMedio,
          row.valorTotalCompra,
        ],
        baseline: () => _pages(
          load: (page) => repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: NotasEntradaFilter(
              dataLancamentoInicio: start,
              dataLancamentoFim: end,
              pageSize: _pageSize,
              page: page,
            ),
          ),
          items: (page) => page.items,
          total: (page) => page.totalCount,
        ),
        progressive: () => repository.loadPagesProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test('produto_vendido_tendencia_de_venda_media_movel: full and progressive results are equivalent', () async {
      final repository = ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      const filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 7,
        pageSize: _pageSize,
      );
      await _verify<ProdutoVendidoTendenciaDeVendaMediaMovelRow>(
        name: 'produto_vendido_tendencia_de_venda_media_movel',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.codProduto,
          row.nomeProduto,
          row.codUnidadeMedida,
          row.codGrupoProduto,
          row.nomeGrupoProduto,
          row.codMarca,
          row.nomeMarca,
          row.mediaAtual,
          row.mediaAnterior,
          row.diferenca,
          row.tendenciaPercentual,
          row.classificacao,
        ],
        baseline: () => _pages(
          load: (page) => repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
              quantidadeDias: 7,
              pageSize: _pageSize,
              page: page,
            ),
          ),
          items: (page) => page.items,
          total: (page) => page.totalCount,
        ),
        progressive: () => repository.loadPagesProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test('produto_vendido_tendencia_de_venda: full and progressive results are equivalent', () async {
      final repository = ProdutoVendidoTendenciaDeVendaRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: start,
        periodoAtualFim: end,
        periodoAnteriorInicio: start.subtract(const Duration(days: 15)),
        periodoAnteriorFim: start.subtract(const Duration(days: 1)),
        pageSize: _pageSize,
      );
      await _verify<ProdutoVendidoTendenciaDeVendaRow>(
        name: 'produto_vendido_tendencia_de_venda',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.codProduto,
          row.nomeProduto,
          row.codUnidadeMedida,
          row.codGrupoProduto,
          row.nomeGrupoProduto,
          row.codMarca,
          row.nomeMarca,
          row.qtdAnterior,
          row.qtdAtual,
          row.diferenca,
          row.percentualTendencia,
          row.classificacao,
        ],
        baseline: () => _pages(
          load: (page) => repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: ProdutoVendidoTendenciaDeVendaFilter(
              periodoAtualInicio: start,
              periodoAtualFim: end,
              periodoAnteriorInicio: start.subtract(const Duration(days: 15)),
              periodoAnteriorFim: start.subtract(const Duration(days: 1)),
              pageSize: _pageSize,
              page: page,
            ),
          ),
          items: (page) => page.items,
          total: (page) => page.totalCount,
        ),
        progressive: () => repository.loadPagesProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test(
      'resumo_parcelas_anual: full and progressive results are equivalent',
      () async {
        final repository = ResumoParcelasAnualRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        final filter = ResumoParcelasAnualFilter(
          dataVendaInicio: start,
          dataVendaFim: end,
        );
        await _verify<ResumoParcelasAnualRow>(
          name: 'resumo_parcelas_anual',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.anoDataVenda,
            row.qtdVendas,
            row.valorTotalVenda,
          ],
          baseline: () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
          progressive: () => repository.loadProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test(
      'resumo_parcelas_dia_semana: full and progressive results are equivalent',
      () async {
        final repository = ResumoParcelasDiaSemanaRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        final filter = ResumoParcelasDiaSemanaFilter(
          dataVendaInicio: start,
          dataVendaFim: end,
        );
        await _verify<ResumoParcelasDiaSemanaRow>(
          name: 'resumo_parcelas_dia_semana',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.diaSemanaNumero,
            row.diaSemana,
            row.qtdVendas,
            row.valorParcela,
          ],
          baseline: () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
          progressive: () => repository.loadProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test('resumo_parcelas_dia_semana_usuario: full and progressive results are equivalent', () async {
      final repository = ResumoParcelasDiaSemanaUsuarioRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoParcelasDiaSemanaUsuarioRow>(
        name: 'resumo_parcelas_dia_semana_usuario',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.nomeUsuario,
          row.diaSemanaNumero,
          row.diaSemana,
          row.qtdVendas,
          row.valorParcela,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test('resumo_parcelas_forma_pagamento_por_mes: full and progressive results are equivalent', () async {
      final repository = ResumoParcelasFormaPagamentoPorMesRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoParcelasFormaPagamentoPorMesFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoParcelasFormaPagamentoPorMesRow>(
        name: 'resumo_parcelas_forma_pagamento_por_mes',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.nomeUsuario,
          row.anoMesDataVenda,
          row.codFormaPagamento,
          row.descricaoFormaPagamento,
          row.qtdVendas,
          row.valorParcela,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test(
      'resumo_parcelas_mensal: full and progressive results are equivalent',
      () async {
        final repository = ResumoParcelasMensalRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        final filter = ResumoParcelasMensalFilter(
          dataVendaInicio: start,
          dataVendaFim: end,
        );
        await _verify<ResumoParcelasMensalRow>(
          name: 'resumo_parcelas_mensal',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.ano,
            row.mes,
            row.anoMes,
            row.qtdVendas,
            row.valorParcela,
          ],
          baseline: () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
          progressive: () => repository.loadProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test('resumo_parcela_forma_pagamento_diario: full and progressive results are equivalent', () async {
      final repository = ResumoParcelaFormaPagamentoDiarioRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoParcelaFormaPagamentoDiarioFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoVendaProdutoDiarioRow>(
        name: 'resumo_parcela_forma_pagamento_diario',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.codProdutoVendido,
          row.origem,
          row.codOrigem,
          row.dataVenda,
          row.anoMesDataVenda,
          row.nomeUsuario,
          row.codVendedor,
          row.nomeVendedor,
          row.qtdVendas,
          row.valorTotalVenda,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test('resumo_parcela_forma_pagamento: full and progressive results are equivalent', () async {
      final repository = ResumoParcelaFormaPagamentoRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoParcelaFormaPagamentoFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoParcelaFormaPagamentoRow>(
        name: 'resumo_parcela_forma_pagamento',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.nomeUsuario,
          row.anoDataVenda,
          row.mesDataVenda,
          row.anoMesDataVenda,
          row.codFormaPagamento,
          row.descricaoFormaPagamento,
          row.qtdVendas,
          row.valorParcela,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test('resumo_parcela_forma_pagamento_v2: full and progressive results are equivalent', () async {
      final repository = ResumoParcelaFormaPagamentoRepositoryImplV2(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoParcelaFormaPagamentoFilterV2(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoParcelaFormaPagamentoRowV2>(
        name: 'resumo_parcela_forma_pagamento_v2',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.codFormaPagamento,
          row.descricaoFormaPagamento,
          row.qtdVendas,
          row.valorParcela,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test(
      'resumo_parcela_por_usuario: full and progressive results are equivalent',
      () async {
        final repository = ResumoParcelaPorUsuarioRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        final filter = ResumoParcelaPorUsuarioFilter(
          dataVendaInicio: start,
          dataVendaFim: end,
        );
        await _verify<ResumoParcelaPorUsuarioRow>(
          name: 'resumo_parcela_por_usuario',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.nomeUsuario,
            row.qtdVendas,
            row.valorParcela,
          ],
          baseline: () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
          progressive: () => repository.loadProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test(
      'resumo_produto_venda: full and progressive results are equivalent',
      () async {
        final repository = ResumoProdutoVendaRepositoryImpl(
          _BypassCache(getIt<AgentQueriesRepository>()),
        );
        final filter = ResumoProdutoVendaFilter(
          dataVendaInicio: start,
          dataVendaFim: end,
          pageSize: _pageSize,
        );
        await _verify<ResumoProdutoVendaRow>(
          name: 'resumo_produto_venda',
          signature: (row) => [
            row.codEmpresa,
            row.codFilial,
            row.codProduto,
            row.nomeProduto,
            row.qtdVendas,
            row.qtdItensVendido,
            row.valorTotalCustoMedio,
            row.custoReposicao,
            row.pontoEquilibrio,
            row.valorTotalItem,
            row.codGrupoProduto,
            row.nomeGrupoProduto,
            row.codMarca,
            row.nomeMarca,
            row.codTipoGrupoProduto,
            row.descricaoTipoGrupoProduto,
          ],
          baseline: () => _pages(
            load: (page) => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              bridgeTimeoutMs: 60000,
              hubConnectedFromApprovedCatalogRow: true,
              filter: ResumoProdutoVendaFilter(
                dataVendaInicio: start,
                dataVendaFim: end,
                pageSize: _pageSize,
                page: page,
              ),
            ),
            items: (page) => page.items,
            total: (page) => page.totalCount,
          ),
          progressive: () => repository.loadPagesProgressively(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            bridgeTimeoutMs: 60000,
            hubConnectedFromApprovedCatalogRow: true,
            filter: filter,
          ),
        );
      },
      timeout: _reportTimeout,
    );

    test('resumo_total_vendas_municipio_filial_diario: full and progressive results are equivalent', () async {
      final repository = ResumoTotalVendasMunicipioFilialDiarioRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoTotalVendasMunicipioFilialDiarioFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoTotalVendasMunicipioFilialDiarioRow>(
        name: 'resumo_total_vendas_municipio_filial_diario',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.nomeFilial,
          row.codMunicipioFilial,
          row.nomeMunicipioFilial,
          row.ufMunicipioFilial,
          row.dataVenda,
          row.qtdVendas,
          row.totalVenda,
          row.nomeFantasiaFilial,
          row.cepFilial,
          row.codigoIbgeMunicipioFilial,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);

    test('resumo_vendas_diarias_por_vendedor: full and progressive results are equivalent', () async {
      final repository = ResumoVendasDiariasPorVendedorRepositoryImpl(
        _BypassCache(getIt<AgentQueriesRepository>()),
      );
      final filter = ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: start,
        dataVendaFim: end,
      );
      await _verify<ResumoVendasDiariasPorVendedorRow>(
        name: 'resumo_vendas_diarias_por_vendedor',
        signature: (row) => [
          row.codEmpresa,
          row.codFilial,
          row.dataVenda,
          row.anoMesDataVenda,
          row.codVendedor,
          row.nomeVendedor,
          row.qtdVendas,
          row.valorTotalVenda,
        ],
        baseline: () => repository.load(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
        progressive: () => repository.loadProgressively(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          bridgeTimeoutMs: 60000,
          hubConnectedFromApprovedCatalogRow: true,
          filter: filter,
        ),
      );
    }, timeout: _reportTimeout);
  });
}

Future<void> _verify<Row>({
  required String name,
  required List<Object?> Function(Row) signature,
  required Future<AppResult<List<Row>>> Function() baseline,
  required Stream<AppResult<AgentQueryProgress<Row>>> Function() progressive,
}) async {
  // ignore: avoid_print -- Only validation stages and counts are logged.
  print(
    'PROGRESSIVE_STAGE ${jsonEncode({'reportId': name, 'stage': 'baseline_start'})}',
  );
  final baselineResult = await baseline();
  final expected = baselineResult.getOrNull();
  if (expected == null) {
    fail(
      '$name baseline failed: ${_failureDescription(baselineResult.exceptionOrNull())}',
    );
  }
  // ignore: avoid_print -- No report content is logged.
  print(
    'PROGRESSIVE_STAGE ${jsonEncode({'reportId': name, 'stage': 'baseline_complete', 'rows': expected.length})}',
  );
  final partial = <Row>[];
  List<Row>? complete;
  final clock = Stopwatch()..start();
  double? firstMs;
  var batches = 0;
  // ignore: avoid_print -- No report content is logged.
  print(
    'PROGRESSIVE_STAGE ${jsonEncode({'reportId': name, 'stage': 'progressive_start'})}',
  );
  await for (final result in progressive()) {
    final event = result.getOrNull();
    if (event == null) {
      fail(
        '$name progressive failed: ${_failureDescription(result.exceptionOrNull())}',
      );
    }
    if (event.isComplete) {
      expect(complete, isNull);
      complete = event.rows;
    } else {
      expect(complete, isNull);
      firstMs ??= clock.elapsedMicroseconds / 1000;
      batches++;
      partial.addAll(event.rows);
      expect(event.receivedRowCount, partial.length);
      // ignore: avoid_print -- No report content is logged.
      print(
        'PROGRESSIVE_STAGE ${jsonEncode({'reportId': name, 'stage': 'partial', 'batch': batches, 'rows': partial.length, 'elapsedMs': clock.elapsedMilliseconds})}',
      );
    }
  }
  expect(complete, isNotNull);
  String digest(List<Row> rows) => sha256
      .convert(
        utf8.encode(
          jsonEncode(
            rows
                .map(
                  (row) =>
                      signature(row)
                          .map((v) => v is DateTime ? v.toIso8601String() : v)
                          .toList(),
                )
                .toList(),
          ),
        ),
      )
      .toString();
  expect(digest(complete!), digest(expected));
  if (partial.isNotEmpty) {
    expect(digest(partial), digest(complete.take(partial.length).toList()));
  }
  // ignore: avoid_print -- No report content is logged.
  print(
    'PROGRESSIVE_VALIDATION ${jsonEncode({'reportId': name, 'rows': complete.length, 'partialBatches': batches, 'firstMs': firstMs, 'completionMs': clock.elapsedMicroseconds / 1000, 'equivalent': true})}',
  );
}

String _failureDescription(AppFailure? failure) => jsonEncode({
  'type': failure.runtimeType.toString(),
  'causeType': failure?.cause.runtimeType.toString(),
  'reason': failure?.context['reason'],
  'category': failure?.context['category'],
  'uiKey': failure?.context[AgentSqlRpcFailureUiKey.field],
  'rpcCode': failure is RpcFailure ? failure.rpcCode : null,
  'httpStatusCode': failure?.context['httpStatusCode'],
  'deadlineExceeded': failure?.context['deadlineExceeded'] == true,
});

Future<AppResult<List<Row>>> _pages<Page extends Object, Row>({
  required Future<AppResult<Page>> Function(int) load,
  required List<Row> Function(Page) items,
  required int Function(Page) total,
}) async {
  final rows = <Row>[];
  int? expectedTotal;
  for (var page = 1; ; page++) {
    final clock = Stopwatch()..start();
    final result = await load(page);
    if (result.isError()) {
      return Failure(result.exceptionOrNull()!);
    }
    final value = result.getOrThrow();
    expectedTotal ??= total(value);
    expect(
      total(value),
      expectedTotal,
      reason: 'Catalog changed during baseline',
    );
    expect(total(value), greaterThanOrEqualTo(0));
    final maxRows = AppEnvironment.socketStreamSqlCollectorMaxBufferedRows;
    if (maxRows > 0) {
      expect(
        total(value),
        lessThanOrEqualTo(maxRows),
        reason: 'Baseline exceeds progressive memory limit',
      );
    }
    expect(items(value).length, lessThanOrEqualTo(_pageSize));
    rows.addAll(items(value));
    // ignore: avoid_print -- Only pagination counts and elapsed time are logged.
    print(
      'PROGRESSIVE_BASELINE_PAGE ${jsonEncode({'page': page, 'rows': rows.length, 'total': total(value), 'elapsedMs': clock.elapsedMilliseconds})}',
    );
    if (rows.length == total(value)) {
      return Success(rows);
    }
    expect(items(value), isNotEmpty);
    expect(rows.length, lessThan(total(value)));
    expect(
      rows.length,
      lessThanOrEqualTo(AppEnvironment.socketStreamSqlCollectorMaxBufferedRows),
    );
  }
}

class _BypassCache implements AgentQueriesRepository {
  _BypassCache(this.delegate);
  final AgentQueriesRepository delegate;
  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) => _measure(
    parent: cancelScope,
    execute: (scope) => delegate.executeSql(
      request.copyWith(
        skipTransportCache: true,
        useRelay:
            const String.fromEnvironment('E2E_PROGRESSIVE_ROUTE') == 'relay',
      ),
      cancelScope: scope,
    ),
  );
  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) => _measure(
    parent: cancelScope,
    execute: (scope) => delegate.executeSqlBatch(
      request.copyWith(
        skipTransportCache: true,
        useRelay:
            const String.fromEnvironment('E2E_PROGRESSIVE_ROUTE') == 'relay',
      ),
      cancelScope: scope,
    ),
  );

  Future<AppResult<T>> _measure<T extends Object>({
    required AgentQueriesCancelScope? parent,
    required Future<AppResult<T>> Function(AgentQueriesCancelScope) execute,
  }) async {
    final diagnostics = AgentQueryDiagnostics();
    final scope =
        AgentQueriesCancelScope(
            traceId: parent?.traceId,
            deadline: parent?.deadline,
            diagnostics: diagnostics,
            progressObserver: parent?.progressObserver,
          )
          ..relayCancelHandler = parent?.relayCancelHandler
          ..socketRpcCancelHandler = parent?.socketRpcCancelHandler
          ..streamingSqlCancelHandler = parent?.streamingSqlCancelHandler;
    final unregister = parent?.registerLocalCancellation(scope.cancelAll);
    try {
      final result = await execute(scope);
      final snapshot = diagnostics.toJson();
      // ignore: avoid_print -- Timings, routes and failure codes contain no report content.
      print(
        'PROGRESSIVE_REQUEST ${jsonEncode({...snapshot, 'success': result.isSuccess(), if (result.isError()) 'failure': jsonDecode(_failureDescription(result.exceptionOrNull()))})}',
      );
      if (result.isSuccess()) {
        final transport = snapshot['transport'] as String?;
        const relay =
            String.fromEnvironment('E2E_PROGRESSIVE_ROUTE') == 'relay';
        expect(transport, relay ? startsWith('relay') : 'rest');
        expect(snapshot['fallback'], false);
        expect(snapshot['cacheHit'], false);
      }
      return result;
    } finally {
      unregister?.call();
      diagnostics.complete();
    }
  }
}
