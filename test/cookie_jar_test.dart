@TestOn('vm')
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
      await cj.saveFromResponse(Uri.parse('https://www.mozilla.org/'), cookies);

      final results1 =
          await cj.loadForRequest(Uri.parse('https://mozilla.org/'));
      expect(results1.length, 1);

      final results2 =
          await cj.loadForRequest(Uri.parse('https://developer.mozilla.org/'));
      expect(results2.length, 1);

      final results3 =
          await cj.loadForRequest(Uri.parse('https://fakemozilla.org/'));
      expect(results3.length, 0);

      final results4 =
          await cj.loadForRequest(Uri.parse('https://mozilla.org.com/'));
      expect(results4.length, 0);
    });

    test('DeleteDomainSharedCookie', () async {
      final cj = CookieJar();
      final cookies = <Cookie>[
        Cookie('JSESSIONID', 'wendux')..domain = '.mozilla.org',
      ];
      await cj.saveFromResponse(Uri.parse('https://www.mozilla.org/'), cookies);

      await cj.delete(Uri.parse('https://www.fakemozilla.org/'), true);
      final results1 =
          await cj.loadForRequest(Uri.parse('https://www.mozilla.org/'));
      expect(results1.length, 1);

      await cj.delete(Uri.parse('https://developer.mozilla.org/'), true);
      final results2 =
          await cj.loadForRequest(Uri.parse('https://www.mozilla.org/'));
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

  test('DefaultCookieJar stores cookies isolated', () async {
    final uri = Uri.parse('https://www.baidu.com/xx');

    final cj = DefaultCookieJar();
    await cj.saveFromResponse(uri, cookies);
    final results = await cj.loadForRequest(uri);
    expect(results, isNotEmpty);

    final otherCj = DefaultCookieJar();
    final otherResults = await otherCj.loadForRequest(uri);
    expect(otherResults, isEmpty);
  });

  group('Test session cookies persistance', () {
    test('PersistCookieJar persists session cookies by default', () async {
      final uri = Uri.parse('https://session-default-test.com/');

      // Create session cookies (no expires or maxAge)
      final sessionCookies = <Cookie>[
        Cookie('session_cookie', 'session_value'),
        Cookie('another_session', 'another_value'),
      ];

      // Create non-session cookies (with expires)
      final persistentCookies = <Cookie>[
        Cookie('persistent_cookie', 'persistent_value')
          ..expires = DateTime.now().add(const Duration(days: 1)),
      ];

      // Mix of session and persistent cookies
      final mixedCookies = <Cookie>[
        ...sessionCookies,
        ...persistentCookies,
      ];

      // Test with default persistSession (should be true)
      PersistCookieJar cj = PersistCookieJar(
        storage: FileStorage('./test/cookies/session_default_test'),
      );

      await cj.delete(uri);
      await cj.saveFromResponse(uri, mixedCookies);

      // Create a new instance to verify persistence
      cj = PersistCookieJar(
        storage: FileStorage('./test/cookies/session_default_test'),
      );

      final results = await cj.loadForRequest(uri);

      // All cookies (session and persistent) should be loaded
      expect(results.length, 3);

      // Verify all cookies are present
      expect(results.any((c) => c.name == 'session_cookie'), true);
      expect(results.any((c) => c.name == 'another_session'), true);
      expect(results.any((c) => c.name == 'persistent_cookie'), true);

      // Verify values
      final sessionCookie = results.firstWhere((c) => c.name == 'session_cookie');
      expect(sessionCookie.value, 'session_value');

      final anotherSession = results.firstWhere((c) => c.name == 'another_session');
      expect(anotherSession.value, 'another_value');

      final persistentCookie = results.firstWhere((c) => c.name == 'persistent_cookie');
      expect(persistentCookie.value, 'persistent_value');
    });

    test('PersistCookieJar does not persist session cookies when `persistSession` is false', () async {
      final uri = Uri.parse('https://session-test.com/');

      // Create session cookies (no expires or maxAge)
      final sessionCookies = <Cookie>[
        Cookie('session_cookie', 'session_value'),
        Cookie('another_session', 'another_value'),
      ];

      // Create non-session cookies (with expires)
      final persistentCookies = <Cookie>[
        Cookie('persistent_cookie', 'persistent_value')
          ..expires = DateTime.now().add(const Duration(days: 1)),
      ];

      // Mix of session and persistent cookies
      final mixedCookies = <Cookie>[
        ...sessionCookies,
        ...persistentCookies,
      ];

      // Test with persistSession = false
      PersistCookieJar cj = PersistCookieJar(
        persistSession: false,
        storage: FileStorage('./test/cookies/session_test'),
      );

      await cj.delete(uri);
      await cj.saveFromResponse(uri, mixedCookies);

      // Create a new instance to verify persistence
      cj = PersistCookieJar(
        persistSession: false,
        storage: FileStorage('./test/cookies/session_test'),
      );

      final results = await cj.loadForRequest(uri);

      // Only persistent cookies should be loaded
      expect(results.length, 1);
      expect(results[0].name, 'persistent_cookie');
      expect(results[0].value, 'persistent_value');

      // Verify session cookies are not present
      expect(results.any((c) => c.name == 'session_cookie'), false);
      expect(results.any((c) => c.name == 'another_session'), false);
    });
  });

  group('FileStorage', () {
    test('Parsed directory correctly', () async {
      final s1 = FileStorage.test('./test/cookies');
      final s2 = FileStorage.test('./test/cookies/');
      final s3 = FileStorage.test('/test/cookies');
      final s4 = FileStorage.test('/test/cookies/');
      final s5 = FileStorage.test('C:\\.cookies');
      await Future.wait([
        s1.init(true, false),
        s2.init(true, false),
        s3.init(true, false),
        s4.init(true, false),
        s5.init(true, false),
      ]);
      expect(s1.currentDirectory, './test/cookies/ie0_ps1/');
      expect(s2.currentDirectory, './test/cookies/ie0_ps1/');
      expect(s3.currentDirectory, '/test/cookies/ie0_ps1/');
      expect(s4.currentDirectory, '/test/cookies/ie0_ps1/');
      expect(s5.currentDirectory, 'C:/.cookies/ie0_ps1/');
    });
  });
}
