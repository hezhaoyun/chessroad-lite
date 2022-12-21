import 'package:kplayer/kplayer.dart';
import '../config/local_data.dart';

class Audios {
  //
  static PlayerController? _bgmPlayer, _tonePlayer;
  static bool booted = false;

  static init() async {
    Player.boot();
    booted = true;
  }

  static loopBgm() async {
    //
    if (!booted) return;

    final enabled = LocalData().bgmEnabled.value;
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
