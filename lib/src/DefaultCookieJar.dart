import 'dart:io';
import 'package:cookie_jar/src/CookieJar.dart';
import 'package:cookie_jar/src/SerializableCookie.dart';

/**
 * [DefaultCookieJar] is a default cookie manager which implements the standard
 * cookie policy declared in RFC. [DefaultCookieJar] saves the cookies in RAM, so if the application
 * exit, all cookies will be cleared.
 */
class DefaultCookieJar extends CookieJar {

  /// A array to save cookies.
  ///
  /// [domains[0]] save the cookies with "domain" attribute.
  /// These cookie usually need to be shared among multiple domains.
  ///
  /// [domains[1]] save the cookies without "domain" attribute.
  /// These cookies are private for each host name.
  List<Map<String, //domain
      Map<String, //path
          Map<String, //cookie name
              SerializableCookie //cookie
          >>>> domains = [
    new Map<String, Map<String, Map<String, SerializableCookie>>>(),
    new Map<String, Map<String, Map<String, SerializableCookie>>>()
  ];

  @override
  List<Cookie> loadForRequest(Uri uri) {
    var list = new List<Cookie>();
    String urlPath = uri.path.isEmpty ? "/" : uri.path;
    // Load cookies with "domain" attribute, Ignore port.
    domains[0].forEach((domain,
        Map<String, Map<String, SerializableCookie>> cookies) {
      if (uri.host.contains(domain)) {
        cookies.forEach((path, Map<String, SerializableCookie> values) {
          if (urlPath.contains(path)) {
            values.forEach((key, v) {
              if (_check(uri.scheme, v)) {
                list.add(v.cookie);
              }
            });
          }
        });
      }
    });
    // Load cookies without "domain" attribute, include port.
    String hostname = '${uri.host}${uri.port}';
    domains[1].forEach((domain,
        Map<String, Map<String, SerializableCookie>> cookies) {
      if (hostname == domain) {
        cookies.forEach((path, Map<String, SerializableCookie> values) {
          if (urlPath.contains(path)) {
            values.forEach((key, v) {
              if (_check(uri.scheme, v)) {
                list.add(v.cookie);
              }
            });
          }
        });
      }
    });
    return list;
  }

  @override
  void saveFromResponse(Uri uri, List<Cookie> cookies) {
    cookies.forEach((cookie) {
      String domain = cookie.domain;
      // Save cookies with "domain" attribute, Ignore port.
      if (domain != null) {
        if (domain.startsWith(".")) {
          domain = domain.substring(1);
        }
        String path = cookie.path ?? "/";
        var mapDomain = domains[0][domain] ??
            new Map<String, Map<String, SerializableCookie>>();
        Map<String, SerializableCookie> map = mapDomain[path] ??
            new Map<String, SerializableCookie>();
        map[cookie.name] = new SerializableCookie(cookie);
        mapDomain[path] = map;
        domains[0][domain] = mapDomain;
      } else {
        // Save cookies without "domain" attribute, include port.
        var path = cookie.path ?? (uri.path.isEmpty ? "/" : uri.path);
        var domain = '${uri.host}${uri.port}';
        var mapDomain = domains[1][domain] ??
            new Map<String, Map<String, SerializableCookie>>();
        Map<String, SerializableCookie> map = mapDomain[path] ??
            new Map<String, SerializableCookie>();
        map[cookie.name] = new SerializableCookie(cookie);
        mapDomain[path] = map;
        domains[1][domain] = mapDomain;
      }
    });
  }

  bool _check(String scheme, SerializableCookie cookie) {
    return cookie.cookie.secure && scheme == "https" ||
        !cookie.isExpired();
  }
}
