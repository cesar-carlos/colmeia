import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';

class NotaEntradaResumoFornecedorRowModel {
  const NotaEntradaResumoFornecedorRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codFornecedor,
    required this.nomeFornecedor,
    required this.qtdNotas,
    required this.ticketMedio,
    required this.valorTotalCompra,
    this.nomeFantasiaFilial,
    this.nomeFantasiaFornecedor,
    this.cnpjCpfFornecedor,
  });

  factory NotaEntradaResumoFornecedorRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return NotaEntradaResumoFornecedorRowModel(
      codEmpresa: _requiredInt(map, 'CodEmpresa'),
      codFilial: _requiredInt(map, 'CodFilial'),
      nomeFilial: _requiredString(map, 'NomeFilial'),
      nomeFantasiaFilial: _optionalString(map, 'NomeFantasiaFilial'),
      codFornecedor: _requiredInt(map, 'CodFornecedor'),
      nomeFornecedor: _requiredString(map, 'NomeFornecedor'),
      nomeFantasiaFornecedor: _optionalString(map, 'NomeFantasiaFornecedor'),
      cnpjCpfFornecedor: _optionalString(map, 'CnpjCpfFornecedor'),
      qtdNotas: _requiredInt(map, 'QtdNotas'),
      ticketMedio: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        _keys('TicketMedio'),
      ),
      valorTotalCompra: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        _keys('ValorTotalCompra'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final int codFornecedor;
  final String nomeFornecedor;
  final String? nomeFantasiaFornecedor;
  final String? cnpjCpfFornecedor;
  final int qtdNotas;
  final double ticketMedio;
  final double valorTotalCompra;

  NotaEntradaResumoFornecedorRow toEntity() {
    return NotaEntradaResumoFornecedorRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: nomeFilial,
      nomeFantasiaFilial: nomeFantasiaFilial,
      codFornecedor: codFornecedor,
      nomeFornecedor: nomeFornecedor,
      nomeFantasiaFornecedor: nomeFantasiaFornecedor,
      cnpjCpfFornecedor: cnpjCpfFornecedor,
      qtdNotas: qtdNotas,
      ticketMedio: ticketMedio,
      valorTotalCompra: valorTotalCompra,
    );
  }

  static int _requiredInt(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readRequiredInt(map, _keys(field));
  }

  static String _requiredString(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
      map,
      _keys(field),
    );
  }

  static String? _optionalString(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
      map,
      _keys(field),
    );
  }

  static List<String> _keys(String field) {
    return AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(field);
  }
}
