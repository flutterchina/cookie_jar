# CookieJar

[![Pub](https://img.shields.io/pub/v/cookie_jar.svg?style=flat-square)](https://pub.dartlang.org/packages/cookie_jar)
[![support](https://img.shields.io/badge/platform-flutter%7Cdart%20vm-ff69b4.svg?style=flat-square)](https://github.com/flutterchina/cookie_jar)

A cookie manager for http requests in Dart, by which you can deal with the complex cookie policy and persist cookies easily.

### Add dependency

```yaml
dependencies:
  cookie_jar: 3.0.1
```

## Usage

A simple usage example:

```dart
import 'package:cookie_jar/cookie_jar.dart';
void main() async {
  List<Cookie> cookies = [Cookie("name", "wendux"),Cookie("location", "china")];
  var cj = CookieJar();
  //Save cookies   
  await cj.saveFromResponse(Uri.parse("https://www.baidu.com/"), cookies);
  //Get cookies  
  List<Cookie> results = await cj.loadForRequest(Uri.parse("https://www.baidu.com/xx"));
  print(results);  
}    
       
```

## Classes

### `SerializableCookie`

This class is a wrapper for `Cookie` class. Because the `Cookie` class doesn't  support Json serialization, for the sake of persistence, we use this class instead of it.

### `CookieJar`

`CookieJar` is a default cookie manager which implements the standard cookie policy declared in RFC. CookieJar saves the cookies in **RAM**, so if the application exit, all cookies will be cleared. A example as follow:

```dart
var cj= CookieJar();
```

### `PersistCookieJar`

`PersistCookieJar` is a cookie manager which implements the standard cookie policy declared in RFC. `PersistCookieJar`  persists the cookies in files, so if the application exit, the cookies always exist unless call `delete` explicitly. A example as follows:

```dart
// Cookie files will be saved in files in "./cookies"
var cj = PersistCookieJar(
    ignoreExpires:true, //save/load even cookies that have expired.
);
```

> **Note**: In Flutter, File system is different from PC,  you can use [path_provider](https://pub.dartlang.org/packages/path_provider) package to get the path :
>
> ```dart
> // API `getTemporaryDirectory` is from "path_provider" package.
> Directory tempDir = await getTemporaryDirectory();
> var tempPath = tempDir.path;
> var cj = PersistCookieJar(
>           ignoreExpires: true,
>           storage: FileStorage(tempPath)
>         );
> ```

#### Storage

Now, You can customize your own storage，for more details refer to the implementation of `FileStorage` 

## APIs

**Future<void>  saveFromResponse(Uri uri, List<Cookie> cookies);**

Save the cookies for specified uri.

**Future<List<Cookie>> loadForRequest(Uri uri);**

Load the cookies for specified uri.

**Future<void> delete(Uri uri,[bool withDomainSharedCookie = false] )**

Delete cookies for specified `uri`. This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.

If `withDomainSharedCookie` is `true `  ,  will delete the domain-shared cookies.

**Future<void> deleteAll();**

Delete all cookies 。

## Working with `HttpClient`

Using  `CookieJar` or `PersistCookieJar` manages  `HttpClient ` 's  request/response cookies is very easy:

```dart
var cj=CookieJar();
...
request = await httpClient.openUrl(options.method, uri);
request.cookies.addAll(await cj.loadForRequest(uri));
response = await request.close();
await cj.saveFromResponse(uri, response.cookies);
```

## Working with dio

[dio](https://github.com/flutterchina/dio) is a powerful Http client for Dart, which supports Interceptors, Global configuration, FormData, File downloading, Timeout etc.  And [dio](https://github.com/flutterchina/dio) supports to manage cookies with cookie_jar, the simple example is:

```dart
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

main() async {
  var dio = Dio();
  var cookieJar=CookieJar();
  dio.interceptors.add(CookieManager(cookieJar));
  await dio.get("https://baidu.com/");
  // Print cookies
  print(await cookieJar.loadForRequest(Uri.parse("https://baidu.com/")));
  // second request with the cookie
  await dio.get("https://baidu.com/");
}
```

> Note: cookieJar 3.0 need:
>
> - dio version >= 4.0
> - dio_cookie_manager >= 3.0

More details about [dio](https://github.com/flutterchina/dio)  see : https://github.com/flutterchina/dio .

## Copyright & License

This open source project authorized by https://flutterchina.club , and the license is MIT.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/flutterchina/cookie_jar

