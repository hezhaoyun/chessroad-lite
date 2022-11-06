import 'package:chessroad/config/profile.dart';

class PikafishEngineConfig {
  //
  static const kTimeLimit = 'pikafish_timeLimit';
  static const kPonder = 'pikafish_ponder';
  static const kThreads = 'pikafish_threads';
  static const kLevel = 'pikafish_level';
  static const kHashSize = 'pikafish_hashSize';

  final Profile _profile;

  PikafishEngineConfig(this._profile);

  int get timeLimit => _profile[kTimeLimit] ?? 3;
  bool get ponder => _profile[kPonder] ?? false;
  int get threads => _profile[kThreads] ?? 1;
  int get level => _profile[kLevel] ?? 20;
  int get hashSize => _profile[kHashSize] ?? 16;

  Profile get profile => _profile;

  save() async => await _profile.save();

  timeLimitPlus() {
    if (timeLimit < 90) _profile[kTimeLimit] = timeLimit + 1;
  }

  timeLimitReduce() {
    if (timeLimit > 1) _profile[kTimeLimit] = timeLimit - 1;
  }

  levelPlus() {
    if (level < 20) _profile[kLevel] = level + 1;
  }

  levelReduce() {
    if (level > 1) _profile[kLevel] = level - 1;
  }

  threadsPlus() {
    if (threads < 16) _profile[kThreads] = threads + 1;
  }

  threadsReduce() {
    if (threads > 1) _profile[kThreads] = threads - 1;
  }

  hashSizePlus() {
    //
    var hs = hashSize;

    if (hs < 16) {
      hs++;
    } else if (hs < 256) {
      hs += 16;
      hs = hs ~/ 16 * 16;
    } else if (hs < 4096) {
      hs += 256;
      hs = hs ~/ 256 * 256;
    } else {
      hs += 4096;
      hs = hs ~/ 4096 * 4096;
    }

    if (hs >= 256 * 1024) hs = 256 * 1024;

    _profile[kHashSize] = hs;
  }

  hashSizeReduce() {
    //
    var hs = hashSize;

    if (hs <= 16) {
      hs--;
    } else if (hs <= 256) {
      hs -= 16;
      hs = hs ~/ 16 * 16;
    } else if (hs <= 4096) {
      hs -= 256;
      hs = hs ~/ 256 * 256;
    } else {
      hs -= 4096;
      hs = hs ~/ 4096 * 4096;
    }

    if (hs < 1) hs = 1;

    _profile[kHashSize] = hs;
  }
}
