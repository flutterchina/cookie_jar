@TestOn('chrome')
library cookie_jar_web_test;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  test('Constructed a WebCookieJar', () async {
    final cj = CookieJar();
    expect(cj, isA<WebCookieJar>());
    await cj.deleteAll();
    await cj.saveFromResponse(Uri(), []);
    final cookies = await cj.loadForRequest(Uri());
    expect(cookies, isEmpty);
  });
}
