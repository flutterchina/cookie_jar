@TestOn('chrome')
import 'package:cookie_jar/cookie_jar.dart';
import 'package:test/test.dart';

void main() {
  test('Throws unimplemented errors', () async {
    expect(() => CookieJar(), throwsA(isA<UnimplementedError>()));
  });
}
