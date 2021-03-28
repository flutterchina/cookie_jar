import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';

void main() async {
  final cookies = <Cookie>[
    Cookie('name', 'wendux'),
    Cookie('location', 'china'),
  ];
  final cookiesExpired = <Cookie>[
    Cookie('name', 'wendux')..maxAge = 1,
    Cookie('location', 'china')
      ..expires = DateTime.now().add(const Duration(hours: 1)),
  ];

  //final cj = CookieJar();
  //final cj = PersistCookieJar();
  final cj = PersistCookieJar(storage: FileStorage('./example/.cookies'));

  await cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
  var results = await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
  assert(results.length == 2);
  results = await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
  assert(results.length == 2);
  results = await cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
  assert(results.isEmpty);
  await cj.saveFromResponse(Uri.parse('https://google.com'), cookiesExpired);
  results = await cj.loadForRequest(Uri.parse('https://google.com'));
  assert(results.length == 2);
  await Future<void>.delayed(const Duration(seconds: 2), () async {
    results = await cj.loadForRequest(Uri.parse('https://google.com'));
    assert(results.length == 1);
  });
}
