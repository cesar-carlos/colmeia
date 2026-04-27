import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default (codProduto ASC) leads with empresa, filial, produto then qtdVendas DESC', () {
    final sql = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.codProduto,
    );
    final numbered = sql.split('Numbered AS (').last;
    final empresa = numbered.indexOf('a.CodEmpresa ASC');
    final filial = numbered.indexOf('a.CodFilial ASC');
    final produto = numbered.indexOf('a.CodProduto ASC');
    final qtd = numbered.indexOf('a.QtdVendas DESC');
    check(empresa).isLessThan(filial);
    check(filial).isLessThan(produto);
    check(produto).isLessThan(qtd);
  });

  test('qtdVendas sortBy places QtdVendas after empresa/filial', () {
    final sql = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.qtdVendas,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    final numbered = sql.split('Numbered AS (').last;
    final empresa = numbered.indexOf('a.CodEmpresa ASC');
    final filial = numbered.indexOf('a.CodFilial ASC');
    final qtd = numbered.indexOf('a.QtdVendas DESC');
    check(empresa).isLessThan(filial);
    check(filial).isLessThan(qtd);
  });

  test('nomeProduto sortBy places NomeProduto after empresa/filial', () {
    final sql = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.nomeProduto,
    );
    final numbered = sql.split('Numbered AS (').last;
    final empresa = numbered.indexOf('a.CodEmpresa ASC');
    final filial = numbered.indexOf('a.CodFilial ASC');
    final nome = numbered.indexOf('a.NomeProduto ASC');
    check(empresa).isLessThan(filial);
    check(filial).isLessThan(nome);
  });

  test('sortDirection DESC applies to chosen sort column', () {
    final sqlDesc = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.codProduto,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    check(sqlDesc).contains('a.CodProduto DESC');

    final sqlAsc = ResumoProdutoVendaSql.pagedQuery(
      sortBy: ResumoProdutoVendaSortBy.nomeProduto,
      sortDirection: ResumoProdutoVendaSortDirection.descending,
    );
    check(sqlAsc).contains('a.NomeProduto DESC');
  });

  test('CodEmpresa and CodFilial are always present and always ASC', () {
    for (final sortBy in ResumoProdutoVendaSortBy.values) {
      final sql = ResumoProdutoVendaSql.pagedQuery(sortBy: sortBy);
      check(sql).contains('a.CodEmpresa ASC');
      check(sql).contains('a.CodFilial ASC');
    }
  });
}
