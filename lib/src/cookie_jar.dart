import 'dart:io';

import 'default_cookie_jar.dart';

/// [CookieJar] is a cookie container and manager for HTTP requests.
abstract class CookieJar {
  factory CookieJar({bool ignoreExpires = false}) {
    return DefaultCookieJar(ignoreExpires: ignoreExpires);
  }

  /// Whether the [CookieJar] should ignore expired cookies during saves/loads.
  final bool ignoreExpires = false;

  /// Save the [cookies] for specified [uri].
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies);

  /// Load the cookies for specified [uri].
  Future<List<Cookie>> loadForRequest(Uri uri);

  /// Delete all cookies in the [CookieJar].
  Future<void> deleteAll();

  /// Delete cookies with the specified [uri].
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]);
}
