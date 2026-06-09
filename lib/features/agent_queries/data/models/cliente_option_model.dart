import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_option.dart';

class ClienteOptionModel {
  const ClienteOptionModel({
    required this.codCliente,
    required this.nomeCliente,
    required this.nomeMunicipio,
    required this.ufMunicipio,
    this.nomeFantasia,
    this.cnpjCpf,
    this.email,
    this.telefone,
    this.celular,
    this.endereco,
    this.numeroEndereco,
    this.bairro,
    this.complemento,
    this.cep,
    this.codMunicipio,
    this.codigoIbge,
  });

  factory ClienteOptionModel.fromMap(Map<String, dynamic> map) {
    return ClienteOptionModel(
      codCliente: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodCliente'),
      ),
      nomeCliente: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeCliente'),
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
      celular: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Celular'),
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

  final int codCliente;
  final String nomeCliente;
  final String? nomeFantasia;
  final String? cnpjCpf;
  final String? email;
  final String? telefone;
  final String? celular;
  final String? endereco;
  final String? numeroEndereco;
  final String? bairro;
  final String? complemento;
  final String? cep;
  final int? codMunicipio;
  final String nomeMunicipio;
  final String ufMunicipio;
  final String? codigoIbge;

  ClienteOption toEntity() {
    return ClienteOption(
      codCliente: codCliente,
      nomeCliente: nomeCliente,
      nomeFantasia: nomeFantasia,
      cnpjCpf: cnpjCpf,
      email: email,
      nomeMunicipio: nomeMunicipio,
      ufMunicipio: ufMunicipio,
      codigoIbge: codigoIbge,
    );
  }
}
