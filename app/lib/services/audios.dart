import 'package:kplayer/kplayer.dart';
import '../config/local_data.dart';

class Audios {
  //
  static PlayerController? _bgmPlayer, _tonePlayer;

  static init() async {
    Player.boot();
    loopBgm();
  }

  static loopBgm() async {
    //
    var enabled = false;

    try {
      enabled = LocalData().bgmEnabled.value;
    } catch (_) {
      // TODO: 首次支行时，有可能配置还没有加载完
    }

    if (!enabled) return;

    const media = 'assets/audios/bg_music.mp3';

    if (_bgmPlayer == null) {
      try {
        _bgmPlayer = Player.asset(media, autoPlay: true);
        _bgmPlayer!.callback = (event) {
          if (event == PlayerEvent.end) _bgmPlayer!.replay();
        };
      } catch (_) {}
    }
  }

  static playTone(String fileName) async {
    //
    if (!LocalData().toneEnabled.value) return;

    final media = 'assets/audios/$fileName';

    try {
      _tonePlayer?.dispose();
      _tonePlayer = Player.asset(media, autoPlay: true);
    } catch (_) {}
  }

  static stopBgm() {
    try {
      _bgmPlayer?.stop();
    } catch (_) {}
    _bgmPlayer = null;
  }

  static Future<void> release() async {
    //
    try {
      _bgmPlayer?.stop();
      _tonePlayer?.stop();
    } catch (_) {}

    _bgmPlayer = _tonePlayer = null;
  }
}
