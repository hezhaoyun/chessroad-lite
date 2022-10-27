import 'package:chessroad/engine/engine.dart';

import 'data_item.dart';
import 'profile.dart';

class LocalData {
  //
  late final Profile _profile;

  late final DataItem aceptedPrivacyPolicy;
  late final DataItem engineName;
  late final DataItem engineConfig;
  late final DataItem cloudEngineEnabled;
  late final DataItem lastReivewInvite;
  late final DataItem showAdDate;
  late final DataItem showAdTimes;
  late final DataItem uiFont;
  late final DataItem artFont;
  late final DataItem bgmEnabled;
  late final DataItem toneEnabled;
  late final DataItem highContrast;

  LocalData._internal();
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;

  Future<void> load() async {
    //
    _profile = await Profile.local().load();
    // 在分离远程数据和本地数据之前，所有的数据都存在 shared 文件里面
    // 这里为了保持对老版本的兼容，分离后，不能在本地数据中找到配置项时，就在 shared 里面查找
    _profile.backup = await Profile.shared().load();

    aceptedPrivacyPolicy = DataItem(_profile, 'acepted_privacy_policy', false);
    engineName = DataItem(_profile, 'engine_name', NativeEngine.kNameEleeye);
    engineConfig = DataItem(_profile, 'engine_config', 5);
    cloudEngineEnabled = DataItem(_profile, 'cloud_engine_enabled', true);
    lastReivewInvite = DataItem(_profile, 'last_review_invite', '');
    showAdDate = DataItem(_profile, 'show_ad_date', '');
    showAdTimes = DataItem(_profile, 'show_ad_times', 0);
    uiFont = DataItem(_profile, 'ui_font', '');
    artFont = DataItem(_profile, 'art_font', 'XiaoLi');
    bgmEnabled = DataItem(_profile, 'bgm_enabled', false);
    toneEnabled = DataItem(_profile, 'tone_enabled', true);
    highContrast = DataItem(_profile, 'high_contrast', false);
  }

  Future<bool> save() => _profile.save();
}
