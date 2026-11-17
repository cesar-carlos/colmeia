import 'package:colmeia/shared/widgets/navigation/app_shell_user_initials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves existing initials and whitespace handling', () {
    expect(appShellUserInitials('   '), '?');
    expect(appShellUserInitials('a'), 'A');
    expect(appShellUserInitials('cesar'), 'CE');
    expect(appShellUserInitials('  Casa  do\tMel  '), 'CM');
  });

  test('keeps combining accents in single and multiple word names', () {
    expect(appShellUserInitials('A\u0301lvaro'), 'A\u0301L');
    expect(appShellUserInitials('A\u0301lvaro E\u0301vora'), 'A\u0301E\u0301');
  });

  test('does not split supplementary or joined characters', () {
    expect(appShellUserInitials('A😀'), 'A😀');
    expect(appShellUserInitials('👩‍💻 Silva'), '👩‍💻S');
  });
}
