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
      String domain = 'https://aa.com';
      await cj.saveFromResponse(Uri.parse('$domain/a'), cookies);
      List<Cookie> results = await cj.loadForRequest(Uri.parse('$domain/a'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/a/b'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse(domain));
      expect(results.length, 2);

      domain = 'https://bb.com';
      await cj.saveFromResponse(Uri.parse('$domain/a/b'), cookies);
      results = await cj.loadForRequest(Uri.parse('$domain/a'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/a/'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/a/b'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/a/b/c'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/c'));
      expect(results.length, 0);

      //same key exists in different path
      domain = 'https://cc.com';
      await cj.saveFromResponse(Uri.parse(domain), [Cookie('a', '1')]);
      await cj.saveFromResponse(Uri.parse('$domain/a/b'), [Cookie('a', '2')]);
      results = await cj.loadForRequest(Uri.parse(domain));
      expect(results.length, 1);
      expect(results.first.value, '1');
      results = await cj.loadForRequest(Uri.parse('$domain/a/b'));
      expect(results.length, 2);
      expect(results.first.value, '2');
      expect(results.last.value, '1');
      results = await cj.loadForRequest(Uri.parse('$domain/a/b/c'));
      expect(results.length, 2);
      expect(results.first.value, '2');
      expect(results.last.value, '1');

      domain = 'https://dd.com';
      await cj.saveFromResponse(Uri.parse(domain), cookiesExpired);
      results = await cj.loadForRequest(Uri.parse(domain));
      expect(results.length, 2);
      await Future<void>.delayed(const Duration(seconds: 2), () async {
        results = await cj.loadForRequest(Uri.parse(domain));
        expect(results.length, 1);
      });
    });
    test('PersistCookieJar', () async {
      final domain = 'https://aa.com';
      // write
      final pcj = PersistCookieJar(storage: FileStorage('./test/cookies'));
      await pcj.saveFromResponse(Uri.parse('$domain/a'), cookies);

      // read
      final cj = PersistCookieJar(storage: FileStorage('./test/cookies'));
      List<Cookie> results = await cj.loadForRequest(Uri.parse('$domain/a'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/a/b'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse('$domain/'));
      expect(results.length, 2);
      results = await cj.loadForRequest(Uri.parse(domain));
      expect(results.length, 2);
    });
    test('SharedCookie', () async {
      final cj = CookieJar();
      final cookies = <Cookie>[
        Cookie('name', 'wendux')..domain = '.facebook.com',
        Cookie('location', 'china')..domain = 'qq.com',
      ];
      await cj.saveFromResponse(
        Uri.parse('https://www.facebook.com/tt'),
        cookies,
      );
      final results =
          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
    });

    // test('SharedPathCookie', () async {
    //   final cj = CookieJar();
    //   final cookies = <Cookie>[
    //     Cookie('JSESSIONID', 'wendux')..path = '/docs',
    //   ];
    //   await cj.saveFromResponse(Uri.parse('http://www.mozilla.org/'), cookies);
    //
    //   final results1 =
    //       await cj.loadForRequest(Uri.parse('http://www.mozilla.org/docs'));
    //   expect(results1.length, 1);
    //
    //   final results2 =
    //       await cj.loadForRequest(Uri.parse('http://www.mozilla.org/docs/'));
    //   expect(results2.length, 1);
    //
    //   final results3 =
    //       await cj.loadForRequest(Uri.parse('http://www.mozilla.org/docs/Web'));
    //   expect(results3.length, 1);
    //
    //   final results4 = await cj
    //       .loadForRequest(Uri.parse('http://www.mozilla.org/docs/Web/HTTP'));
    //   expect(results4.length, 1);
    //
    //   final results5 =
    //       await cj.loadForRequest(Uri.parse('http://www.mozilla.org/docsets'));
    //   expect(results5.length, 0);
    //
    //   final results6 =
    //       await cj.loadForRequest(Uri.parse('http://www.mozilla.org/fr/docs'));
    //   expect(results6.length, 0);
    // });

    test('SharedDomainCookie', () async {
      final cj = CookieJar();
      final cookies = <Cookie>[
        Cookie('JSESSIONID', 'wendux')..domain = '.mozilla.org',
      ];
      await cj.saveFromResponse(Uri.parse('http://www.mozilla.org/'), cookies);

      final results1 =
          await cj.loadForRequest(Uri.parse('http://mozilla.org/'));
      expect(results1.length, 1);

      final results2 =
          await cj.loadForRequest(Uri.parse('http://developer.mozilla.org/'));
      expect(results2.length, 1);

      final results3 =
          await cj.loadForRequest(Uri.parse('http://fakemozilla.org/'));
      expect(results3.length, 0);

      final results4 =
          await cj.loadForRequest(Uri.parse('http://mozilla.org.com/'));
      expect(results4.length, 0);
    });

    test('DeleteDomainSharedCookie', () async {
      final cj = CookieJar();
      final cookies = <Cookie>[
        Cookie('JSESSIONID', 'wendux')..domain = '.mozilla.org',
      ];
      await cj.saveFromResponse(Uri.parse('http://www.mozilla.org/'), cookies);

      await cj.delete(Uri.parse('http://www.fakemozilla.org/'), true);
      final results1 =
          await cj.loadForRequest(Uri.parse('http://www.mozilla.org/'));
      expect(results1.length, 1);

      await cj.delete(Uri.parse('http://developer.mozilla.org/'), true);
      final results2 =
          await cj.loadForRequest(Uri.parse('http://www.mozilla.org/'));
      expect(results2.length, 0);
    });

    test('SharedCookiePersist', () async {
      final cj = PersistCookieJar(storage: FileStorage('./test/cookies'));
      final cookies = <Cookie>[
        Cookie('name', 'wendux')..domain = '.facebook.com',
        Cookie('location', 'china')..domain = 'qq.com',
      ];
      await cj.saveFromResponse(
        Uri.parse('https://www.facebook.com/tt'),
        cookies,
      );
      List<Cookie> results =
          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
      await cj.delete(Uri.parse('https://www.facebook.com/'));
      results =
          await cj.loadForRequest(Uri.parse('https://tt.facebook.com/xxx'));
      expect(results.length, 1);
    });

    test('PersistCookieIgnoreExpires', () async {
      PersistCookieJar cj = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage('./test/cookies'),
      );
      final uri = Uri.parse('https://xxx.com/');
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
        ignoreExpires: false,
        storage: FileStorage('./test/cookies'),
      );
      results = await cj.loadForRequest(uri);
      expect(results.length, 0);
    });

    test('encryption', () async {
      final storage = FileStorage('./test/cookies/encryption')
        ..readPreHandler = (Uint8List list) {
          return utf8.decode(list.map<int>((e) => e ^ 2).toList());
        }
        ..writePreHandler = (String value) {
          return utf8.encode(value).map<int>((e) => e ^ 2).toList();
        };

      PersistCookieJar cj = PersistCookieJar(
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
