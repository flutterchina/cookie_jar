import 'cookie/cookie.dart';

/// This class is a wrapper for `Cookie` class.
/// Because the `Cookie` class doesn't  support Json serialization,
/// for the sake of persistence, we use this class instead of it.
class SerializableCookie {
  SerializableCookie(this.cookie) {
    createTimeStamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toInt();
  }

  final Cookie cookie;
  int createTimeStamp = 0;

  /// Create an instance from JSON string.
  factory SerializableCookie.fromJson(String value) {
    final t = value.split(';_crt=');
    return SerializableCookie(Cookie.fromSetCookieValue(t[0]))
      ..createTimeStamp = int.parse(t[1]);
  }

  /// Tells whether this cookie is expired.
  bool isExpired() {
    final now = DateTime.now();
    return (cookie.maxAge != null && cookie.maxAge! < 1) ||
        (cookie.maxAge != null &&
            (now.millisecondsSinceEpoch ~/ 1000).toInt() - createTimeStamp >=
                cookie.maxAge!) ||
        (cookie.expires != null && !cookie.expires!.isAfter(now));
  }

  /// Serialize the JSON string.
  String toJson() => toString();

  @override
  String toString() => '$cookie;_crt=$createTimeStamp';
}
