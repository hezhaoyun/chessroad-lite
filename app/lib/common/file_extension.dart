import 'dart:io';

extension FileExtention on FileSystemEntity {
  String get name => path.split(Platform.isWindows ? '\\' : '/').last;
  String get basename =>
      path.split(Platform.isWindows ? '\\' : '/').last.split('.').first;
  String get ext => path.split('.').last;
}
