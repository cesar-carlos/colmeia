import 'dart:io';

/// Writes [lib/l10n/app_pt.arb] from [lib/l10n/app_pt_BR.arb] with @@locale "pt".
///
/// Run after editing Portuguese strings in app_pt_BR.arb:
/// `dart run tool/sync_pt_locale_arb.dart`
void main() {
  final root = Directory.current;
  final source = File('${root.path}/lib/l10n/app_pt_BR.arb');
  final target = File('${root.path}/lib/l10n/app_pt.arb');
  if (!source.existsSync()) {
    stderr.writeln('Missing ${source.path}');
    exitCode = 1;
    return;
  }
  var content = source.readAsStringSync();
  content = content.replaceFirst(
    RegExp(r'"@@locale"\s*:\s*"pt_BR"'),
    '"@@locale": "pt"',
  );
  target.writeAsStringSync(content);
  stdout.writeln('Updated ${target.path} from app_pt_BR.arb.');
}
