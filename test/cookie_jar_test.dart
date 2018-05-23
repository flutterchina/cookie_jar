import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cookie_jar/src/persist_cookie_jar.dart';
import 'package:test/test.dart';

void main() async {
  final List<Cookie> cookies = <Cookie>[
    new Cookie('name', 'wendux'),
    new Cookie('location', 'china'),
  ];
  final List<Cookie> cookiesExpired = <Cookie>[
    new Cookie('name', 'wendux'),
    new Cookie('location', 'china'),
  ];
  cookiesExpired[0].maxAge = 1;
  cookiesExpired[1].expires = new DateTime.now().add(const Duration(hours: 1));

  final Directory dir = new Directory('./cookies');
  await dir.create();
  group('read and save', () {
    test('DefaultCookieJar', () async {
      final CookieJar cj = new CookieJar();
      cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      List<Cookie> results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      cj.saveFromResponse(Uri.parse('https://google.com'), cookiesExpired);
      results = cj.loadForRequest(Uri.parse('https://google.com'));
      expect(results.length, 2);
      await new Future<void>.delayed(const Duration(seconds: 2), () {
        results = cj.loadForRequest(Uri.parse('https://google.com'));
        expect(results.length, 1);
      });
    });

    test('SharedCookie', () async {
      final CookieJar cj = new CookieJar();
      final List<Cookie> cookies = <Cookie>[
        new Cookie('name', 'wendux')..domain = '.facebook.com',
        new Cookie('location', 'china')..domain = 'qq.com',
      ];
      cj.saveFromResponse(Uri.parse('https://www.facebook.com/tt'), cookies);
      final List<Cookie> results = cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
    });

    test('SharedCookiePersist', () async {
      final PersistCookieJar cj = new PersistCookieJar('./cookies');
      final List<Cookie> cookies = <Cookie>[
        new Cookie('name', 'wendux')..domain = '.facebook.com',
        new Cookie('location', 'china')..domain = 'qq.com',
      ];
      cj.saveFromResponse(Uri.parse('https://www.facebook.com/tt'), cookies);
      List<Cookie> results = cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
      cj.delete(Uri.parse('https://www.facebook.com/'));
      results = cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
      cj.delete(Uri.parse('https://www.facebook.com/'), true);
      results = cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 0);
    });

    test('PersistCookieJar', () async {
      final PersistCookieJar cj = new PersistCookieJar('./cookies');
      cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      List<Cookie> results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      cj.delete(Uri.parse('https://www.baidu.com/'));
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 0);
      cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      cj.saveFromResponse(Uri.parse('https://google.com'), cookiesExpired);
      results = cj.loadForRequest(Uri.parse('https://google.com'));
      expect(results.length, 2);
      await new Future<void>.delayed(const Duration(seconds: 2), () {
        results = cj.loadForRequest(Uri.parse('https://google.com'));
        expect(results.length, 1);
      });
    });

    test('PersistCookieJarLoad', () async {
      final PersistCookieJar cj = new PersistCookieJar('./test/cookies');
      List<Cookie> results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      results = cj.loadForRequest(Uri.parse('https://google.com'));
    });
  });
}
