class ClientPatchMeRequestDto {
  const ClientPatchMeRequestDto({
    this.firstName,
    this.lastName,
    this.mobile,
    this.removeThumbnail = false,
  });

  final String? firstName;
  final String? lastName;
  final String? mobile;
  final bool removeThumbnail;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (firstName case final String value when value.trim().isNotEmpty)
        'name': value.trim(),
      if (lastName case final String value when value.trim().isNotEmpty)
        'lastName': value.trim(),
      if (mobile case final String value)
        'mobile': value.trim().isEmpty ? null : value.trim(),
      if (removeThumbnail) 'thumbnailUrl': null,
    };
  }
}
