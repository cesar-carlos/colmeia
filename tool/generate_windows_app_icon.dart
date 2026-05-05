// Generates Windows ICO files with multiple embedded PNG layers (16–256 px).
//
// Outputs:
// - `windows/runner/resources/app_icon.ico` — linked via Runner.rc into colmeia.exe.
// - `installer/setup_icon.ico` — used only by Inno Setup (`SetupIconFile`).
//
// `installer/setup_icon.ico` lives outside `windows/` so `flutter build windows`
// cannot overwrite it before ISCC runs (the Flutter tool may replace the runner ICO).
//
// flutter_launcher_icons single-resolution ICO is insufficient for Explorer/Inno;
// this script runs before (and after) release builds — see `installer/build_installer.py`.

import 'dart:io';

import 'package:image/image.dart';

const List<int> _icoSizes = <int>[256, 128, 64, 48, 32, 16];

Future<void> main() async {
  final root = Directory.current.path;
  final srcPath = '$root/assets/icons/colmeia-512.png';
  final outputPaths = <String>[
    '$root/windows/runner/resources/app_icon.ico',
    '$root/installer/setup_icon.ico',
  ];

  final srcFile = File(srcPath);
  if (!srcFile.existsSync()) {
    stderr.writeln('generate_windows_app_icon: missing $srcPath');
    exit(64);
  }

  final decoded = decodeImage(await srcFile.readAsBytes());
  if (decoded == null) {
    stderr.writeln('generate_windows_app_icon: could not decode PNG');
    exit(65);
  }

  final frames = <Image>[];
  for (final size in _icoSizes) {
    frames.add(
      copyResize(
        decoded,
        width: size,
        height: size,
        interpolation: Interpolation.average,
      ),
    );
  }

  final icon = Image.from(frames.first, noAnimation: true);
  for (var i = 1; i < frames.length; i++) {
    icon.addFrame(frames[i]);
  }

  final bytes = encodeIco(icon);

  for (final outPath in outputPaths) {
    final outFile = File(outPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(bytes, flush: true);
    stdout.writeln(
      'generate_windows_app_icon: wrote $outPath '
      '(${bytes.length} bytes, ${_icoSizes.length} sizes)',
    );
  }
}
