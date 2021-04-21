import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      await cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      var results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      await cj.saveFromResponse(
          Uri.parse('https://google.com'), cookiesExpired);
      results = await cj.loadForRequest(Uri.parse('https://google.com'));
      expect(results.length, 2);
      await Future<void>.delayed(const Duration(seconds: 2), () async {
        results = await cj.loadForRequest(Uri.parse('https://google.com'));
        expect(results.length, 1);
      });
    });

    test('SharedCookie', () async {
      final cj = CookieJar();
      final cookies = <Cookie>[
        Cookie('name', 'wendux')..domain = '.facebook.com',
        Cookie('location', 'china')..domain = 'qq.com',
      ];
      await cj.saveFromResponse(
          Uri.parse('https://www.facebook.com/tt'), cookies);
      final results =
          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
    });

    test('SharedCookiePersist', () async {
      final cj = PersistCookieJar(storage: FileStorage('./test/cookies'));
      final cookies = <Cookie>[
        Cookie('name', 'wendux')..domain = '.facebook.com',
        Cookie('location', 'china')..domain = 'qq.com',
      ];
      await cj.saveFromResponse(
          Uri.parse('https://www.facebook.com/tt'), cookies);
      var results =
          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
      await cj.delete(Uri.parse('https://www.facebook.com/'));
      results =
          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
//      await cj.delete(Uri.parse('https://www.facebook.com/'), true);
//      results =
//          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
//      expect(results.length, 0);
    });

    test('PersistCookieJar', () async {
      final cj = PersistCookieJar(storage: FileStorage('./test/cookies'));
      await cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      var results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      await cj.delete(Uri.parse('https://www.baidu.com/'));
      results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 0);
      await cj.saveFromResponse(Uri.parse('https://www.baidu.com/xx'), cookies);
      await cj.saveFromResponse(
          Uri.parse('https://google.com'), cookiesExpired);
      results = await cj.loadForRequest(Uri.parse('https://google.com'));
      expect(results.length, 2);
      await Future<void>.delayed(const Duration(seconds: 2), () async {
        results = await cj.loadForRequest(Uri.parse('https://google.com'));
        expect(results.length, 1);
      });
    });

    test('PersistCookieJarLoad', () async {
      final cj = PersistCookieJar(storage: FileStorage('./test/cookies'));
      var results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx'));
      expect(results.length, 2);
      results =
          await cj.loadForRequest(Uri.parse('https://www.baidu.com/xx/dd'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('https://www.baidu.com/'));
      expect(results.length, 0);
      results = await cj.loadForRequest(Uri.parse('https://google.com'));
    });

    test('PersistCookieIgnoreExpires', () async {
      var cj = PersistCookieJar(
          ignoreExpires: true, storage: FileStorage('./test/cookies'));
      final uri = Uri.parse('https://xxx.xxx.com/');
      await cj.delete(uri);
      List<Cookie> results;
      final cookie = Cookie('test', 'hh')
        ..expires = DateTime.parse('1970-02-27 13:27:00');
      await cj.saveFromResponse(uri, <Cookie>[
        cookie,
      ]);
      results = await cj.loadForRequest(uri);
      expect(results.length, 1);
      cj = PersistCookieJar(
          ignoreExpires: false, storage: FileStorage('./test/cookies'));
      results = await cj.loadForRequest(uri);
      expect(results.length, 0);
    });

    test('encryption', () async {
      var storage = FileStorage('./test/cookies/encryption')
        ..readPreHandler = (Uint8List list) {
          return utf8.decode(list.map<int>((e) => e ^ 2).toList());
        }
        ..writePreHandler = (String value) {
          return utf8.encode(value).map<int>((e) => e ^ 2).toList();
        };

      var cj = PersistCookieJar(
        ignoreExpires: true,
        storage: storage,
      );

      final uri = Uri.parse('https://xxx.xxx.com/');
      await cj.delete(uri);
      List<Cookie> results;
      final cookie = Cookie('test', 'hh')
        ..expires = DateTime.parse('1970-02-27 13:27:00');
      await cj.saveFromResponse(uri, <Cookie>[
        cookie,
      ]);

      results = await cj.loadForRequest(uri);
      expect(results.length, 1);
      expect(results[0].value, 'hh');

      cj = PersistCookieJar(
        ignoreExpires: false,
        storage: storage,
      );

      results = await cj.loadForRequest(uri);
      expect(results.length, 0);
    });
  });
}
