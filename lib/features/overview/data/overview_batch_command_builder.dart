import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_forma_pagamento_sql_v2.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcela_por_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';

final class OverviewCachedSectionSqlOmission {
  const OverviewCachedSectionSqlOmission({
    this.dailyMonthly = false,
    this.weekday = false,
    this.lucratividade = false,
  });

  final bool dailyMonthly;
  final bool weekday;
  final bool lucratividade;
}

final class OverviewBatchCommandIndexes {
  const OverviewBatchCommandIndexes({
    required this.main,
    required this.userRanking,
    required this.monthly,
    required this.weekday,
    required this.daily,
    required this.lucratividade,
    this.weekdayUser,
    this.lucratividadeMensal,
  });

  final int main;
  final int userRanking;
  final int? monthly;
  final int? weekday;
  final int? daily;
  final int? lucratividade;
  final int? weekdayUser;
  final int? lucratividadeMensal;
}

final class OverviewMainBatchCommandIndexes {
  const OverviewMainBatchCommandIndexes({
    required this.main,
    required this.userRanking,
  });

  final int main;
  final int userRanking;
}

final class OverviewSectionBatchCommandIndexes {
  const OverviewSectionBatchCommandIndexes({
    this.weekday,
    this.weekdayUser,
    this.lucratividade,
    this.monthly,
    this.daily,
    this.lucratividadeMensal,
  });

  final int? monthly;
  final int? weekday;
  final int? daily;
  final int? weekdayUser;
  final int? lucratividade;
  final int? lucratividadeMensal;
}

final class OverviewBatchCommands {
  const OverviewBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final OverviewBatchCommandIndexes indexes;
}

final class OverviewMainBatchCommands {
  const OverviewMainBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final OverviewMainBatchCommandIndexes indexes;
}

final class OverviewSectionBatchCommands {
  const OverviewSectionBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final OverviewSectionBatchCommandIndexes indexes;
}

/// Builds ordered `sql.executeBatch` command lists for overview home loads.
final class OverviewBatchCommandBuilder {
  const OverviewBatchCommandBuilder();

  /// Main phased batch always issues payment resumo + per-user ranking.
  static const int mainBatchCommandCount = 2;

  OverviewMainBatchCommands buildMainCommands({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final parcelPeriodParams = _parcelPeriodSqlParamsFromPeriodo(
      ResumoParcelaFormaPagamentoFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );
    final main = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoParcelaFormaPagamentoSqlV2.query,
        namedParams: parcelPeriodParams,
        executionOrder: main,
      ),
    );
    final userRanking = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoParcelaPorUsuarioSql.query,
        namedParams: parcelPeriodParams,
        executionOrder: userRanking,
      ),
    );
    return OverviewMainBatchCommands(
      commands: commands,
      indexes: OverviewMainBatchCommandIndexes(
        main: main,
        userRanking: userRanking,
      ),
    );
  }

  OverviewSectionBatchCommands buildSectionCommands({
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    OverviewCachedSectionSqlOmission omitCachedSectionsFromSqlBatch =
        const OverviewCachedSectionSqlOmission(),
    Set<OverviewProgressiveSection>? includedSectionBatchSections,
    bool includeMainBatch = true,
  }) {
    final mainOffset = includeMainBatch ? mainBatchCommandCount : 0;
    final full = buildCommands(
      periodStart: dailyTotalFilter.dataVendaInicio,
      periodEnd: dailyTotalFilter.dataVendaFim,
      last12Range: last12Range,
      mensalFilter: mensalFilter,
      weekdayFilter: weekdayFilter,
      dailyTotalFilter: dailyTotalFilter,
      includeLucratividadeMensal: includeLucratividadeMensal,
      omitCachedSectionsFromSqlBatch: omitCachedSectionsFromSqlBatch,
      includedSectionBatchSections: includedSectionBatchSections,
      includeMainBatch: includeMainBatch,
    );
    final commands = full.commands.skip(mainOffset).toList(growable: false);
    for (var i = 0; i < commands.length; i++) {
      final command = commands[i];
      commands[i] = AgentSqlExecuteBatchCommand(
        sql: command.sql,
        namedParams: command.namedParams,
        executionOrder: i,
      );
    }
    return OverviewSectionBatchCommands(
      commands: commands,
      indexes: _sectionIndexesFromFull(full.indexes, mainOffset: mainOffset),
    );
  }

  OverviewBatchCommands buildCommands({
    required DateTime periodStart,
    required DateTime periodEnd,
    required ({DateTime dataVendaInicio, DateTime dataVendaFim}) last12Range,
    required ResumoParcelasMensalFilter mensalFilter,
    required ResumoParcelasDiaSemanaFilter weekdayFilter,
    required ResumoTotalDiarioVendasFilter dailyTotalFilter,
    required bool includeLucratividadeMensal,
    OverviewCachedSectionSqlOmission omitCachedSectionsFromSqlBatch =
        const OverviewCachedSectionSqlOmission(),
    Set<OverviewProgressiveSection>? includedSectionBatchSections,
    bool includeMainBatch = true,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];

    int add(String sql, Map<String, Object?> namedParams) {
      final index = commands.length;
      commands.add(
        AgentSqlExecuteBatchCommand(
          sql: sql,
          namedParams: namedParams,
          executionOrder: index,
        ),
      );
      return index;
    }

    final int main;
    final int userRanking;
    if (includeMainBatch) {
      main = add(
        ResumoParcelaFormaPagamentoSqlV2.query,
        _parcelPeriodSqlParamsFromPeriodo(
          ResumoParcelaFormaPagamentoFilter(
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          ),
        ),
      );
      userRanking = add(
        ResumoParcelaPorUsuarioSql.query,
        _parcelPeriodSqlParamsFromPeriodo(
          ResumoParcelaFormaPagamentoFilter(
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          ),
        ),
      );
    } else {
      main = 0;
      userRanking = 0;
    }

    bool includesSection(OverviewProgressiveSection section) {
      return includedSectionBatchSections == null ||
          includedSectionBatchSections.contains(section);
    }

    final int? monthly;
    if (includesSection(OverviewProgressiveSection.monthlyParcels) &&
        !omitCachedSectionsFromSqlBatch.dailyMonthly) {
      monthly = add(
        ResumoParcelasMensalSql.query(
          codEmpresa: mensalFilter.codEmpresa,
          codFilial: mensalFilter.codFilial,
          codVendedor: mensalFilter.codVendedor,
        ),
        _parcelPeriodSqlParamsFromMensal(mensalFilter),
      );
    } else {
      monthly = null;
    }
    final int? weekday;
    if (includesSection(OverviewProgressiveSection.weekdaySales) &&
        !omitCachedSectionsFromSqlBatch.weekday) {
      weekday = add(
        ResumoParcelasDiaSemanaSql.query(
          codEmpresa: weekdayFilter.codEmpresa,
          codFilial: weekdayFilter.codFilial,
          codVendedor: weekdayFilter.codVendedor,
        ),
        _parcelPeriodSqlParamsFromWeekday(weekdayFilter),
      );
    } else {
      weekday = null;
    }
    final int? daily;
    if (includesSection(OverviewProgressiveSection.dailySales) &&
        !omitCachedSectionsFromSqlBatch.dailyMonthly) {
      daily = add(
        ResumoTotalDiarioVendasSql.query,
        _produtoVendidoPeriodParams(dailyTotalFilter),
      );
    } else {
      daily = null;
    }
    final int? weekdayUser;
    if (includesSection(OverviewProgressiveSection.weekdayUserSales)) {
      weekdayUser = add(
        ResumoParcelasDiaSemanaUsuarioSql.query(
          codEmpresa: weekdayFilter.codEmpresa,
          codFilial: weekdayFilter.codFilial,
          codVendedor: weekdayFilter.codVendedor,
        ),
        _parcelPeriodSqlParamsFromWeekday(weekdayFilter),
      );
    } else {
      weekdayUser = null;
    }
    final lucratividadePeriodFilter = ResumoProdutoVendaLucratividadeFilter(
      dataVendaInicio: periodStart,
      dataVendaFim: periodEnd,
    );
    final lucratividadeMensalFilter = ResumoProdutoVendaLucratividadeFilter(
      dataVendaInicio: last12Range.dataVendaInicio,
      dataVendaFim: last12Range.dataVendaFim,
    );
    final int? lucratividade;
    if (includesSection(OverviewProgressiveSection.lucratividadePeriod) &&
        !omitCachedSectionsFromSqlBatch.lucratividade) {
      lucratividade = add(
        ResumoProdutoVendaLucratividadeSql.query,
        _lucratividadeParams(lucratividadePeriodFilter),
      );
    } else {
      lucratividade = null;
    }
    final int? lucratividadeMensal;
    if (includeLucratividadeMensal &&
        includesSection(OverviewProgressiveSection.lucratividadeMensal)) {
      lucratividadeMensal = add(
        ResumoProdutoVendaLucratividadeMensalSql.query,
        _lucratividadeParams(lucratividadeMensalFilter),
      );
    } else {
      lucratividadeMensal = null;
    }

    return OverviewBatchCommands(
      commands: commands,
      indexes: OverviewBatchCommandIndexes(
        main: main,
        userRanking: userRanking,
        monthly: monthly,
        weekday: weekday,
        daily: daily,
        weekdayUser: weekdayUser,
        lucratividade: lucratividade,
        lucratividadeMensal: lucratividadeMensal,
      ),
    );
  }

  OverviewSectionBatchCommandIndexes _sectionIndexesFromFull(
    OverviewBatchCommandIndexes full, {
    required int mainOffset,
  }) {
    int? subtract(int? index) =>
        index == null ? null : index - mainOffset;
    return OverviewSectionBatchCommandIndexes(
      monthly: subtract(full.monthly),
      weekday: subtract(full.weekday),
      daily: subtract(full.daily),
      weekdayUser: full.weekdayUser == null
          ? null
          : full.weekdayUser! - mainOffset,
      lucratividade: subtract(full.lucratividade),
      lucratividadeMensal: subtract(full.lucratividadeMensal),
    );
  }

  Map<String, Object?> _parcelPeriodSqlParamsFromPeriodo(
    ResumoParcelasPeriodoFilter filter,
  ) {
    return <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
      'geraFinanceiro': filter.trimmedGeraFinanceiro,
      'preVenda': filter.trimmedPreVenda,
    };
  }

  Map<String, Object?> _parcelPeriodSqlParamsFromMensal(
    ResumoParcelasMensalFilter filter,
  ) {
    return _parcelPeriodSqlParamsFromPeriodo(
      ResumoParcelasPeriodoFilter(
        dataVendaInicio: filter.dataVendaInicio,
        dataVendaFim: filter.dataVendaFim,
        origem: filter.origem,
        geraFinanceiro: filter.geraFinanceiro,
        preVenda: filter.preVenda,
      ),
    );
  }

  Map<String, Object?> _parcelPeriodSqlParamsFromWeekday(
    ResumoParcelasDiaSemanaFilter filter,
  ) {
    return _parcelPeriodSqlParamsFromPeriodo(
      ResumoParcelasPeriodoFilter(
        dataVendaInicio: filter.dataVendaInicio,
        dataVendaFim: filter.dataVendaFim,
        origem: filter.origem,
        geraFinanceiro: filter.geraFinanceiro,
        preVenda: filter.preVenda,
      ),
    );
  }

  Map<String, Object?> _produtoVendidoPeriodParams(
    ResumoTotalDiarioVendasFilter filter,
  ) {
    return <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
      'geraFinanceiro': filter.trimmedGeraFinanceiro,
      'preVenda': filter.trimmedPreVenda,
    };
  }

  Map<String, Object?> _lucratividadeParams(
    ResumoProdutoVendaLucratividadeFilter filter,
  ) {
    return <String, Object?>{
      'dataVendaInicio': AgentQueriesSqlLocalDate.format(
        filter.dataVendaInicio,
      ),
      'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
      'origem': filter.trimmedOrigem,
    };
  }
}
