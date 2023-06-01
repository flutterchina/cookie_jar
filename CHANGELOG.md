# CHANGELOG

## 4.0.3

- Fix runtime type cast exception.

## 4.0.2

- Use `universal_io` to handle imports.
  This also bumps the minimum required SDK version to `2.15.0`.

## 4.0.1

- Clean codes and update documents.
- Support to compile on Web.

## 4.0.0

- Preserve all cookies that with same name but in different paths when request (as Chrome acts).
  For example, in request header: `Cookie: a=1; a=2; a=3`.
  Note: Cookies with same name will be sorted by path (longer path first)
  when return (`List<Cookie>` that `loadForRequest` returned).
- Fix path and domain match error (#30)
- Fix #31: Use the "directory" of request-uri as default path if there is no 'Path' component in Set-Cookie line
  (in 3.x, used root '/', it is not standard).

## 3.0.1

- refactor

## 3.0.0

- Change all APIs to async
- Add `delete` 、 `deleteAll` APIs in CookieJar class.
- Support custom cookie persistent storage。

## 2.0.1

- support nullsafety

## 1.0.1

- add `forceInit` method for PersistCookieJar
- handle  cookie name conflicts 

## 0.0.1

- Initial version, created by Stagehand
