import 'dart:io';

import 'package:cookie_jar/src/cookie_jar.dart';
import 'package:cookie_jar/src/serializable_cookie.dart';

/// [DefaultCookieJar] is a default cookie manager which implements the standard
/// cookie policy declared in RFC. [DefaultCookieJar] saves the cookies in RAM, so if the application
/// exit, all cookies will be cleared.
class DefaultCookieJar implements CookieJar {
  /// [ignoreExpires]: save/load even cookies that have expired.
  DefaultCookieJar({this.ignoreExpires = false});

  /// A array to save cookies.
  ///
  /// [domains[0]] save the cookies with "domain" attribute.
  /// These cookie usually need to be shared among multiple domains.
  ///
  /// [domains[1]] save the cookies without "domain" attribute.
  /// These cookies are private for each host name.
  ///
  static List<
          Map<
              String, //domain
              Map<
                  String, //path
                  Map<
                      String, //cookie name
                      SerializableCookie //cookie
                      >>>> domains =
      <Map<String, Map<String, Map<String, SerializableCookie>>>>[
    <String, Map<String, Map<String, SerializableCookie>>>{},
    <String, Map<String, Map<String, SerializableCookie>>>{}
  ];

  @override
  List<Cookie> loadForRequest(Uri uri) {
    final List<Cookie> list = <Cookie>[];
    final String urlPath = uri.path.isEmpty ? '/' : uri.path;
    // Load cookies with "domain" attribute, Ignore port.
    domains[0].forEach(
        (String domain, Map<String, Map<String, SerializableCookie>> cookies) {
      if (uri.host.contains(domain)) {
        cookies.forEach((String path, Map<String, SerializableCookie> values) {
          if (urlPath.toLowerCase().contains(path)) {
            values.forEach((String key, SerializableCookie v) {
              if (_check(uri.scheme, v)) {
                list.add(v.cookie);
              }
            });
          }
        });
      }
    });
    // Load cookies without "domain" attribute, include port.
    final String hostname = '${uri.host}${uri.port}';

    for (String domain in domains[1].keys) {
      if (hostname == domain) {
        final Map<String, Map<String, dynamic>> cookies =
            domains[1][domain].cast<String, Map<String, dynamic>>();

        for (String path in cookies.keys) {
          if (urlPath.toLowerCase().contains(path)) {
            final Map<String, dynamic> values = cookies[path];
            for (String key in values.keys) {
              final SerializableCookie cookie = values[key];
              if (_check(uri.scheme, cookie)) {
                list.add(cookie.cookie);
              }
            }
          }
        }
      }
    }
    return list;
  }

  @override
  void saveFromResponse(Uri uri, List<Cookie> cookies) {
    for (Cookie cookie in cookies) {
      String domain = cookie.domain;
      // Save cookies with "domain" attribute, Ignore port.
      if (domain != null) {
        if (domain.startsWith('.')) {
          domain = domain.substring(1);
        }
        final String path = cookie.path ?? '/';

        final Map<String, Map<String, SerializableCookie>> mapDomain =
            domains[0][domain] ?? <String, Map<String, SerializableCookie>>{};
        final Map<String, SerializableCookie> map =
            mapDomain[path] ?? <String, SerializableCookie>{};
        map[cookie.name] = new SerializableCookie(cookie);
        if (_isExpired(map[cookie.name])) {
          map.remove(cookie.name);
        }
        mapDomain[path] = map;
        domains[0][domain] = mapDomain;
      } else {
        // Save cookies without "domain" attribute, include port.
        final String path = cookie.path ?? (uri.path.isEmpty ? '/' : uri.path);
        final String domain = '${uri.host}${uri.port}';

        Map<String, Map<String, dynamic>> mapDomain =
            domains[1][domain] ?? <String, Map<String, dynamic>>{};
        mapDomain = mapDomain.cast<String, Map<String, dynamic>>();

        final Map<String, dynamic> map = mapDomain[path] ?? <String, dynamic>{};
        map[cookie.name] = new SerializableCookie(cookie);
        if (_isExpired(map[cookie.name])) {
          map.remove(cookie.name);
        }
        mapDomain[path] = map.cast<String, SerializableCookie>();
        domains[1][domain] =
            mapDomain.cast<String, Map<String, SerializableCookie>>();
      }
    }
  }

  /// Delete cookies for specified [uri].
  /// This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.
  ///
  /// [withDomainSharedCookie] `true` will delete the domain-shared cookies.
  void delete(Uri uri, [bool withDomainSharedCookie = false]) {
    final String host = '${uri.host}${uri.port}';
    domains[1].remove(host);
    if (withDomainSharedCookie) {
      domains[0].removeWhere(
          (String domain, Map<String, Map<String, SerializableCookie>> v) =>
              uri.host.contains(domain));
    }
  }

//  /// delete cookies for specified domain+port, path will be ignored!
//  void deleteKeys(Uri uri, String key, [bool withDomainSharedCookie = false]) {
//    final String host = '${uri.host}${uri.port}';
//    final String urlPath = uri.path.isEmpty ? '/' : uri.path;
//    var cookies = domains[1][host];
//    cookies?.forEach((path, _cookies) {
//      _cookies?.removeWhere((name, v) {
//        return name == key;
//      });
//    });
//    if (withDomainSharedCookie) {
//      domains[0].forEach((String domain, v){
//        if(uri.host.contains(domain)){
//          v[urlPath]?.removeWhere((name, v) {
//            return name == key;
//          });
//        }
//      });
//    }
//  }
//
//  void deleteKey(Uri uri, String key, [bool withDomainSharedCookie = false]) {
//    final String host = '${uri.host}${uri.port}';
//    var cookies = domains[1][host];
//    if(cookies!=null) {
//      final String urlPath = uri.path.isEmpty ? '/' : uri.path;
//      cookies[urlPath]?.removeWhere((name, v) {
//        return name == key;
//      });
//    }
//    if (withDomainSharedCookie) {
//      final String urlPath = uri.path.isEmpty ? '/' : uri.path;
//      domains[0].forEach((String domain, v){
//          if(uri.host.contains(domain)){
//            v[urlPath]?.removeWhere((name, v) {
//              return name == key;
//            });
//          }
//      });
//    }
//  }
//}

  /// Delete all cookies in RAM
  void deleteAll() {
    domains.clear();
  }

  bool _isExpired(SerializableCookie cookie) {
    return ignoreExpires ? false : cookie.isExpired();
  }

  bool _check(String scheme, SerializableCookie cookie) {
    return cookie.cookie.secure && scheme == 'https' || !_isExpired(cookie);
  }

  @override
  bool ignoreExpires;
}
