import 'dart:convert';

import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:crypto/crypto.dart';

abstract final class AppLocationLookupNormalizer {
  static const String streetAddressNormalizationVersion = 'v1';

  static String? cacheKeyFor(AppLocationLookupInput input) {
    return switch (input.type) {
      AppLocationLookupType.geoPoint => null,
      AppLocationLookupType.streetAddress => cacheKeyForStreetAddress(
        input.postalAddress,
      ),
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

  static String? cacheKeyForStreetAddress(AppPostalAddress? address) {
    final fingerprint = fingerprintForStreetAddress(address);
    if (fingerprint == null) {
      return null;
    }

    return '${AppKvCacheKeyPrefixes.locationGeocode}'
        'street_address_${streetAddressNormalizationVersion}_$fingerprint';
  }

  static String? fingerprintForStreetAddress(AppPostalAddress? address) {
    if (address == null) {
      return null;
    }

    final normalizedStreet = normalizeAddressLine(address.street);
    final normalizedNumber = normalizeAddressToken(address.number);
    final normalizedDistrict = normalizeAddressLine(address.district);
    final normalizedCity = normalizeCity(address.city);
    final normalizedUf = normalizeUf(address.uf);
    final normalizedCep = normalizeCep(address.cep);
    final normalizedCountry = normalizeCountryCode(address.countryCode);
    final hasLookupData =
        normalizedUf != null ||
        normalizedCity != null ||
        normalizedStreet != null ||
        normalizedNumber != null ||
        normalizedDistrict != null ||
        normalizedCep != null;
    if (!hasLookupData) {
      return null;
    }
    final payload = <String>[
      streetAddressNormalizationVersion,
      normalizedCountry ?? '',
      normalizedUf ?? '',
      normalizedCity ?? '',
      normalizedStreet ?? '',
      normalizedNumber ?? '',
      normalizedDistrict ?? '',
      normalizedCep ?? '',
    ];

    final digest = sha256.convert(utf8.encode(payload.join('|')));
    return digest.toString().substring(0, 24);
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
    final value = code?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final digitsOnly = value.replaceAll(RegExp('[^0-9]'), '');
    if (digitsOnly.length == 7) {
      return digitsOnly;
    }

    final numeric = double.tryParse(value.replaceAll(',', '.'));
    if (numeric == null ||
        !numeric.isFinite ||
        numeric.truncateToDouble() != numeric) {
      return null;
    }

    final normalized = numeric.toInt().toString();
    return normalized.length == 7 ? normalized : null;
  }

  static String? normalizeUf(String? uf) {
    final value = uf?.trim().toUpperCase();
    if (value == null || value.length != 2) {
      return null;
    }

    return value;
  }

  static String? normalizeCountryCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.length != 2) {
      return null;
    }

    return normalized;
  }

  static String? normalizeCountryCodeLoose(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.length == 2) {
      return normalized;
    }
    return switch (normalized) {
      'BRA' => 'BR',
      _ => null,
    };
  }

  static String? normalizeCity(String? city) {
    return _normalizeToUnderscoreToken(city);
  }

  static String? normalizeAddressLine(String? value) {
    return _normalizeToUnderscoreToken(value);
  }

  static String? normalizeAddressToken(String? value) {
    return _normalizeToUnderscoreToken(value);
  }

  static String? _normalizeToUnderscoreToken(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final normalized = _stripDiacritics(trimmed)
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? null : normalized;
  }

  static String _stripDiacritics(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      buffer.write(
        _asciiBaseLetterFor(codeUnit) ?? String.fromCharCode(codeUnit),
      );
    }

    return buffer.toString();
  }

  static String? _asciiBaseLetterFor(int codeUnit) {
    return switch (codeUnit) {
      0x00C0 || 0x00C1 || 0x00C2 || 0x00C3 || 0x00C4 || 0x00C5 => 'A',
      0x00E0 || 0x00E1 || 0x00E2 || 0x00E3 || 0x00E4 || 0x00E5 => 'A',
      0x00C8 || 0x00C9 || 0x00CA || 0x00CB => 'E',
      0x00E8 || 0x00E9 || 0x00EA || 0x00EB => 'E',
      0x00CC || 0x00CD || 0x00CE || 0x00CF => 'I',
      0x00EC || 0x00ED || 0x00EE || 0x00EF => 'I',
      0x00D2 || 0x00D3 || 0x00D4 || 0x00D5 || 0x00D6 => 'O',
      0x00F2 || 0x00F3 || 0x00F4 || 0x00F5 || 0x00F6 => 'O',
      0x00D9 || 0x00DA || 0x00DB || 0x00DC => 'U',
      0x00F9 || 0x00FA || 0x00FB || 0x00FC => 'U',
      0x00C7 || 0x00E7 => 'C',
      0x00D1 || 0x00F1 => 'N',
      _ => null,
    };
  }
}
