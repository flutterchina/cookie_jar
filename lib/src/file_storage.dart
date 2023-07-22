import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:universal_io/io.dart' show Directory, File;

import 'storage.dart';

/// Persist [Cookies] in the host file storage.
class FileStorage implements Storage {
  FileStorage([this.dir]) : shouldCreateDirectory = true;

  @visibleForTesting
  FileStorage.test(this.dir, {this.shouldCreateDirectory = false});

  /// Where the cookie files should be saved.
  ///
  /// When using the [FileStorage] in Flutter apps, use `path_provider`
  /// to obtain available directories.
  final String? dir;

  /// A storage can be used across different jars, so this cannot be final.
  late String _currentDirectory;

  /// {@nodoc}
  @visibleForTesting
  final bool shouldCreateDirectory;

  /// {@nodoc}
  @visibleForTesting
  String get currentDirectory => _currentDirectory;

  String? Function(Uint8List list)? readPreHandler;
  List<int> Function(String value)? writePreHandler;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    // 4 indicates v4 starts to use a new path.
    String baseDir = dir?.replaceAll('\\', '/') ?? '.cookies/4/';
    if (!baseDir.endsWith('/')) {
      baseDir += '/';
    }
    final StringBuffer sb = StringBuffer(baseDir)
      ..write('ie${ignoreExpires ? 1 : 0}')
      ..write('_ps${persistSession ? 1 : 0}')
      ..write('/');
    _currentDirectory = sb.toString();
    await _makeCookieDir();
  }

  @override
  Future<void> delete(String key) async {
    final file = File('$_currentDirectory$key');
    if (file.existsSync()) {
      await file.delete(recursive: true);
    }
  }

  // TODO(EVERYONE): Remove keys since it's useless in the next major version.
  @override
  Future<void> deleteAll(List<String> keys) async {
    final directory = Directory(_currentDirectory);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<String?> read(String key) async {
    final file = File('$_currentDirectory$key');
    if (file.existsSync()) {
      if (readPreHandler != null) {
        return readPreHandler!(await file.readAsBytes());
      } else {
        return file.readAsString();
      }
    }
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    await _makeCookieDir();
    final file = File('$_currentDirectory$key');
    if (writePreHandler != null) {
      await file.writeAsBytes(writePreHandler!(value));
    } else {
      await file.writeAsString(value);
    }
  }

  Future<void> _makeCookieDir() async {
    if (!shouldCreateDirectory) {
      return;
    }
    final directory = Directory(_currentDirectory);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
  }
}
