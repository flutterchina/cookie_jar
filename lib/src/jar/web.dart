import 'package:universal_io/io.dart' show Cookie;

import '../cookie_jar.dart';

/// A [WebCookieJar] will do nothing to handle cookies
/// since they are already handled by XHRs.
class WebCookieJar implements CookieJar {
  WebCookieJar({this.ignoreExpires = false});

  @override
  final bool ignoreExpires;

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async => [];

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {}
}
