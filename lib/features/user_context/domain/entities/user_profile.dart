class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.roleLabel,
    this.corporateEmail = '',
    this.phone = '',
    this.firstName = '',
    this.lastName = '',
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final String roleLabel;
  final String corporateEmail;
  final String phone;
  final String firstName;
  final String lastName;
  final String? thumbnailUrl;

  bool get hasCorporateEmail => corporateEmail.trim().isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasThumbnail => thumbnailUrl?.trim().isNotEmpty ?? false;
}
