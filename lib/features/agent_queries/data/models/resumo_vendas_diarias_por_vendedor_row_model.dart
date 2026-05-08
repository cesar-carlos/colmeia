import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';

class ResumoVendasDiariasPorVendedorRowModel {
  const ResumoVendasDiariasPorVendedorRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.dataVenda,
    required this.anoMesDataVenda,
    required this.qtdVendas,
    required this.valorTotalVenda,
    this.codVendedor,
    this.nomeVendedor,
  });

  factory ResumoVendasDiariasPorVendedorRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoVendasDiariasPorVendedorRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      dataVenda: AgentQueriesSqlRowMapReader.readDataVendaCalendarDate(map),
      anoMesDataVenda: AgentQueriesSqlRowMapReader.readRequiredAnoMesDataVenda(
        map,
      ),
      codVendedor: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodVendedor'),
      ),
      nomeVendedor: AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeVendedor'),
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
  final DateTime dataVenda;
  final String anoMesDataVenda;
  final int? codVendedor;
  final String? nomeVendedor;
  final int qtdVendas;
  final double valorTotalVenda;

  ResumoVendasDiariasPorVendedorRow toEntity() {
    return ResumoVendasDiariasPorVendedorRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      dataVenda: dataVenda,
      anoMesDataVenda: anoMesDataVenda,
      codVendedor: codVendedor,
      nomeVendedor: nomeVendedor,
      qtdVendas: qtdVendas,
      valorTotalVenda: valorTotalVenda,
    );
  }
}
