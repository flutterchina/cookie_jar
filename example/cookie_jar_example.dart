import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';

void main() async {
  final List<Cookie> cookies = <Cookie>[
    new Cookie('name', 'wendux'),
    new Cookie('location', 'china'),
  ];
  final List<Cookie> cookiesExpired = <Cookie>[
    new Cookie('name', 'wendux')..maxAge = 1,
    new Cookie('location', 'china')
      ..expires = new DateTime.now().add(const Duration(hours: 1)),
  ];
  final Directory dir = new Directory('./example/.cookies');
  await dir.create(recursive: true);
  final CookieJar cj = new CookieJar();
  //var cj=new PersistCookieJar('./example/.cookies');
  cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
  List<Cookie> results =
      cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
  assert(results.length == 2);
  results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
  assert(results.length == 2);
  results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
  assert(results.isEmpty);
  cj.saveFromResponse(Uri.parse('https://google.com'), cookiesExpired);
  results = cj.loadForRequest(Uri.parse('https://google.com'));
  assert(results.length == 2);
  await new Future<void>.delayed(const Duration(seconds: 2), () {
    results = cj.loadForRequest(Uri.parse('https://google.com'));
    assert(results.length == 1);
  });
}
