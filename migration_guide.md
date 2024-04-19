# Migration Guide

This document gathered all breaking changes and migrations requirement between versions.

<!--
When new content need to be added to the migration guide, make sure they're following the format:
1. Add a version in the *Breaking versions* section, with a version anchor.
2. Use *Summary* and *Details* to introduce the migration.
-->

## Breaking versions

# NEXT

Version 5.0 brings a few refinements to the `CookieJar` interface.
Breaking changes include:

- Usage of `FutureOr` in interfaces.
  Going forward a CookieJar can also return synchronously. If every call is 
  properly awaited nothing should break.
  Usage in an `unawaited` method is no longer possible. The `WebCookieJar` has
  been migrated to always complete synchronously.

- Changing cookie deletion:
  To allow implementers further flexibility the `delete` method has been removed
  from the `CookieJar` interface. Users should migrate to the more flexible 
  `deleteWhere` method:
  ```dart
  final jar = CookieJar();
  // Check what cookies you want to have deleted.
  jar.deleteWhere((cookie) {
    cookie.domain == 'example.com' || cookie.name == 'cookie1';
  }));
  ```

- Optional cookie management interface:
  Cookie management interfaces like `deleteAll`, `deleteWhere` or `loadAll` have
  been made optional. It is up to the implementer to support these operations.
  Consult your implementers documentation.

- Optional extra cookie parameters:
  When loading cookies in any way from the store (`loadForRequest`, `deleteWhere` or `loadAll`)
  implementers only have to provide the `Cookie.name` and `Cookie.value` attributes.

- [4.0.0](#400)

# 4.0.0

In version 3.0, when the path of cookie is not specified, '/' will be used.
However, this is not standard.
In this case, the current URL path should be used.
Therefore, in 4.x, we updated it, but this will cause the
**PersistCookieJar in 4.x to be incompatible with the PersistCookieJar in 3.0**,
that is say, we cannot continue to read and write old cookies in 4.x.
We can upgrade to 4.x through one of following two steps:

- Delete old cookies (Note: The following code should only be executed once):
  ```dart
  // `ignoreExpires` and `oldPath` must be same with 3.x .
  PersistCookieJar(
    ignoreExpires: true, 
    storage: FileStorage(oldPath),
  ).deleteAll();
  ```
- Or use a new cookie file (ignore old cookies).
  ```dart
  PersistCookieJar( 
    // The path should be different from that in 3.x。
    storage: FileStorage(newPath), 
  );
  ```
