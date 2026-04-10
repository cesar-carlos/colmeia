import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_labels.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';

class ResumoParcelasMensalRowModel {
  const ResumoParcelasMensalRowModel({
    required this.ano,
    required this.mes,
    required this.quantidade,
    required this.valorTotal,
  });

  factory ResumoParcelasMensalRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelasMensalRowModel(
      ano: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Ano'),
      ),
      mes: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Mes'),
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

  final int ano;
  final int mes;
  final int quantidade;
  final double valorTotal;

  ResumoParcelasMensalRow toEntity() {
    return ResumoParcelasMensalRow(
      ano: ano,
      mes: mes,
      anoMes: ResumoParcelasMensalLabels.format(ano, mes),
      quantidade: quantidade,
      valorTotal: valorTotal,
    );
  }
}
