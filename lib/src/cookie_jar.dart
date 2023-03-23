import 'cookie/cookie.dart';

import 'default_cookie_jar.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// CookieJar is a cookie manager for http requests。
abstract class CookieJar {
  factory CookieJar({bool ignoreExpires = false}) {
    if (_kIsWeb) {
      throw UnimplementedError();
    }
    return DefaultCookieJar(ignoreExpires: ignoreExpires);
  }

  /// Save the cookies for specified uri.
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies);

  /// Load the cookies for specified uri.
  Future<List<Cookie>> loadForRequest(Uri uri);

  Future<void> deleteAll();

  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]);

  final bool ignoreExpires = false;
}
