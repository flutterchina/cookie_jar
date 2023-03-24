/// The storage concept to persist cookies.
abstract class Storage {
  const Storage();

  /// Initialization for the [Storage], e.g. prepare storage paths.
  Future<void> init(bool persistSession, bool ignoreExpires);

  /// Read cookie string from the given [key] in the storage.
  Future<String?> read(String key);

  /// Write cookie [value] with the given [key] to the storage.
  Future<void> write(String key, String value);

  /// Delete the cookie value with the given [key] in the storage.
  Future<void> delete(String key);

  /// Delete all cookies in the storage (regardless the keys).
  Future<void> deleteAll(List<String> keys);
}
