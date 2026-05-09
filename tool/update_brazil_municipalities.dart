import 'dart:convert';
import 'dart:io';

const _municipalitiesUrl =
    'https://raw.githubusercontent.com/kelvins/municipios-brasileiros/'
    'main/csv/municipios.csv';
const _statesUrl =
    'https://raw.githubusercontent.com/kelvins/municipios-brasileiros/'
    'main/csv/estados.csv';
const _licenseUrl =
    'https://raw.githubusercontent.com/kelvins/municipios-brasileiros/'
    'main/LICENSE';
const _outputPath = 'assets/maps/brazil_municipios_centroids.csv';
const _licenseOutputPath = 'assets/maps/brazil_municipios_centroids.LICENSE';
const _header =
    'codigo_ibge;nome;codigo_uf;uf;estado;regiao;capital;latitude;'
    'longitude;siafi_id;ddd;fuso_horario';

Future<void> main() async {
  final municipalities = _parseCsv(await _download(_municipalitiesUrl));
  final states = _parseCsv(await _download(_statesUrl));
  final statesByCode = <String, Map<String, String>>{
    for (final state in states) state['codigo_uf']!: state,
  };

  final rows =
      municipalities
          .where((row) => RegExp(r'^\d{7}$').hasMatch(row['codigo_ibge'] ?? ''))
          .toList()
        ..sort(
          (left, right) => int.parse(
            left['codigo_ibge']!,
          ).compareTo(int.parse(right['codigo_ibge']!)),
        );

  final output = StringBuffer(_header)..writeln();
  for (final row in rows) {
    final state = statesByCode[row['codigo_uf']];
    if (state == null) {
      throw StateError('Missing state for codigo_uf=${row['codigo_uf']}.');
    }

    output.writeln(
      <String>[
        row['codigo_ibge']!,
        row['nome']!,
        row['codigo_uf']!,
        state['uf']!,
        state['nome']!,
        state['regiao']!,
        row['capital']!,
        row['latitude']!,
        row['longitude']!,
        row['siafi_id']!,
        row['ddd']!,
        row['fuso_horario']!,
      ].map(_sanitizeField).join(';'),
    );
  }

  await File(_outputPath).writeAsString(output.toString());
  await File(_licenseOutputPath).writeAsString(await _download(_licenseUrl));
  stdout
    ..writeln('Wrote $_outputPath with ${rows.length} municipalities.')
    ..writeln('Wrote $_licenseOutputPath.');
}

Future<String> _download(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'GET $url failed with status ${response.statusCode}.',
        uri: Uri.parse(url),
      );
    }

    return (await utf8.decodeStream(response)).trimLeftByBom();
  } finally {
    client.close(force: true);
  }
}

List<Map<String, String>> _parseCsv(String content) {
  final lines = const LineSplitter()
      .convert(content)
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
  if (lines.isEmpty) {
    return const <Map<String, String>>[];
  }

  final header = _parseCsvLine(lines.first);
  return [
    for (final line in lines.skip(1))
      Map<String, String>.fromIterables(header, _parseCsvLine(line)),
  ];
}

List<String> _parseCsvLine(String line) {
  final values = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var index = 0; index < line.length; index += 1) {
    final char = line[index];
    if (char == '"') {
      final isEscapedQuote =
          inQuotes && index + 1 < line.length && line[index + 1] == '"';
      if (isEscapedQuote) {
        buffer.write('"');
        index += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      values.add(buffer.toString());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  values.add(buffer.toString());
  return values;
}

String _sanitizeField(String value) {
  return value.replaceAll(';', ',').replaceAll('\r', ' ').replaceAll('\n', ' ');
}

extension on String {
  String trimLeftByBom() {
    if (isNotEmpty && codeUnitAt(0) == 0xFEFF) {
      return substring(1);
    }

    return this;
  }
}
