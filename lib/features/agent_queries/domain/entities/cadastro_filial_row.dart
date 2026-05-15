/// Branch registration row loaded directly from `Filial`.
class CadastroFilialRow {
  const CadastroFilialRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    this.nomeFantasia,
    this.cnpj,
    this.endereco,
    this.numeroEndereco,
    this.bairro,
    this.cep,
    this.codMunicipio,
    this.nomeMunicipio,
    this.codigoIbge,
    this.ufMunicipio,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasia;
  final String? cnpj;
  final String? endereco;
  final String? numeroEndereco;
  final String? bairro;
  final String? cep;
  final int? codMunicipio;
  final String? nomeMunicipio;
  final String? codigoIbge;
  final String? ufMunicipio;
}
