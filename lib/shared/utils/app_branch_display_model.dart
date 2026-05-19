import 'package:flutter/foundation.dart';

@immutable
class AppBranchDisplayModel {
  const AppBranchDisplayModel({
    required this.primaryName,
    required this.searchTokens,
    this.secondaryName,
  });

  final String primaryName;
  final String? secondaryName;
  final String searchTokens;

  bool get hasSecondaryName => secondaryName != null;
}

AppBranchDisplayModel resolveAppBranchDisplayModel({
  String? registrationName,
  String? fantasyName,
  String? fallbackName,
  Iterable<String?> extraSearchTerms = const <String?>[],
}) {
  final normalizedRegistrationName = _trimmedOrNull(registrationName);
  final normalizedFantasyName = _trimmedOrNull(fantasyName);
  final normalizedFallbackName = _trimmedOrNull(fallbackName);
  final primaryName =
      normalizedRegistrationName ??
      normalizedFallbackName ??
      normalizedFantasyName ??
      '';
  final secondaryName =
      normalizedFantasyName != null && normalizedFantasyName != primaryName
      ? normalizedFantasyName
      : null;
  final seen = <String>{};
  final searchTerms = <String>[
    for (final value in <String?>[
      primaryName,
      secondaryName,
      normalizedRegistrationName,
      normalizedFantasyName,
      normalizedFallbackName,
      ...extraSearchTerms,
    ])
      if (_registerSearchTerm(seen, value)) value!.trim(),
  ];

  return AppBranchDisplayModel(
    primaryName: primaryName,
    secondaryName: secondaryName,
    searchTokens: searchTerms.join(' '),
  );
}

bool _registerSearchTerm(Set<String> seen, String? value) {
  final normalized = _trimmedOrNull(value);
  if (normalized == null) {
    return false;
  }
  return seen.add(normalized);
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
