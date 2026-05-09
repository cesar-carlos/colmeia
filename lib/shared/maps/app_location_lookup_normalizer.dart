import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';

abstract final class AppLocationLookupNormalizer {
  static String? cacheKeyFor(AppLocationLookupInput input) {
    return switch (input.type) {
      AppLocationLookupType.geoPoint => null,
      AppLocationLookupType.ibgeMunicipalityCode => cacheKeyForIbgeMunicipality(
        input.ibgeMunicipalityCode,
      ),
      AppLocationLookupType.cep => cacheKeyForCep(input.cep),
      AppLocationLookupType.cityUf => cacheKeyForCityUf(
        city: input.city,
        uf: input.uf,
      ),
      AppLocationLookupType.capitalUf => cacheKeyForCapitalUf(input.uf),
      AppLocationLookupType.uf => cacheKeyForUf(input.uf),
    };
  }

  static String? cacheKeyForCep(String? cep) {
    final normalizedCep = normalizeCep(cep);
    if (normalizedCep == null) {
      return null;
    }

    return '${AppKvCacheKeyPrefixes.locationGeocode}cep_$normalizedCep';
  }

  static String? cacheKeyForIbgeMunicipality(String? code) {
    final normalizedCode = normalizeIbgeMunicipalityCode(code);
    if (normalizedCode == null) {
      return null;
    }

    return '${AppKvCacheKeyPrefixes.locationGeocode}ibge_$normalizedCode';
  }

  static String? cacheKeyForCityUf({
    required String? city,
    required String? uf,
  }) {
    final normalizedCity = normalizeCity(city);
    final normalizedUf = normalizeUf(uf);
    if (normalizedCity == null || normalizedUf == null) {
      return null;
    }

    return '${AppKvCacheKeyPrefixes.locationGeocode}'
        'city_uf_${normalizedCity}_$normalizedUf';
  }

  static String? cacheKeyForCapitalUf(String? uf) {
    final normalizedUf = normalizeUf(uf);
    if (normalizedUf == null) {
      return null;
    }

    return '${AppKvCacheKeyPrefixes.locationGeocode}'
        'capital_uf_$normalizedUf';
  }

  static String? cacheKeyForUf(String? uf) {
    final normalizedUf = normalizeUf(uf);
    if (normalizedUf == null) {
      return null;
    }

    return '${AppKvCacheKeyPrefixes.locationGeocode}uf_$normalizedUf';
  }

  static String? normalizeCep(String? cep) {
    final value = cep?.replaceAll(RegExp('[^0-9]'), '');
    if (value == null || value.length != 8) {
      return null;
    }

    return value;
  }

  static String? normalizeIbgeMunicipalityCode(String? code) {
    final value = code?.replaceAll(RegExp('[^0-9]'), '');
    if (value == null || value.length != 7) {
      return null;
    }

    return value;
  }

  static String? normalizeUf(String? uf) {
    final value = uf?.trim().toUpperCase();
    if (value == null || value.length != 2) {
      return null;
    }

    return value;
  }

  static String? normalizeCity(String? city) {
    final value = city?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return _stripDiacritics(value)
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _stripDiacritics(String value) {
    const replacements = <String, String>{
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'à': 'A',
      'á': 'A',
      'â': 'A',
      'ã': 'A',
      'ä': 'A',
      'å': 'A',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'è': 'E',
      'é': 'E',
      'ê': 'E',
      'ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'ì': 'I',
      'í': 'I',
      'î': 'I',
      'ï': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'ò': 'O',
      'ó': 'O',
      'ô': 'O',
      'õ': 'O',
      'ö': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'ù': 'U',
      'ú': 'U',
      'û': 'U',
      'ü': 'U',
      'Ç': 'C',
      'ç': 'C',
      'Ñ': 'N',
      'ñ': 'N',
    };

    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      buffer.write(replacements[char] ?? char);
    }

    return buffer.toString();
  }
}
