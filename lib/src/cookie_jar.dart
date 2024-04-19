import 'dart:async';

import 'package:universal_io/io.dart' show Cookie;

import 'jar/default.dart';
import 'jar/web.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// [CookieJar] is a cookie container and manager for HTTP requests implementing [RFC6265](https://www.rfc-editor.org/rfc/rfc6265.html).
///
/// ## Implementation considerations
/// In most cases it is not needed to implement this interface.
/// Use a `PersistCookieJar` with a custom [Storage] backend.
///
/// ### Cookie value retrieval
/// A cookie jar does not need to retrieve cookies with all attributes present.
/// Retrieved cookies only need to have a valid [Cookie.name] and [Cookie.value].
/// It is up to the implementation to provide further information.
///
/// ### Cookie management
/// According to [RFC6265 section 7.2](https://www.rfc-editor.org/rfc/rfc6265.html#section-7.2)
/// user agents SHOULD provide users with a mechanism for managing the cookies stored in the cookie jar.
/// It must be documented if an implementer does not provide any of the optional
/// [loadAll], [deleteAll] and [deleteWhere] methods.
///
/// ### Public suffix validation
/// The default implementation does not validate the cookie domain against a public
/// suffix list:
/// > NOTE: A "public suffix" is a domain that is controlled by a public
/// > registry, such as "com", "co.uk", and "pvt.k12.wy.us". This step is
/// > essential for preventing attacker.com from disrupting the integrity of
/// > example.com by setting a cookie with a Domain attribute of "com".
/// > Unfortunately, the set of public suffixes (also known as "registry controlled domains")
/// > changes over time. If feasible, user agents SHOULD use an up-to-date
/// > public suffix list, such as the one maintained by the Mozilla project at <http://publicsuffix.org/>.
///
/// ### CookieJar limits and eviction policy
/// If a cookie jar has a limit to the number of cookies it can store,
/// the removal policy outlined in [RFC6265 section 5.3](https://www.rfc-editor.org/rfc/rfc6265.html#section-5.3)
/// must be followed:
/// > At any time, the user agent MAY "remove excess cookies" from the cookie store
/// > if the number of cookies sharing a domain field exceeds some implementation-defined
/// > upper bound (such as 50 cookies).
/// >
/// > At any time, the user agent MAY "remove excess cookies" from the cookie store
/// > if the cookie store exceeds some predetermined upper bound (such as 3000 cookies).
/// >
/// > When the user agent removes excess cookies from the cookie store, the user agent MUST
/// > evict cookies in the following priority order:
/// >
/// >    Expired cookies.
/// >    Cookies that share a domain field with more than a predetermined number of other cookies.
/// >    All cookies.
/// >
/// > If two cookies have the same removal priority, the user agent MUST evict the
/// > cookie with the earliest last-access date first.
///
/// It is recommended to set an upper bound to the time a cookie is stored
/// as described in [RFC6265 section 7.3](https://www.rfc-editor.org/rfc/rfc6265.html#section-7.3):
/// > Although servers can set the expiration date for cookies to the distant future,
/// > most user agents do not actually retain cookies for multiple decades.
/// > Rather than choosing gratuitously long expiration periods, servers SHOULD
/// > promote user privacy by selecting reasonable cookie expiration periods based on the purpose of the cookie.
/// > For example, a typical session identifier might reasonably be set to expire in two weeks.
abstract class CookieJar {
  /// Creates a [DefaultCookieJar] instance or a dummy [WebCookieJar] if run in a browser.
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
