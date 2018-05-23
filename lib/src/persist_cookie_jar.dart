import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/src/default_cookie_jar.dart';
import 'package:cookie_jar/src/serializable_cookie.dart';

/// [PersistCookieJar] is a cookie manager which implements the standard
/// cookie policy declared in RFC. [PersistCookieJar]  persists the cookies in files,
/// so if the application exit, the cookies always exist unless call [delete] explicitly.
class PersistCookieJar extends DefaultCookieJar {
  List<String> _cookieDomains;
  String _dir;
  static final Map<String, PersistCookieJar> _dirMaps = <String, PersistCookieJar>{};

  /// [dir] where the cookie files saved in, it must be a directory.
  factory PersistCookieJar([String dir = './.cookies/']) {
    if (!dir.endsWith('/')) {
      dir += '/';
    }
    final Directory directory = new Directory(dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    _dirMaps[dir] ??= new PersistCookieJar._init(dir);
    return _dirMaps[dir];
  }

  PersistCookieJar._init(this._dir) {
    File file = new File('$_dir.domains');
    if (file.existsSync()) {
      try {
        final Map<String, Map<String, Map<String, dynamic>>> map =
            json.decode(file.readAsStringSync()).cast<String, Map<String, dynamic>>()
              ..forEach((String domain, Map<String, Map<String, dynamic>> cookies) {
                cookies.forEach((String path, Map<String, dynamic> map) {
                  map.forEach((String k, dynamic v) {
                    map[k] = new SerializableCookie.fromJson(v);
                  });
                });
              });

        domains[0] = map;
      } catch (e) {
        file.delete();
        rethrow;
      }
    }
    if (_cookieDomains == null) {
      file = new File('$_dir.index');
      if (file.existsSync()) {
        try {
          final List<dynamic> list = json.decode(file.readAsStringSync());
          _cookieDomains = list.cast<String>();
          return;
        } catch (e) {
          file.delete();
          rethrow;
        }
      }
    }
    _cookieDomains = <String>[];
  }

  @override
  List<Cookie> loadForRequest(Uri uri) {
    _load(uri);
    return super.loadForRequest(uri);
  }

  @override
  void saveFromResponse(Uri uri, List<Cookie> cookies) {
    if (cookies.isNotEmpty) {
      super.saveFromResponse(uri, cookies);
      if (cookies.every((Cookie e) => e.domain == null)) {
        _save(uri);
      } else {
        _save(uri, true);
      }
    }
  }

  Map<String, Map<String, SerializableCookie>> _filter(Map<String, Map<String, SerializableCookie>> domain,
      [bool keepSession = true]) {
    final Map<String, Map<String, SerializableCookie>> newDomain = <String, Map<String, SerializableCookie>>{};
    domain.forEach((String key, Map<String, SerializableCookie> map) {
      final Map<String, SerializableCookie> temp = <String, SerializableCookie>{};
      map.forEach((String key, SerializableCookie v) {
        if (((v.cookie.expires == null && v.cookie.maxAge == null) && keepSession) || !v.isExpired()) {
          temp[key] = v;
        }
      });
      newDomain[key] = temp;
    });
    return newDomain;
  }

  /// Delete cookies for specified [uri].
  /// This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.
  ///
  /// [withDomainSharedCookie] `true` will delete the domain-shared cookies.
  void delete(Uri uri, [bool withDomainSharedCookie = false]) {
    final String host = '${uri.host}${uri.port}';
    File file;
    if (_cookieDomains.remove(host)) {
      file = new File('$_dir.index');
      file.writeAsStringSync(json.encode(_cookieDomains));
    }
    domains[1].remove(host);
    file = new File('$_dir$host');
    if (file.existsSync()) {
      file.delete();
    }
    if (withDomainSharedCookie) {
      final Map<String, Map<String, Map<String, SerializableCookie>>> newSharedCookies =
          <String, Map<String, Map<String, SerializableCookie>>>{};
      domains[0].forEach((String domain, Map<String, Map<String, SerializableCookie>> key) {
        if (!uri.host.contains(domain)) {
          newSharedCookies[domain] = key;
        }
      });
      domains[0] = newSharedCookies;
      file = new File('$_dir.domains');
      file.writeAsStringSync(json.encode(domains[0]));
    }
  }

  void _save(Uri uri, [bool withDomainSharedCookie = false]) {
    final String host = '${uri.host}${uri.port}';
    File file;
    if (!_cookieDomains.contains(host)) {
      _cookieDomains.add(host);
      file = new File('$_dir.index');
      file.writeAsStringSync(json.encode(_cookieDomains));
    }
    if (domains[1][host] != null) {
      file = new File('$_dir$host');
      file.writeAsStringSync(json.encode(_filter(domains[1][host])));
    }
    if (withDomainSharedCookie) {
      file = new File('$_dir.domains');
      final Map<String, Map<String, Map<String, SerializableCookie>>> newDomains =
          <String, Map<String, Map<String, SerializableCookie>>>{};
      domains[0].forEach((String domain, Map<String, Map<String, SerializableCookie>> map) {
        newDomains[domain] = _filter(map);
      });
      file.writeAsStringSync(json.encode(newDomains));
    }
  }

  void _load(Uri uri) {
    final String host = '${uri.host}${uri.port}';
    final File file = new File('$_dir$host');
    if (_cookieDomains.contains(host) && domains[1][host] == null) {
      if (file.existsSync()) {
        Map<String, Map<String, dynamic>> cookies;
        try {
          cookies = json.decode(file.readAsStringSync()).cast<String, Map<String, dynamic>>();
          cookies.forEach((String path, Map<String, dynamic> map) {
            map.forEach((String k, dynamic v) {
              map[k] = new SerializableCookie.fromJson(v);
            });
          });
          domains[1][host] = cookies.cast<String, Map<String, SerializableCookie>>();
        } catch (e) {
          file.delete();
          rethrow;
        }
      }
    }
  }
}
