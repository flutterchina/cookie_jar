import 'dart:async';

import 'package:universal_io/io.dart' show Cookie;

import 'jar/default.dart';
import 'jar/web.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// [CookieJar] is a cookie container and manager for HTTP requests.
abstract class CookieJar {
  factory CookieJar({bool ignoreExpires = false}) {
    if (_kIsWeb) {
      return WebCookieJar();
    }
    return DefaultCookieJar(ignoreExpires: ignoreExpires);
  }

  /// Save the [cookies] for specified [uri].
  FutureOr<void> saveFromResponse(Uri uri, List<Cookie> cookies);

  /// Load the cookies for specified [uri].
  FutureOr<List<Cookie>> loadForRequest(Uri uri);

  /// Ends the current session deleting all session cookies.
  FutureOr<void> endSession();

  /// Loads all cookies in the jar.
  ///
  /// User agents SHOULD provide users with a mechanism for managing the cookies stored in the cookie jar.
  /// https://www.rfc-editor.org/rfc/rfc6265.html#section-7.2
  ///
  /// Implementing this method is optional. It must be documented if the
  /// implementer does not support this operation.
  FutureOr<List<Cookie>> loadAll();

  /// Deletes all cookies in the jar.
  ///
  /// User agents SHOULD provide users with a mechanism for managing the cookies stored in the cookie jar.
  /// https://www.rfc-editor.org/rfc/rfc6265.html#section-7.2
  ///
  /// Implementing this method is optional. It must be documented if the
  /// implementer does not support this operation.
  FutureOr<void> deleteAll();

  /// Removes all cookies in this store that satisfy the given [test].
  ///
  /// User agents SHOULD provide users with a mechanism for managing the cookies stored in the cookie store.
  /// https://www.rfc-editor.org/rfc/rfc6265.html#section-7.2
  ///
  /// Implementing this method is optional. It must be documented if the
  /// implementer does not support this operation.
  FutureOr<void> deleteWhere(bool Function(Cookie cookie) test);
}
