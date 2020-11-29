import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() async {
  final cookies = <Cookie>[
    Cookie('name', 'wendux'),
    Cookie('location', 'china'),
  ];
  final cookiesExpired = <Cookie>[
    Cookie('name', 'wendux'),
    Cookie('location', 'china'),
  ];
  cookiesExpired[0].maxAge = 1;
  cookiesExpired[1].expires = DateTime.now().add(const Duration(hours: 1));

  final dir = Directory('./cookies');
  await dir.create();
  group('read and save', () {
    test('DefaultCookieJar', () async {
      final cj = CookieJar();
      cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      var results =
          cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      cj.saveFromResponse(Uri.parse('https://google.com'), cookiesExpired);
      results = cj.loadForRequest(Uri.parse('https://google.com'));
      expect(results.length, 2);
      await Future<void>.delayed(const Duration(seconds: 2), () {
        results = cj.loadForRequest(Uri.parse('https://google.com'));
        expect(results.length, 1);
      });
    });

    test('SharedCookie', () async {
      final cj = CookieJar();
      final cookies = <Cookie>[
        Cookie('name', 'wendux')..domain = '.facebook.com',
        Cookie('location', 'china')..domain = 'qq.com',
      ];
      cj.saveFromResponse(Uri.parse('https://www.facebook.com/tt'), cookies);
      final results =
          cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
    });

    test('SharedCookiePersist', () async {
      final cj = PersistCookieJar(dir: './cookies');
      final cookies = <Cookie>[
        Cookie('name', 'wendux')..domain = '.facebook.com',
        Cookie('location', 'china')..domain = 'qq.com',
      ];
      cj.saveFromResponse(Uri.parse('https://www.facebook.com/tt'), cookies);
      var results =
          cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
      cj.delete(Uri.parse('https://www.facebook.com/'));
      results = cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
      cj.delete(Uri.parse('https://www.facebook.com/'), true);
      results = cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 0);
    });

    test('PersistCookieJar', () async {
      final cj = PersistCookieJar(dir: './test/cookies');
      cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      var results =
          cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
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
      await Future<void>.delayed(const Duration(seconds: 2), () {
        results = cj.loadForRequest(Uri.parse('https://google.com'));
        expect(results.length, 1);
      });
    });

    test('PersistCookieJarLoad', () async {
      final cj = PersistCookieJar(dir: './test/cookies');
      var results =
          cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      results = cj.loadForRequest(Uri.parse('https://google.com'));
    });

    test('PersistCookieIgnoreExpires', () async {
      var cj = PersistCookieJar(
        dir: './test/cookies',
        ignoreExpires: true,
      );
      final uri = Uri.parse('https://xxx.xxx.com/');
      cj.delete(uri);
      List<Cookie> results;
      final cookie = Cookie('test', 'hh')
        ..expires = DateTime.parse('1970-02-27 13:27:00');
      cj.saveFromResponse(uri, <Cookie>[
        cookie,
      ]);
      results = cj.loadForRequest(uri);
      expect(results.length, 1);
      cj = PersistCookieJar(
        dir: './test/cookies',
        ignoreExpires: false,
      );
      results = cj.loadForRequest(uri);
      expect(results.length, 0);
    });
  });
}
