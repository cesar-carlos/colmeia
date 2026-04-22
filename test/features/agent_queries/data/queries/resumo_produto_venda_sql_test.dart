import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row_number_ordering.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pagedQuery ROW_NUMBER metric matches sortBy (default DESC)', () {
    check(
      ResumoProdutoVendaSql.pagedQuery(
        sortBy: ResumoProdutoVendaSortBy.qtdVendas,
      ),
    ).contains('a.QtdVendas DESC');
    check(
      ResumoProdutoVendaSql.pagedQuery(
        sortBy: ResumoProdutoVendaSortBy.qtdItensVendido,
      ),
    ).contains('a.QtdItensVendido DESC');
    check(
      ResumoProdutoVendaSql.pagedQuery(
        sortBy: ResumoProdutoVendaSortBy.percentualLucro,
      ),
    ).contains('a.PercentualLucro DESC');
  });

  test('pagedQuery sortDirection ASC applies to metric only', () {
    final sql = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.qtdVendas,
      sortDirection: ResumoProdutoVendaSortDirection.ascending,
    );
    check(sql).contains('a.QtdVendas ASC');
    check(sql).contains('a.CodEmpresa ASC');
    check(sql).contains('a.CodFilial ASC');
  });

  test('pagedQuery metricGlobal orders metric before empresa/filial', () {
    final sql = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.qtdVendas,
      rowNumberOrdering: ResumoProdutoVendaRowNumberOrdering.metricGlobal,
    );
    final numbered = sql.split('Numbered AS (').last;
    final metric = numbered.indexOf('a.QtdVendas DESC');
    final empresa = numbered.indexOf('a.CodEmpresa ASC');
    check(metric).isLessThan(empresa);
  });

  test('pagedQuery ledgerDefault orders empresa/filial before metric', () {
    final sql = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.qtdVendas,
    );
    final numbered = sql.split('Numbered AS (').last;
    final metric = numbered.indexOf('a.QtdVendas DESC');
    final empresa = numbered.indexOf('a.CodEmpresa ASC');
    check(empresa).isLessThan(metric);
  });
}
