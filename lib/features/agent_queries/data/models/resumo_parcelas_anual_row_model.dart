import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

class ResumoParcelasAnualRowModel {
  const ResumoParcelasAnualRowModel({
    required this.ano,
    required this.quantidade,
    required this.valorTotal,
  });

  factory ResumoParcelasAnualRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelasAnualRowModel(
      ano: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Ano'),
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
  final int quantidade;
  final double valorTotal;

  ResumoParcelasAnualRow toEntity() {
    return ResumoParcelasAnualRow(
      ano: ano,
      quantidade: quantidade,
      valorTotal: valorTotal,
    );
  }
}
