import 'package:universal_io/io.dart' show Cookie;

import '../cookie_jar.dart';

/// A [WebCookieJar] will do nothing to handle cookies
/// since they are already handled by XHRs.
class WebCookieJar implements CookieJar {
  WebCookieJar();

  @override
  void deleteWhere(bool Function(Cookie cookie) test) {}

  @override
  void deleteAll() {}

  @override
  List<Cookie> loadForRequest(Uri uri) => [];

  @override
  void saveFromResponse(Uri uri, List<Cookie> cookies) {}
}
