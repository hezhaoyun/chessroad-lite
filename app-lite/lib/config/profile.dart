import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../common/prt.dart';

class Profile {
  //
  static const kLocalFile = 'local-profile.json';
  static const kSharedFile = 'default-profile.json';

  final String fileName;
  Profile._create(this.fileName);

  static final _local = Profile._create(kLocalFile);
  static final _shared = Profile._create(kSharedFile);

  factory Profile.local() => _local;
  factory Profile.shared() => _shared;

  File? _file;
  bool _loadOk = false;
  Map<String, dynamic> _values = {};

  // 在当前配置中找不到配置项时，可以从此备份配置项中查找配置项
  Profile? backup;

  operator [](String key) => _values[key] ?? backup?[key];

  operator []=(String key, dynamic value) => _values[key] = value;

  Future<Profile> load() async {
    //
    if (!_loadOk) {
      //
      final docDir = await getApplicationDocumentsDirectory();
      _file = File('${docDir.path}/$fileName');

      try {
        final contents = await _file!.readAsString();
        _values = jsonDecode(contents);
        _loadOk = true;
      } catch (e) {
        prt('Profile.prepare: $e');
      }
    }

    return this;
  }

  void update(Map<String, dynamic> values) {
    for (final key in values.keys) {
      _values[key] = values[key];
    }
  }

  Future<bool> save() async {
    //
    if (_file == null || _values.isEmpty) return false;

    _file!.create(recursive: true);

    try {
      final contents = jsonEncode(_values);
      await _file!.writeAsString(contents);
    } catch (e) {
      prt('Profile.save: $e');
      return false;
    }

    return true;
  }
}
