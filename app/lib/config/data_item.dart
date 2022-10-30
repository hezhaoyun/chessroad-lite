import 'profile.dart';

class DataItem {
  //
  final Profile profile;
  final String key;
  final dynamic defValue;

  const DataItem(this.profile, this.key, this.defValue);

  dynamic get value => profile[key] ?? defValue;

  set value(dynamic v) => profile[key] = v;
}
