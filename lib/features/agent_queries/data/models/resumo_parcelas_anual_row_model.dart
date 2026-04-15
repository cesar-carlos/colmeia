import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

class ResumoParcelasAnualRowModel {
  const ResumoParcelasAnualRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.anoDataVenda,
    required this.qtdVendas,
    required this.valorTotalVenda,
  });

  factory ResumoParcelasAnualRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelasAnualRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      anoDataVenda: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('AnoDataVenda'),
      ),
      qtdVendas: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('QtdVendas'),
      ),
      valorTotalVenda: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('ValorTotalVenda'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int anoDataVenda;
  final int qtdVendas;
  final double valorTotalVenda;

  ResumoParcelasAnualRow toEntity() {
    return ResumoParcelasAnualRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      anoDataVenda: anoDataVenda,
      qtdVendas: qtdVendas,
      valorTotalVenda: valorTotalVenda,
    );
  }
}
