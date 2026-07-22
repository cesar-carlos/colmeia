import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql_v2.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_por_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/overview/data/overview_batch_command_builder.dart';
import 'package:colmeia/features/overview/domain/entities/overview_section_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = OverviewBatchCommandBuilder();

  final periodStart = DateTime(2026, 4);
  final periodEnd = DateTime(2026, 4, 30);
  final mensalFilter = ResumoParcelasMensalFilter(
    dataVendaInicio: periodStart,
    dataVendaFim: periodEnd,
  );
  final weekdayFilter = ResumoParcelasDiaSemanaFilter(
    dataVendaInicio: periodStart,
    dataVendaFim: periodEnd,
  );
  final dailyTotalFilter = ResumoTotalDiarioVendasFilter(
    dataVendaInicio: periodStart,
    dataVendaFim: periodEnd,
  );

  group('OverviewBatchCommandBuilder', () {
    test('buildMainCommands returns payment resumo and user ranking', () {
      final batch = builder.buildMainCommands(
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      check(
        batch.commands.length,
      ).equals(OverviewBatchCommandBuilder.mainBatchCommandCount);
      check(
        batch.commands[0].sql,
      ).equals(ResumoParcelaFormaPagamentoSqlV2.query);
      check(batch.commands[1].sql).equals(ResumoParcelaPorUsuarioSql.query);
      check(batch.indexes.main).equals(0);
      check(batch.indexes.userRanking).equals(1);
      check(
        batch.commands[0].namedParams['dataVendaInicio'],
      ).equals('2026-04-01');
      check(batch.commands[0].namedParams['dataVendaFim']).equals('2026-04-30');
    });

    test('buildMainCommands can omit payment resumo for slim home', () {
      final batch = builder.buildMainCommands(
        periodStart: periodStart,
        periodEnd: periodEnd,
        includePaymentResumo: false,
      );

      check(batch.commands.length).equals(1);
      check(batch.commands.single.sql).equals(ResumoParcelaPorUsuarioSql.query);
      check(batch.indexes.paymentResumo).isNull();
      check(batch.indexes.userRanking).equals(0);
    });

    test('buildMainCommands can load payment resumo only for mix card', () {
      final batch = builder.buildMainCommands(
        periodStart: periodStart,
        periodEnd: periodEnd,
        includeUserRanking: false,
      );

      check(batch.commands.length).equals(1);
      check(
        batch.commands.single.sql,
      ).equals(ResumoParcelaFormaPagamentoSqlV2.query);
      check(batch.indexes.paymentResumo).equals(0);
      check(batch.indexes.userRanking).isNull();
    });

    test('buildCommands includes all sections when nothing is omitted', () {
      final batch = builder.buildCommands(
        periodStart: periodStart,
        periodEnd: periodEnd,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
      );

      check(batch.commands.length).equals(7);
      final sqlBodies = batch.commands.map((command) => command.sql).toList();
      check(
        sqlBodies.contains(ResumoParcelaFormaPagamentoSqlV2.query),
      ).isTrue();
      check(sqlBodies.contains(ResumoParcelaPorUsuarioSql.query)).isTrue();
      check(
        sqlBodies.any(
          (sql) =>
              sql.contains(ResumoParcelasMensalSql.query().split('\n').first),
        ),
      ).isTrue();
      check(
        sqlBodies.any(
          (sql) => sql.contains(
            ResumoParcelasDiaSemanaSql.query().split('\n').first,
          ),
        ),
      ).isTrue();
      check(sqlBodies.contains(ResumoTotalDiarioVendasSql.query)).isTrue();
      check(
        sqlBodies.any(
          (sql) => sql.contains(
            ResumoParcelasDiaSemanaUsuarioSql.query().split('\n').first,
          ),
        ),
      ).isTrue();
      check(
        sqlBodies.contains(ResumoProdutoVendaLucratividadeSql.query),
      ).isTrue();
      check(batch.indexes.lucratividade).isNotNull();
    });

    test('buildCommands omits cached sections when configured', () {
      final batch = builder.buildCommands(
        periodStart: periodStart,
        periodEnd: periodEnd,
        mensalFilter: mensalFilter,
        weekdayFilter: weekdayFilter,
        dailyTotalFilter: dailyTotalFilter,
        omitCachedSectionsFromSqlBatch: const OverviewCachedSectionSqlOmission(
          dailyMonthly: true,
          weekday: true,
          lucratividade: true,
        ),
      );

      check(batch.commands.length).equals(3);
      check(batch.indexes.monthly).isNull();
      check(batch.indexes.weekday).isNull();
      check(batch.indexes.daily).isNull();
      check(batch.indexes.lucratividade).isNull();
      check(batch.indexes.weekdayUser).equals(2);
    });

    test(
      'buildSectionCommands for home scope includes only monthly parcels',
      () {
        final batch = builder.buildSectionCommands(
          mensalFilter: mensalFilter,
          weekdayFilter: weekdayFilter,
          dailyTotalFilter: dailyTotalFilter,
          includedSectionBatchSections:
              OverviewSectionRequest.home.sectionBatchSections,
          includeMainBatch: false,
        );

        check(batch.commands.length).equals(1);
        check(
          batch.commands.single.sql.contains(
            ResumoParcelasMensalSql.query().split('\n').first,
          ),
        ).isTrue();
        check(batch.indexes.monthly).equals(0);
        check(batch.indexes.daily).isNull();
        check(batch.indexes.weekday).isNull();
        check(batch.indexes.weekdayUser).isNull();
        check(batch.indexes.lucratividade).isNull();
      },
    );

    test(
      'buildSectionCommands skips main commands and reindexes execution order',
      () {
        final batch = builder.buildSectionCommands(
          mensalFilter: mensalFilter,
          weekdayFilter: weekdayFilter,
          dailyTotalFilter: dailyTotalFilter,
        );

        check(batch.commands.length).equals(5);
        check(batch.commands.first.executionOrder).equals(0);
        check(batch.commands.last.executionOrder).equals(4);
        check(batch.indexes.monthly).equals(0);
        check(batch.indexes.weekdayUser).equals(3);
        check(batch.indexes.lucratividade).equals(4);
      },
    );
  });
}
