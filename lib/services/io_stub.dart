// Stub for web platform when dart:io is not available
// This file provides stub implementations that match dart:io API
// These methods will never actually execute on web due to kIsWeb checks

class File {
  final String path;
  File(this.path);
  Future<void> writeAsBytes(List<int> bytes) async {
    throw UnimplementedError('File operations not available on web');
  }
  Future<void> delete() async {
    throw UnimplementedError('File operations not available on web');
  }
}

class Directory {
  final String path;
  Directory(this.path);
  
  static Directory get systemTemp {
    throw UnimplementedError('Directory operations not available on web');
  }
  
  Future<Directory> createTemp(String prefix) async {
    throw UnimplementedError('Directory operations not available on web');
  }
  
  Future<void> delete({bool recursive = false}) async {
    throw UnimplementedError('Directory operations not available on web');
  }
}
