import 'dart:convert';
import 'dart:typed_data';

abstract class FileSystemEntity {
  /// Checks whether the file system entity with this path exists.
  ///
  /// Returns a `Future<bool>` that completes with the result.
  ///
  /// Since [FileSystemEntity] is abstract, every [FileSystemEntity] object
  /// is actually an instance of one of the subclasses [File],
  /// [Directory], and [Link]. Calling [exists] on an instance of one
  /// of these subclasses checks whether the object exists in the file
  /// system object exists *and* is of the correct type (file, directory,
  /// or link). To check whether a path points to an object on the
  /// file system, regardless of the object's type, use the [type]
  /// static method.
  Future<bool> exists();

  /// Synchronously checks whether the file system entity with this path
  /// exists.
  ///
  /// Since [FileSystemEntity] is abstract, every [FileSystemEntity] object
  /// is actually an instance of one of the subclasses [File],
  /// [Directory], and [Link].  Calling [existsSync] on an instance of
  /// one of these subclasses checks whether the object exists in the
  /// file system object exists and is of the correct type (file,
  /// directory, or link).  To check whether a path points to an object
  /// on the file system, regardless of the object's type, use the
  /// [typeSync] static method.
  bool existsSync();

  /// Deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a directory, and if [recursive] is `false`,
  /// the directory must be empty. Otherwise, if [recursive] is true, the
  /// directory and all sub-directories and files in the directories are
  /// deleted. Links are not followed when deleting recursively. Only the link
  /// is deleted, not its target.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows [delete] to be used to unconditionally delete any file
  /// system object.
  ///
  /// Returns a `Future<FileSystemEntity>` that completes with this
  /// [FileSystemEntity] when the deletion is done. If the [FileSystemEntity]
  /// cannot be deleted, the future completes with an exception.
  Future<FileSystemEntity> delete({bool recursive = false}) {
    throw UnimplementedError();
  }

  /// Synchronously deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a directory, and if [recursive] is false,
  /// the directory must be empty. Otherwise, if [recursive] is true, the
  /// directory and all sub-directories and files in the directories are
  /// deleted. Links are not followed when deleting recursively. Only the link
  /// is deleted, not its target.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows [deleteSync] to be used to unconditionally delete any
  /// file system object.
  ///
  /// Throws an exception if the [FileSystemEntity] cannot be deleted.
  void deleteSync({bool recursive = false}) => throw UnimplementedError();
}

abstract class File extends FileSystemEntity {
  /// Creates a [File] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  factory File(String path) => throw UnimplementedError();

  /// Create a [File] object from a URI.
  ///
  /// If [uri] cannot reference a file this throws [UnsupportedError].
  factory File.fromUri(Uri uri) => throw UnimplementedError();

  /// Creates a [File] object from a raw path.
  ///
  /// A raw path is a sequence of bytes, as paths are represented by the OS.
  factory File.fromRawPath(Uint8List rawPath) => throw UnimplementedError();

  /// Reads the entire file contents as a list of bytes.
  ///
  /// Returns a `Future<Uint8List>` that completes with the list of bytes that
  /// is the contents of the file.
  Future<Uint8List> readAsBytes();

  /// Reads the entire file contents as a string using the given
  /// [Encoding].
  ///
  /// Returns a `Future<String>` that completes with the string once
  /// the file contents has been read.
  Future<String> readAsString({Encoding encoding = utf8});

  /// Reads the entire file contents as lines of text using the given
  /// [Encoding].
  ///
  /// Returns a `Future<List<String>>` that completes with the lines
  /// once the file contents has been read.
  Future<List<String>> readAsLines({Encoding encoding = utf8});

  /// Writes a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it, and closes the file.
  /// Returns a `Future<File>` that completes with this [File] object once
  /// the entire operation has completed.
  ///
  /// By default [writeAsBytes] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  });

  /// Synchronously writes a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it and closes the file.
  ///
  /// By default [writeAsBytesSync] creates the file for writing and truncates
  /// the file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the [flush] argument is set to `true` data written will be
  /// flushed to the file system before returning.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  });

  /// Writes a string to a file.
  ///
  /// Opens the file, writes the string in the given encoding, and closes the
  /// file. Returns a `Future<File>` that completes with this [File] object
  /// once the entire operation has completed.
  ///
  /// By default [writeAsString] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  ///
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  });

  /// Get the path of the file.
  String get path;
}

/// The modes in which a [File] can be opened.
class FileMode {
  /// The mode for opening a file only for reading.
  static const read = FileMode._internal(0);

  /// Mode for opening a file for reading and writing. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const write = FileMode._internal(1);

  /// Mode for opening a file for reading and writing to the
  /// end of it. The file is created if it does not already exist.
  static const append = FileMode._internal(2);

  /// Mode for opening a file for writing *only*. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const writeOnly = FileMode._internal(3);

  /// Mode for opening a file for writing *only* to the
  /// end of it. The file is created if it does not already exist.
  static const writeOnlyAppend = FileMode._internal(4);

  final int mode;

  const FileMode._internal(this.mode);
}

abstract class Directory extends FileSystemEntity {
  /// Gets the path of this directory.
  String get path;

  /// Creates a [Directory] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  factory Directory(String path) => throw UnimplementedError();

  factory Directory.fromRawPath(Uint8List path) => throw UnimplementedError();

  /// Create a [Directory] from a URI.
  ///
  /// If [uri] cannot reference a directory this throws [UnsupportedError].
  factory Directory.fromUri(Uri uri) => throw UnimplementedError();

  /// Creates a directory object pointing to the current working
  /// directory.
  static Directory get current => throw UnimplementedError();

  /// A [Uri] representing the directory's location.
  ///
  /// The URI's scheme is always "file" if the entity's [path] is
  /// absolute, otherwise the scheme will be empty and the URI relative.
  /// The URI's path always ends in a slash ('/').
  Uri get uri;

  /// Sets the current working directory of the Dart process.
  ///
  /// This affects all running isolates.
  /// The new value set can be either a [Directory] or a [String].
  ///
  /// The new value is passed to the OS's system call unchanged, so a
  /// relative path passed as the new working directory will be
  /// resolved by the OS.
  ///
  /// Note that setting the current working directory is a synchronous
  /// operation and that it changes the working directory of *all*
  /// isolates.
  ///
  /// Use this with care — especially when working with asynchronous
  /// operations and multiple isolates. Changing the working directory,
  /// while asynchronous operations are pending or when other isolates
  /// are working with the file system, can lead to unexpected results.
  static set current(path) {
    throw UnimplementedError();
  }

  /// Creates the directory if it doesn't exist.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// Returns a `Future<Directory>` that completes with this
  /// directory once it has been created. If the directory cannot be
  /// created the future completes with an exception.
  Future<Directory> create({bool recursive = false});

  /// Synchronously creates the directory if it doesn't exist.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// If the directory cannot be created an exception is thrown.
  void createSync({bool recursive = false});

  /// Returns a human readable representation of this [Directory].
  @override
  String toString();
}
