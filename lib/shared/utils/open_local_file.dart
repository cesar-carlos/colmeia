import 'dart:io' show Platform, Process;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Opens [path] with the platform default application.
Future<bool> openLocalFile(String path) async {
  if (kIsWeb) {
    return false;
  }
  try {
    if (Platform.isWindows) {
      await Process.run('cmd', <String>[
        '/c',
        'start',
        '',
        path,
      ], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', <String>[path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', <String>[path]);
    } else {
      return false;
    }
    return true;
  } on Object {
    return false;
  }
}
