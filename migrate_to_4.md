# Migrate to 4.x

In version 3.0, when the path of cookie is not specified, '/' will be used. However, this is not standard. In this case, the current URL path should be used. Therefore, in 4.x, we updated it, but this will cause the **PersistCookieJar in 4.x to be incompatible with the PersistCookieJar in 3.0**, that is say, we cannot continue to read and write old cookies  in 4.x. We can upgrade to 4.x through one of following two steps:

- Delete old cookies (Note: The following code should only be executed once):
  ```dart
  // `ignoreExpires` and `oldPath` must be same with 3.x .
  PersistCookieJar(
   ignoreExpires: true, 
   storage: FileStorage(oldPath),
  ).deleteAll();
  ```
- Or use a new cookie file（ignore old cookies）.
  ```dart
  var cj = PersistCookieJar( 
     ...
     // The path should be different from that in 3.x。
     storage: FileStorage(newPath), 
   );
  ```

---
# 升级到 4.x

在3.0版本中，当cookie的path没有指定时，会使用'/'，但这并不标准，这种情况应该使用当前URL路径，因此，在4.x中，我们进行了更新，但这会导致**4.x中的 PersistCookieJar 无法向下兼容**，也就是说，我们不能在4.x中再继续读写旧版本的cookie。可以通过下面方式升级到4.x：

- 删除旧版本创建的cookie（注意：删除代码应该只被执行一次）。
  ```dart
  // 删除时，`ignoreExpires` 和 `oldPath` 的值和 3.x 的值必须一致 .
  PersistCookieJar(
   ignoreExpires: true, 
   storage: FileStorage(oldPath),
  ).deleteAll();
  ```
- 或者直接使用新的cookie文件（忽略旧cookie文件）：
  ```dart
  var cj = PersistCookieJar( 
     ...
     // The path should be different from that in 3.x。
     storage: FileStorage(newPath), 
   );
  ```
