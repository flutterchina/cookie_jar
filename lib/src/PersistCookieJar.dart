import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/src/DefaultCookieJar.dart';
import 'package:cookie_jar/src/SerializableCookie.dart';

/**
 * [PersistCookieJar] is a cookie manager which implements the standard
 * cookie policy declared in RFC. [PersistCookieJar]  persists the cookies in files,
 * so if the application exit, the cookies always exist unless call [delete] explicitly.
 */
class PersistCookieJar extends DefaultCookieJar {
  List<String> _cookieDomains;
  String _dir;

  /// [dir] where the cookie files saved in, it must be a directory.
  PersistCookieJar([String dir = './']) {
    if (!dir.endsWith("/")) {
      dir += "/";
    }
    _dir = dir;
    var file = new File('$_dir.domains');
    if (file.existsSync()) {
      try {
        domains[0] = JSON.decode(file.readAsStringSync());
        domains[0].forEach((domain, Map<String, Map<String, dynamic>> cookies) {
          cookies.forEach((path, Map<String, dynamic> map) {
            map.forEach((k, v) {
              map[k] = new SerializableCookie.fromJson(v);
            });
          });
        });
      } catch (e) {
        file.delete();
      }
    }
    if (_cookieDomains == null) {
      file = new File('$_dir.index');
      if (file.existsSync()) {
        try {
          _cookieDomains = JSON.decode(file.readAsStringSync());
          return;
        } catch (e) {
          file.delete();
        }
      }
    }
    _cookieDomains = new List<String>();
  }


  @override
  List<Cookie> loadForRequest(Uri uri) {
    _load(uri);
    return super.loadForRequest(uri);
  }

  @override
  void saveFromResponse(Uri uri, List<Cookie> cookies) {
    if (cookies.length > 0) {
      super.saveFromResponse(uri, cookies);
      if (cookies.every((e) => e.domain == null)) {
        _save(uri);
      } else {
        _save(uri, true);
      }
    }
  }

  Map<String, Map<String, SerializableCookie>> _filter(
      Map<String, Map<String, SerializableCookie>> domain,
      [keepSession = true]) {
    var newDomain = new Map<String, Map<String, SerializableCookie>>();
    domain.forEach((key, map) {
      var temp = new Map<String, SerializableCookie>();
      map.forEach((key, v) {
        if (((v.cookie.expires == null && v.cookie.maxAge == null) &&
            keepSession) ||
            !v.isExpired()) {
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
  delete(Uri uri,[bool withDomainSharedCookie = false] ){
    var host = '${uri.host}${uri.port}';
    File  file;
    if(_cookieDomains.remove(host)){
      file = new File('$_dir.index');
      file.writeAsStringSync(JSON.encode(_cookieDomains));
    }
    domains[1].remove(host);
    file = new File('$_dir$host');
    if(file.existsSync()){
      file.delete();
    }
    if(withDomainSharedCookie){
     var newSharedCookies= new Map<String, Map<String, Map<String, SerializableCookie>>>();
      domains[0].forEach((domain,key){
         if(!uri.host.contains(domain)){
           newSharedCookies[domain]=key;
         }
      });
     domains[0]=newSharedCookies;
     file = new File('$_dir.domains');
     file.writeAsStringSync(JSON.encode(domains[0]));
    }
  }

  _save(Uri uri, [bool withDomainSharedCookie = false]) {
    var host = '${uri.host}${uri.port}';
    File file;
    if (!_cookieDomains.contains(host)) {
      _cookieDomains.add(host);
      file = new File('$_dir.index');
      file.writeAsStringSync(JSON.encode(_cookieDomains));
    }
    if(domains[1][host]!=null) {
      file = new File('$_dir$host');
      file.writeAsStringSync(JSON.encode(_filter(domains[1][host])));
    }
    if (withDomainSharedCookie) {
      file = new File('$_dir.domains');
      var newDomains = new Map<String,
          Map<String, Map<String, SerializableCookie>>>();
      domains[0].forEach((domain, map) {
        newDomains[domain] = _filter(map);
      });
      file.writeAsStringSync(JSON.encode(newDomains));
    }
  }

  _load(Uri uri) {
    var host = '${uri.host}${uri.port}';
    var file = new File('$_dir$host');
    if (_cookieDomains.contains(host) && domains[1][host] == null) {
      if (file.existsSync()) {
        Map<String, Map<String, dynamic>> cookies;
        try {
          cookies = JSON.decode(file.readAsStringSync());
          cookies.forEach((path, Map<String, dynamic> map) {
            map.forEach((k, v) {
              map[k] = new SerializableCookie.fromJson(v);
            });
          });
          domains[1][host] = cookies;
        } catch (e) {
          file.delete();
        }
      }
    }
  }
}
