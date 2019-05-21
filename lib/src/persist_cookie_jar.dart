import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/src/default_cookie_jar.dart';
import 'package:cookie_jar/src/serializable_cookie.dart';

/// [PersistCookieJar] is a cookie manager which implements the standard
/// cookie policy declared in RFC. [PersistCookieJar]  persists the cookies in files,
/// so if the application exit, the cookies always exist unless call [delete] explicitly.
class PersistCookieJar extends DefaultCookieJar {
  /// [dir]: where the cookie files saved in, it must be a directory.
  ///
  /// [persistSession]: Whether persisting the cookies that without
  /// "expires" or "max-age" attribute;
  /// If false, the session cookies will be discarded;
  /// otherwise, the session cookies will be persisted.
  ///
  /// [ignoreExpires]: save/load even cookies that have expired.
  PersistCookieJar({
    String dir = './.cookies/',
    this.persistSession = true,
    bool ignoreExpires = false,
  }) : super(ignoreExpires: ignoreExpires) {
    if (!dir.endsWith('/')) {
      _dir = dir + '/';
    }else{
      _dir=dir;
    }
    _dir += "ie${ignoreExpires ? 1 : 0}_ps${persistSession ? 1 : 0}/";
    _checkInited();
  }

  /// Whether persisting the cookies that without "expires" or "max-age" attribute;
  final bool persistSession;

  /// domain-shared cookie
  static final _dirCookieDomains = <String, List<String>>{};
  String _dir;

  List<String> get _cookieDomains => _dirCookieDomains[_dir];
  static final _dirInit = <String,
      List<Map<String, Map<String, Map<String, SerializableCookie>>>>>{};

  @override
  List<Map<String, Map<String, Map<String, SerializableCookie>>>> get domains =>
      _dirInit[_dir];

  void forceInit() {
    _dirInit[_dir] = null;
    _checkInited();
  }

  void _checkInited(){
    if (_dirInit[_dir] == null) {
      _dirInit[_dir] = [
        <String, Map<String, Map<String, SerializableCookie>>>{},
        <String, Map<String, Map<String, SerializableCookie>>>{}
      ];
      _makeCookieDir();
      // Load domain cookies
      File file = new File('$_dir.domains');
      if (file.existsSync()) {
        try {
          final Map<String, dynamic> jsonData =
          json.decode(file.readAsStringSync());

          final Map<String, Map<String, Map<String, SerializableCookie>>>
          cookies = jsonData.map((String domain, dynamic _cookies) {
            final Map<String, dynamic> cookies =
            _cookies.cast<String, dynamic>();
            final Map<String, Map<String, SerializableCookie>> domainCookies =
            cookies.map((String path, dynamic map) {
              final Map<String, String> cookieForPath =
              map.cast<String, String>();
              final Map<String, SerializableCookie> realCookies =
              cookieForPath.map((String cookieName, String cookie) =>
              new MapEntry<String, SerializableCookie>(
                  cookieName, new SerializableCookie.fromJson(cookie)));
              return new MapEntry<String, Map<String, SerializableCookie>>(
                  path, realCookies);
            });
            return new MapEntry<String,
                Map<String, Map<String, SerializableCookie>>>(
                domain, domainCookies);
          });
          _dirInit[_dir][0] = cookies;
        } catch (e) {
          file.delete();
        }
      }

      file = new File('$_dir.index');
      if (file.existsSync()) {
        try {
          final List<dynamic> list = json.decode(file.readAsStringSync());
          _dirCookieDomains[_dir] = list.cast<String>();
          return;
        } catch (e) {
          file.delete();
        }
      }
      _dirCookieDomains[_dir] = <String>[];
    }
  }
  void _makeCookieDir() {
    final Directory directory = new Directory(_dir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
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

  Map<String, Map<String, SerializableCookie>> _filter(
    Map<String, Map<String, SerializableCookie>> domain,
  ) {
    return domain
        .cast<String, Map<String, dynamic>>()
        .map((String path, Map<String, dynamic> _cookies) {
      final Map<String, SerializableCookie> cookies =
          _cookies.map((String cookieName, dynamic cookie) {
        if (((cookie.cookie.expires == null && cookie.cookie.maxAge == null) &&
                persistSession) ||
            (persistSession && !cookie.isExpired())) {
          return new MapEntry<String, SerializableCookie>(cookieName, cookie);
        } else
          return new MapEntry<String, SerializableCookie>(null, cookie);
      })
            ..removeWhere((String k, SerializableCookie v) => k == null);

      return new MapEntry<String, Map<String, SerializableCookie>>(
          path, cookies);
    });
  }

  /// Delete cookies for specified [uri].
  /// This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.
  ///
  /// [withDomainSharedCookie] `true` will delete the domain-shared cookies.
  @override
  void delete(Uri uri, [bool withDomainSharedCookie = false]) {
    super.delete(uri,withDomainSharedCookie);
    final String host = uri.host;
    File file;
    if (_cookieDomains.remove(host)) {
      file = new File('$_dir.index');
      file.writeAsStringSync(json.encode(_cookieDomains));
    }
    file = new File('$_dir$host');
    if (file.existsSync()) {
      file.delete();
    }
    if (withDomainSharedCookie) {
      file = new File('$_dir.domains');
      file.writeAsStringSync(json.encode(domains[0]));
    }
  }

  /// Delete all cookies files under [dir] directory and clear them out from RAM
  @override
  void deleteAll() {
    super.deleteAll();
    _cookieDomains?.clear();
    final Directory directory = Directory(_dir);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  void _save(Uri uri, [bool withDomainSharedCookie = false]) {
    _makeCookieDir();
    final String host = uri.host;
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
      final Map<String, Map<String, Map<String, SerializableCookie>>>
          newDomains = <String, Map<String, Map<String, SerializableCookie>>>{};
      domains[0].forEach(
          (String domain, Map<String, Map<String, SerializableCookie>> map) {
        newDomains[domain] = _filter(map);
      });
      file.writeAsStringSync(json.encode(newDomains));
    }
  }

  void _load(Uri uri) {
    final String host = uri.host;
    if (_cookieDomains.contains(host) && domains[1][host] == null) {
      final File file = new File('$_dir$host');
      if (file.existsSync()) {
        Map<String, Map<String, dynamic>> cookies;
        try {
          cookies = json
              .decode(file.readAsStringSync())
              .cast<String, Map<String, dynamic>>();
          cookies.forEach((String path, Map<String, dynamic> map) {
            map.forEach((String k, dynamic v) {
              map[k] = new SerializableCookie.fromJson(v);
            });
          });
          domains[1][host] =
              cookies.cast<String, Map<String, SerializableCookie>>();
        } catch (e) {
          file.delete();
        }
      }
    }
  }
}
