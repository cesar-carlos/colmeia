import 'package:flutter/foundation.dart';

enum SalesLiveMapLocationResolution {
  providedGeoPoint,
  ibgeMunicipalityCode,
  cep,
  cityUf,
  capitalUf,
  stateUf,
}

@immutable
class SalesLiveMapPoint {
  const SalesLiveMapPoint({
    required this.id,
    required this.name,
    required this.uf,
    required this.latitude,
    required this.longitude,
    required this.salesAmount,
    required this.salesCount,
    this.municipalityCode,
    this.city,
    this.fantasyName,
    this.branchName,
    this.companyCode,
    this.branchCode,
    this.agentName,
    this.salesDataLoading = false,
    this.salesDataUnavailable = false,
    this.salesDataStatusLabel,
    this.locationResolution,
    this.subtitle,
    this.payload,
  });

  final String id;
  final String name;
  final String uf;
  final double latitude;
  final double longitude;
  final double salesAmount;
  final int salesCount;
  final String? municipalityCode;
  final String? city;
  final String? fantasyName;
  final String? branchName;
  final int? companyCode;
  final int? branchCode;
  final String? agentName;
  final bool salesDataLoading;
  final bool salesDataUnavailable;
  final String? salesDataStatusLabel;
  final SalesLiveMapLocationResolution? locationResolution;
  final String? subtitle;
  final Object? payload;

  SalesLiveMapPoint copyWith({
    String? id,
    String? name,
    String? uf,
    double? latitude,
    double? longitude,
    double? salesAmount,
    int? salesCount,
    Object? municipalityCode = _sentinel,
    Object? city = _sentinel,
    Object? fantasyName = _sentinel,
    Object? branchName = _sentinel,
    Object? companyCode = _sentinel,
    Object? branchCode = _sentinel,
    Object? agentName = _sentinel,
    bool? salesDataLoading,
    bool? salesDataUnavailable,
    Object? salesDataStatusLabel = _sentinel,
    Object? locationResolution = _sentinel,
    Object? subtitle = _sentinel,
    Object? payload = _sentinel,
  }) {
    return SalesLiveMapPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      uf: uf ?? this.uf,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      salesAmount: salesAmount ?? this.salesAmount,
      salesCount: salesCount ?? this.salesCount,
      municipalityCode: identical(municipalityCode, _sentinel)
          ? this.municipalityCode
          : municipalityCode as String?,
      city: identical(city, _sentinel) ? this.city : city as String?,
      fantasyName: identical(fantasyName, _sentinel)
          ? this.fantasyName
          : fantasyName as String?,
      branchName: identical(branchName, _sentinel)
          ? this.branchName
          : branchName as String?,
      companyCode: identical(companyCode, _sentinel)
          ? this.companyCode
          : companyCode as int?,
      branchCode: identical(branchCode, _sentinel)
          ? this.branchCode
          : branchCode as int?,
      agentName: identical(agentName, _sentinel)
          ? this.agentName
          : agentName as String?,
      salesDataLoading: salesDataLoading ?? this.salesDataLoading,
      salesDataUnavailable: salesDataUnavailable ?? this.salesDataUnavailable,
      salesDataStatusLabel: identical(salesDataStatusLabel, _sentinel)
          ? this.salesDataStatusLabel
          : salesDataStatusLabel as String?,
      locationResolution: identical(locationResolution, _sentinel)
          ? this.locationResolution
          : locationResolution as SalesLiveMapLocationResolution?,
      subtitle: identical(subtitle, _sentinel)
          ? this.subtitle
          : subtitle as String?,
      payload: identical(payload, _sentinel) ? this.payload : payload,
    );
  }
}

@immutable
class SalesLiveMapPointSource {
  const SalesLiveMapPointSource({
    required this.id,
    required this.name,
    required this.salesAmount,
    required this.salesCount,
    this.uf,
    this.city,
    this.latitude,
    this.longitude,
    this.cep,
    this.ibgeMunicipalityCode,
    this.preferCapitalFallback = false,
    this.allowUfFallback = true,
    this.fantasyName,
    this.branchName,
    this.companyCode,
    this.branchCode,
    this.agentName,
    this.salesDataLoading = false,
    this.salesDataUnavailable = false,
    this.salesDataStatusLabel,
    this.subtitle,
    this.payload,
  });

  final String id;
  final String name;
  final double salesAmount;
  final int salesCount;
  final String? uf;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? cep;
  final String? ibgeMunicipalityCode;
  final bool preferCapitalFallback;
  final bool allowUfFallback;
  final String? fantasyName;
  final String? branchName;
  final int? companyCode;
  final int? branchCode;
  final String? agentName;
  final bool salesDataLoading;
  final bool salesDataUnavailable;
  final String? salesDataStatusLabel;
  final String? subtitle;
  final Object? payload;
}

@immutable
class SalesLiveMapResolvedPoint {
  const SalesLiveMapResolvedPoint({
    required this.point,
  });

  final SalesLiveMapPoint point;
}

const Object _sentinel = Object();
