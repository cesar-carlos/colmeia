import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

class ResumoParcelasMensalRowModel {
  const ResumoParcelasMensalRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.ano,
    required this.mes,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelasMensalRowModel.fromMap(Map<String, dynamic> map) {
    final ano = AgentQueriesSqlRowMapReader.readRequiredInt(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Ano'),
    );
    final mes = AgentQueriesSqlRowMapReader.readRequiredInt(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Mes'),
    );
    final anoMesRaw = AgentQueriesSqlRowMapReader.lookupFirst(
      map,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('AnoMes'),
    );
    if (anoMesRaw != null) {
      final actual = switch (anoMesRaw) {
        final String s => s.trim(),
        _ => anoMesRaw.toString().trim(),
      };
      if (!_anoMesConsistentWithCalendarMonth(actual, ano, mes)) {
        final expected = ResumoParcelasMensalLabels.format(ano, mes);
        throw FormatException(
          'AnoMes "$actual" does not match Ano/Mes (expected "$expected")',
        );
      }
    }
    return ResumoParcelasMensalRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      ano: ano,
      mes: mes,
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      valorParcela: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorParcela'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int ano;
  final int mes;
  final int qtdVendas;
  final double valorParcela;

  /// When [raw] looks like `YYYY/MM`, require it to match [ano] and [mes].
  /// Non-matching shapes are ignored so drivers that omit padding or send
  /// odd spacing do not fail parsing while `Ano` / `Mes` stay authoritative.
  static bool _anoMesConsistentWithCalendarMonth(
    String raw,
    int ano,
    int mes,
  ) {
    final match = RegExp(
      r'^\s*(\d{4})\s*/\s*(\d{1,2})\s*$',
    ).firstMatch(raw);
    if (match == null) {
      return true;
    }
    final y = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (y == null || m == null || m < 1 || m > 12) {
      return true;
    }
    return y == ano && m == mes;
  }

  ResumoParcelasMensalRow toEntity() {
    return ResumoParcelasMensalRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      ano: ano,
      mes: mes,
      anoMes: ResumoParcelasMensalLabels.format(ano, mes),
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }
}
