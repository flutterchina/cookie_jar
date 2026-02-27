import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';

void main() async {
  final storage = FileStorage('./example/.cookies/encryption')
    ..readPreHandler = (Uint8List list) {
      // decrypt
      return utf8.decode(list.map<int>((e) => e ^ 2).toList());
    }
    ..writePreHandler = (String value) {
      // encrypt
      return utf8.encode(value).map<int>((e) => e ^ 2).toList();
    };

  final cj = PersistCookieJar(ignoreExpires: true, storage: storage);

  final uri = Uri.parse('https://xxx.xxx.com/');
  await cj.deleteWhere((cookie) => cookie.domain == uri.host);
  List<Cookie> results;
  final cookie = Cookie('test', 'hh')
    ..expires = DateTime.parse('1970-02-27 13:27:00');
  await cj.saveFromResponse(uri, <Cookie>[
    cookie,
  ]);

  results = await cj.loadForRequest(uri);
  assert(results.length == 1);
  assert(results[0].value == 'hh');
}
