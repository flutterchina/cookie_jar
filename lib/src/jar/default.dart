import 'dart:async';

import 'package:universal_io/io.dart' show Cookie;

import '../cookie_jar.dart';
import '../serializable_cookie.dart';

/// [DefaultCookieJar] is a default cookie manager which implements the standard
/// cookie policy declared in RFC.
///
/// [DefaultCookieJar] saves the cookies in the memory, all cookies will be
/// cleared after the app exited.
///
/// In order to save cookies into storages, use [PersistCookieJar] instead.
class DefaultCookieJar implements CookieJar {
  DefaultCookieJar({this.ignoreExpires = false});

  final bool ignoreExpires;

  /// An array to save cookies.
  ///
  /// [domains[0]] save the cookies with "domain" attribute.
  /// These cookie usually need to be shared among multiple domains.
  ///
  /// [domains[1]] save the cookies without "domain" attribute.
  /// These cookies are private for each host name.
  final List<
          Map<
              String, //domain or host
              Map<
                  String, //path
                  Map<
                      String, //cookie name
                      SerializableCookie //cookie
                      >>>> _cookies =
      <Map<String, Map<String, Map<String, SerializableCookie>>>>[
    <String, Map<String, Map<String, SerializableCookie>>>{},
    <String, Map<String, Map<String, SerializableCookie>>>{},
  ];

  Map<String, Map<String, Map<String, SerializableCookie>>> get domainCookies =>
      _cookies[0];

  Map<String, Map<String, Map<String, SerializableCookie>>> get hostCookies =>
      _cookies[1];

  /// If you set Path=/docs, these request paths match:
  ///     /docs
  ///     /docs/
  ///     /docs/Web/
  ///     /docs/Web/HTTP
  /// But these request paths don't:
  ///     /
  ///     /docsets
  ///     /fr/docs
  bool _isPathMatch(String urlPath, String cookiePath) {
    final urlPathLowerCase = urlPath.toLowerCase();
    final cookiePathLowerCase = cookiePath.toLowerCase();
    if ('/' == cookiePath || urlPathLowerCase == cookiePathLowerCase) {
      return true;
    }
    if (urlPathLowerCase.startsWith(cookiePathLowerCase)) {
      final temp = urlPathLowerCase.substring(
        cookiePathLowerCase.endsWith('/')
            ? cookiePathLowerCase.length - 1
            : cookiePathLowerCase.length,
      );
      return temp.startsWith('/');
    }
    return false;
  }

  /// If you set Domain=.mozilla.org, these request domains match:
  ///     mozilla.org
  ///     developer.mozilla.org
  /// But these request domains don't:
  ///     fakemozilla.org
  ///     mozilla.org.com
  bool _isDomainMatch(String urlDomain, String cookieDomain) {
    if (urlDomain == cookieDomain) {
      return true;
    }
    if (urlDomain.endsWith(cookieDomain)) {
      final temp =
          urlDomain.substring(0, urlDomain.length - cookieDomain.length);
      return temp.endsWith('.');
    }
    return false;
  }

  @override
  FutureOr<List<Cookie>> loadForRequest(Uri uri) {
    final list = <Cookie>[];
    final urlPath = uri.path;
    // Load cookies without "domain" attribute, include port.
    final hostname = uri.host;
    for (final domain in hostCookies.keys) {
      if (hostname == domain) {
        final cookies =
            hostCookies[domain]!.cast<String, Map<String, dynamic>>();
        // Sort by best match （longer path first）
        final keys = cookies.keys.toList()
          ..sort((a, b) => b.length.compareTo(a.length));
        for (final path in keys) {
          if (_isPathMatch(urlPath, path)) {
            final values = cookies[path]!;
            for (final key in values.keys) {
              final SerializableCookie cookie = values[key];
              if (_check(uri.scheme, cookie)) {
                // preserve cookies that with same name but in different paths when request (as Chrome);
                // eg(in request header): Cookie: a=1;  a=2;  a=3
                list.add(cookie.cookie);
              }
            }
          }
        }
      }
    }
    // Load cookies with "domain" attribute, Ignore port.
    domainCookies.forEach(
      (domain, cookies) {
        if (_isDomainMatch(uri.host, domain)) {
          cookies.forEach(
            (path, values) {
              if (_isPathMatch(urlPath, path)) {
                values.forEach((key, v) {
                  if (_check(uri.scheme, v)) {
                    list.add(v.cookie);
                  }
                });
              }
            },
          );
        }
      },
    );
    return list;
  }

  @override
  FutureOr<void> saveFromResponse(Uri uri, List<Cookie> cookies) {
    for (final cookie in cookies) {
      String? domain = cookie.domain;
      String path;
      final int index;
      if (domain != null) {
        index = 0;
        // Save cookies with "domain" attribute.
        if (domain.startsWith('.')) {
          domain = domain.substring(1);
        }
        path = cookie.path ?? '/';
      } else {
        // Save cookies without "domain" attribute.
        index = 1;
        domain = uri.host;
        path = cookie.path ?? _curDir(uri.path);
      }
      final mapDomain =
          _cookies[index][domain]?.cast<String, Map<String, dynamic>>() ??
              <String, Map<String, dynamic>>{};
      final map = mapDomain[path] ?? <String, dynamic>{};
      map[cookie.name] = SerializableCookie(cookie);
      if (_isExpired(map[cookie.name])) {
        map.remove(cookie.name);
      }
      mapDomain[path] = map.cast<String, SerializableCookie>();
      _cookies[index][domain] =
          mapDomain.cast<String, Map<String, SerializableCookie>>();
    }
  }

  /// Delete cookies for specified [uri].
  /// This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.
  ///
  /// [withDomainSharedCookie] `true` will delete the domain-shared cookies.
  @Deprecated('Use deleteWhere instead')
  FutureOr<void> delete(Uri uri, [bool withDomainSharedCookie = false]) {
    final host = uri.host;
    hostCookies.remove(host);
    if (withDomainSharedCookie) {
      domainCookies.removeWhere(
        (domain, v) => _isDomainMatch(uri.host, domain),
      );
    }
  }

  /// Delete all cookies stored in the memory.
  @override
  FutureOr<void> deleteAll() {
    domainCookies.clear();
    hostCookies.clear();
  }

  bool _isExpired(SerializableCookie cookie) {
    return ignoreExpires ? false : cookie.isExpired();
  }

  bool _check(String scheme, SerializableCookie cookie) {
    return cookie.cookie.secure && scheme == 'https' || !_isExpired(cookie);
  }

  String _curDir(String path) {
    if (path.isEmpty) {
      return '/';
    }
    final list = path.split('/')..removeLast();
    return list.join('/');
  }

  @override
  void deleteWhere(bool Function(Cookie cookie) test) {
    // Traverse all managed cookies and delete entries matching `test`.
    for (final group in _cookies) {
      for (final domainPair in group.values) {
        for (final pathPair in domainPair.values) {
          pathPair.removeWhere((key, value) => test(value.cookie));
        }
      }
    }
  }

  @override
  void endSession() {
    deleteWhere((cookie) {
      return cookie.expires == null && cookie.maxAge == null;
    });
  }

  @override
  FutureOr<List<Cookie>> loadAll() {
    final list = <Cookie>[];

    for (final group in _cookies) {
      for (final domainPair in group.values) {
        for (final pathPair in domainPair.values) {
          for (final value in pathPair.values) {
            list.add(value.cookie);
          }
        }
      }
    }

    return list;
  }
}
