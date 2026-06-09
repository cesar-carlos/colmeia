import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/fornecedor_option.dart';

class FornecedorOptionModel {
  const FornecedorOptionModel({
    required this.codFornecedor,
    required this.nomeFornecedor,
    required this.nomeMunicipio,
    required this.ufMunicipio,
    this.nomeFantasia,
    this.cnpjCpf,
    this.email,
    this.telefone,
    this.endereco,
    this.numeroEndereco,
    this.bairro,
    this.complemento,
    this.cep,
    this.codMunicipio,
    this.codigoIbge,
  });

  factory FornecedorOptionModel.fromMap(Map<String, dynamic> map) {
    return FornecedorOptionModel(
      codFornecedor: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFornecedor'),
      ),
      nomeFornecedor: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFornecedor'),
      ),
      nomeFantasia: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFantasia'),
      ),
      cnpjCpf: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CNPJ_CPF'),
      ),
      email: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('EMail'),
      ),
      telefone: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Telefone'),
      ),
      endereco: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Endereco'),
      ),
      numeroEndereco: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NumeroEndereco'),
      ),
      bairro: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Bairro'),
      ),
      complemento: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Complemento'),
      ),
      cep: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CEP'),
      ),
      codMunicipio: AgentQueriesSqlRowMapReader.readOptionalInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipio'),
      ),
      nomeMunicipio: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeMunicipio'),
      ),
      ufMunicipio: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('UFMunicipio'),
      ),
      codigoIbge: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodigoIBGE'),
      ),
    );
  }

  final int codFornecedor;
  final String nomeFornecedor;
  final String? nomeFantasia;
  final String? cnpjCpf;
  final String? email;
  final String? telefone;
  final String? endereco;
  final String? numeroEndereco;
  final String? bairro;
  final String? complemento;
  final String? cep;
  final int? codMunicipio;
  final String nomeMunicipio;
  final String ufMunicipio;
  final String? codigoIbge;

  FornecedorOption toEntity() {
    return FornecedorOption(
      codFornecedor: codFornecedor,
      nomeFornecedor: nomeFornecedor,
      nomeFantasia: nomeFantasia,
      cnpjCpf: cnpjCpf,
      email: email,
      telefone: telefone,
      endereco: endereco,
      numeroEndereco: numeroEndereco,
      bairro: bairro,
      complemento: complemento,
      cep: cep,
      codMunicipio: codMunicipio,
      nomeMunicipio: nomeMunicipio,
      ufMunicipio: ufMunicipio,
      codigoIbge: codigoIbge,
    );
  }
}
