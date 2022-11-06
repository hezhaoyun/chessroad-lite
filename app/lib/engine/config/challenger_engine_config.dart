import '../../config/profile.dart';

class ChallengerEngineConfig {
  //
  static const kTimeLimit = 'eleeye_timeLimit';

  final Profile _profile;

  int get timeLimit => _profile[kTimeLimit] ?? 3;

  ChallengerEngineConfig(this._profile);

  save() async => await _profile.save();

  timeLimitPlus() {
    if (timeLimit < 90) _profile[kTimeLimit] = timeLimit + 1;
  }

  timeLimitReduce() {
    if (timeLimit > 1) _profile[kTimeLimit] = timeLimit - 1;
  }
}
