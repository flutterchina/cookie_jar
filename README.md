# CookieJar

[![build statud](https://img.shields.io/travis/flutterchina/cookie_jar/master.svg?style=flat-square)](https://travis-ci.org/flutterchina/cookie_jar)
[![Pub](https://img.shields.io/pub/v/box2d.svg?style=flat-square)](https://pub.dartlang.org/packages/cookie_jar)
[![coverage](https://img.shields.io/codecov/c/github/flutterchina/cookie_jar/master.svg?style=flat-square)](https://codecov.io/github/flutterchina/cookie_jar?branch=master)
[![support](https://img.shields.io/badge/platform-flutter%7Cdart%20vm-ff69b4.svg?style=flat-square)](https://github.com/flutterchina/cookie_jar)

A cookie manager for http requests in Dart, by which you can deal with the complex cookie policy and persist cookies easily.

### Add dependency

```yaml
dependencies:
  dio: ^0.0.1
```

## Usage

A simple usage example:

```dart
import 'package:cookie_jar/cookie_jar.dart';
void main() async {
  List<Cookie> cookies = [
    new Cookie("name", "wendux")
    new Cookie("location", "china")
  ];
    
  var cj = new DefaultCookieJar();
  cj.saveFromResponse(Uri.parse("https://www.baidu.com/"), cookies);
  List<Cookie> results = cj.loadForRequest(Uri.parse("https://www.baidu.com/xx"));
  print(results);  
}    
       
```

## Classes

### `DefaultCookieJar`

`DefaultCookieJar` is a default cookie manager which implements the standard cookie policy declared in RFC. DefaultCookieJar saves the cookies in **RAM**, so if the application exit, all cookies will be cleared.

### `PersistCookieJar`

`PersistCookieJar` is a cookie manager which implements the standard cookie policy declared in RFC. `PersistCookieJar`  persists the cookies in files, so if the application exit, the cookies always exist unless call `delete` explicitly.

### `SerializableCookie` 

This class is a wrapper for `Cookie` class. Because the `Cookie` class doesn't  support Json serialization, for the sake of persistence, we use this class instead of it.

## APIs

**void saveFromResponse(Uri uri, List<Cookie> cookies);**

Save the cookies for specified uri.

**List<Cookie> loadForRequest(Uri uri);**

Load the cookies for specified uri.

**delete(Uri uri,[bool withDomainSharedCookie = false] )**

Delete cookies for specified `uri`. This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.

If `withDomainSharedCookie` is `true `  ,  will delete the domain-shared cookies.

*Note: This API is only available in `PersistCookieJar` class.*

## Work with `HttpClient`

Using  `DefaultCookieJar` or `PersistCookieJar` manages  `HttpClient ` 's  request/response cookies is very easy:

```dart
var cj=new DefaultCookieJar();
...
request= await httpClient.openUrl(options.method, uri);
request.cookies.addAll(cj.loadForRequest(uri));
response= await request.close();
cj.saveFromResponse(uri, response.cookies);
```

## Work with dio

[dio](https://github.com/flutterchina/dio) is a powerful Http client for Dart, which supports Interceptors, Global configuration, FormData, File downloading, Timeout etc.  And [dio](https://github.com/flutterchina/dio) supports to manage cookies with cookie_jar, the simple example is:

```dart
var dio = new Dio();
dio.cookieJar=new PersistCookieJar("./cookies");
Response<String>  response = await dio.get("https://www.baidu.com");
```

More details about [dio](https://github.com/flutterchina/dio)  see : https://github.com/flutterchina/dio .

## Copyright & License

This open source project authorized by https://flutterchina.club , and the license is MIT.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/flutterchina/cookie_jar

