import 'dart:io';

/**
 * CookieJar is a cookie manager for http requests。
 */
abstract class CookieJar {
  // Save the cookies for specified uri.
  void saveFromResponse(Uri uri, List<Cookie> cookies);
  // Load the cookies for specified uri.
  List<Cookie> loadForRequest(Uri uri);
}