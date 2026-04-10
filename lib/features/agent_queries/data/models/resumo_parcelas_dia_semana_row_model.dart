import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';

class ResumoParcelasDiaSemanaRowModel {
  const ResumoParcelasDiaSemanaRowModel({
    required this.diaSemanaNumero,
    required this.diaSemana,
    required this.quantidade,
    required this.valorTotal,
  });

  factory ResumoParcelasDiaSemanaRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelasDiaSemanaRowModel(
      diaSemanaNumero: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('DiaSemanaNumero'),
      ),
      diaSemana: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('DiaSemana'),
      ),
      quantidade: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Quantidade'),
      ),
      valorTotal: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotal'),
      ),
    );
  }

  final int diaSemanaNumero;
  final String diaSemana;
  final int quantidade;
  final double valorTotal;

  ResumoParcelasDiaSemanaRow toEntity() {
    return ResumoParcelasDiaSemanaRow(
      diaSemanaNumero: diaSemanaNumero,
      diaSemana: ResumoParcelasDiaSemanaLabels.labelFor(diaSemanaNumero),
      quantidade: quantidade,
      valorTotal: valorTotal,
    );
  }
}
