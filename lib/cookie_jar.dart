/// A cookie manager for http requests, by which you
/// can deal with the complex cookie policy and persist cookies easily.
///
/// A open source project authorized by [https://flutterchina.club](https://flutterchina.club).
library cookie_jar;

export 'package:universal_io/io.dart' show Cookie;

export 'src/cookie_jar.dart';
export 'src/jar/default.dart';
export 'src/jar/persist.dart';
export 'src/jar/web.dart';
export 'src/serializable_cookie.dart';
export 'src/storage.dart';
export 'src/file_storage.dart';
