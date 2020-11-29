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
  final dir = Directory('./example/.cookies');
  await dir.create(recursive: true);
  final cj = CookieJar();
  //var cj=new PersistCookieJar('./example/.cookies');
  cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
  var results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
  assert(results.length == 2);
  results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
  assert(results.length == 2);
  results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
  assert(results.isEmpty);
  cj.saveFromResponse(Uri.parse('https://google.com'), cookiesExpired);
  results = cj.loadForRequest(Uri.parse('https://google.com'));
  assert(results.length == 2);
  await Future<void>.delayed(const Duration(seconds: 2), () {
    results = cj.loadForRequest(Uri.parse('https://google.com'));
    assert(results.length == 1);
  });
}
