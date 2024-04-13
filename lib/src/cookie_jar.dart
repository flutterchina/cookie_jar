import 'dart:async';

import 'package:universal_io/io.dart' show Cookie;

import 'jar/default.dart';
import 'jar/web.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// [CookieJar] is a cookie container and manager for HTTP requests.
abstract class CookieJar {
  factory CookieJar({bool ignoreExpires = false}) {
    if (_kIsWeb) {
      return WebCookieJar();
    }
    return DefaultCookieJar(ignoreExpires: ignoreExpires);
  }

  /// Save the [cookies] for specified [uri].
  FutureOr<void> saveFromResponse(Uri uri, List<Cookie> cookies);

  /// Load the cookies for specified [uri].
  FutureOr<List<Cookie>> loadForRequest(Uri uri);

  /// Delete all cookies in the [CookieJar].
  FutureOr<void> deleteAll();

  /// Removes all cookies in this jar that satisfy the given [test].
  FutureOr<void> deleteWhere(bool Function(Cookie cookie) test);
}
