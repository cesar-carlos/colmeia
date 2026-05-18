import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';

class AppHereGeocodingCandidate {
  const AppHereGeocodingCandidate({
    required this.point,
    required this.resultType,
    required this.label,
    required this.title,
    required this.city,
    required this.uf,
    required this.district,
    required this.postalCode,
    required this.countryCode,
  });

  final AppGeoPoint point;
  final String? resultType;
  final String? label;
  final String? title;
  final String? city;
  final String? uf;
  final String? district;
  final String? postalCode;
  final String? countryCode;
}

abstract final class AppHereGeocodingCandidateMatcher {
  static AppHereGeocodingCandidate? selectBest({
    required AppLocationLookupInput input,
    required List<AppHereGeocodingCandidate> candidates,
  }) {
    if (candidates.isEmpty) {
      return null;
    }

    final address = input.postalAddress;
    final expectedCountry =
        AppLocationLookupNormalizer.normalizeCountryCodeLoose(
          address?.countryCode,
        );
    final expectedCep = switch (input.type) {
      AppLocationLookupType.cep => AppLocationLookupNormalizer.normalizeCep(
        input.cep,
      ),
      AppLocationLookupType.streetAddress =>
        AppLocationLookupNormalizer.normalizeCep(address?.cep),
      _ => null,
    };
    final expectedUf = switch (input.type) {
      AppLocationLookupType.streetAddress =>
        AppLocationLookupNormalizer.normalizeUf(address?.uf),
      AppLocationLookupType.cityUf ||
      AppLocationLookupType.capitalUf ||
      AppLocationLookupType.uf => AppLocationLookupNormalizer.normalizeUf(
        input.uf,
      ),
      _ => null,
    };
    final expectedCity = switch (input.type) {
      AppLocationLookupType.streetAddress =>
        AppLocationLookupNormalizer.normalizeCity(address?.city),
      AppLocationLookupType.cityUf => AppLocationLookupNormalizer.normalizeCity(
        input.city,
      ),
      _ => null,
    };
    final needsSpecificAddress =
        input.type == AppLocationLookupType.streetAddress &&
        ((address?.street?.trim().isNotEmpty ?? false) ||
            (address?.number?.trim().isNotEmpty ?? false));

    var filtered = candidates
        .where((candidate) {
          if (!candidate.point.isValid) {
            return false;
          }
          if (expectedCountry != null) {
            final candidateCountry =
                AppLocationLookupNormalizer.normalizeCountryCodeLoose(
                  candidate.countryCode,
                );
            if (candidateCountry != expectedCountry) {
              return false;
            }
          }
          if (expectedUf != null) {
            final candidateUf = AppLocationLookupNormalizer.normalizeUf(
              candidate.uf,
            );
            if (candidateUf != expectedUf) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);

    if (filtered.isEmpty) {
      return null;
    }

    if (expectedCep != null) {
      final postalMatches = filtered
          .where((candidate) {
            return AppLocationLookupNormalizer.normalizeCep(
                  candidate.postalCode,
                ) ==
                expectedCep;
          })
          .toList(growable: false);
      if (postalMatches.isEmpty) {
        return null;
      }
      filtered = postalMatches;
    }

    if (expectedCity != null) {
      final cityMatches = filtered
          .where((candidate) {
            return AppLocationLookupNormalizer.normalizeCity(candidate.city) ==
                expectedCity;
          })
          .toList(growable: false);
      if (cityMatches.isNotEmpty) {
        filtered = cityMatches;
      }
    }

    if (!needsSpecificAddress) {
      return filtered.first;
    }

    final ranked = filtered.toList(growable: false)
      ..sort((left, right) {
        return _specificityScore(
          right.resultType,
        ).compareTo(_specificityScore(left.resultType));
      });
    return ranked.first;
  }

  static int _specificityScore(String? resultType) {
    return switch (resultType) {
      'houseNumber' => 3,
      'street' => 2,
      'intersection' => 1,
      _ => 0,
    };
  }
}
