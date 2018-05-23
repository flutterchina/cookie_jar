import 'dart:io';

import 'package:cookie_jar/src/default_cookie_jar.dart';

/// CookieJar is a cookie manager for http requests。
abstract class CookieJar {
  factory CookieJar() = DefaultCookieJar;

  // Save the cookies for specified uri.
  void saveFromResponse(Uri uri, List<Cookie> cookies);

  // Load the cookies for specified uri.
  List<Cookie> loadForRequest(Uri uri);
}
