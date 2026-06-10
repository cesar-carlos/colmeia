abstract final class RegistrationFormPolicy {
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;
  static const int personNameMaxLength = 120;
  static const int pollTokenMinLength = 32;
  static final RegExp pollTokenPattern = RegExp(r'^[A-Za-z0-9_-]+$');
}
