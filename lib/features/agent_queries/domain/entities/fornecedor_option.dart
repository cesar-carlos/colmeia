/// One fornecedor row from the agent SQL catalog used by autocomplete UIs.
class FornecedorOption {
  const FornecedorOption({
    required this.codFornecedor,
    required this.nomeFornecedor,
    required this.nomeMunicipio,
    required this.ufMunicipio,
    this.codigoIbge,
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
  });

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

  String get municipioDisplay => '$nomeMunicipio - $ufMunicipio';

  /// Primary label for dropdowns and async search fields.
  String get displayLabel {
    final suffixParts = <String>[];
    final fantasy = nomeFantasia?.trim();
    if (fantasy != null &&
        fantasy.isNotEmpty &&
        fantasy.toUpperCase() != nomeFornecedor.toUpperCase()) {
      suffixParts.add(fantasy);
    }
    final cnpj = cnpjCpf?.trim();
    if (cnpj != null && cnpj.isNotEmpty) {
      suffixParts.add(cnpj);
    }
    if (suffixParts.isEmpty) {
      return nomeFornecedor;
    }
    return '$nomeFornecedor (${suffixParts.join(' · ')})';
  }
}
