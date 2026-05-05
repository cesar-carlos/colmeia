// Generates windows/runner/resources/app_icon.ico with multiple embedded PNG
// layers (standard Windows / Explorer / Inno Setup compatibility).
//
// flutter_launcher_icons produces a single-resolution ICO; this script
// overwrites that output before `flutter build windows`.

import 'dart:io';

import 'package:image/image.dart';

const List<int> _icoSizes = <int>[256, 128, 64, 48, 32, 16];

Future<void> main(List<String> args) async {
  final root = Directory.current.path;
  final srcPath = '$root/assets/icons/colmeia-512.png';
  final outPath = '$root/windows/runner/resources/app_icon.ico';

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
  final outFile = File(outPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(bytes, flush: true);

  stdout.writeln(
    'generate_windows_app_icon: wrote $outPath '
    '(${bytes.length} bytes, ${_icoSizes.length} sizes)',
  );
}
