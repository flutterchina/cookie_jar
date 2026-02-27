# Migration Guide

This document gathered all breaking changes and migration requirements between versions.

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
  Going forward a `CookieJar` can also return synchronously. If every call is 
  properly awaited, nothing should break.
  Usage in an `unawaited` method is no longer possible. The `WebCookieJar` has
  been migrated to always complete synchronously.

- Changing Cookie deletion:
  To allow implementers further flexibility the `delete` method has been removed
  from the `CookieJar` interface. Users should migrate to the more flexible 
  `deleteWhere` method:
  ```dart
  final jar = CookieJar();
  // Check what Cookies you want to have deleted.
  jar.deleteWhere((cookie) {
    return cookie.domain == 'example.com' || cookie.name == 'cookie1';
  }));
  ```

- Optional Cookie management interface:
  Cookie management interfaces like `deleteAll`, `deleteWhere` or `loadAll` have
  been made optional. It is up to the implementer to support these operations.
  Consult your implementers' documentation.

- Optional extra Cookie parameters:
  When loading Cookies in any way from the store (`loadForRequest`, `deleteWhere` or `loadAll`)
  implementers only have to provide the `Cookie.name` and `Cookie.value` attributes.

- [4.0.0](#400)

# 4.0.0

In version 3.0, when the path of Cookie is not specified, '/' will be used.
However, this is not standard.
In this case, the current URL path should be used.
Therefore, in 4.x, we updated it, but this will cause the
**PersistCookieJar in 4.x to be incompatible with the PersistCookieJar in 3.0**,
that is to say, we cannot continue to read and write old Cookies in 4.x.
We can upgrade to 4.x through one of the following two steps:

- Delete old Cookies (Note: The following code should only be executed once):
  ```dart
  // `ignoreExpires` and `oldPath` must be same with 3.x .
  PersistCookieJar(
    ignoreExpires: true, 
    storage: FileStorage(oldPath),
  ).deleteAll();
  ```
- Or use a new Cookie file (ignore old Cookies).
  ```dart
  PersistCookieJar( 
    // The path should be different from that in 3.x。
    storage: FileStorage(newPath), 
  );
  ```
