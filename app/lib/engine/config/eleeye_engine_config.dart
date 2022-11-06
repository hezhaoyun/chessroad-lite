import '../../config/profile.dart';

class EleeyeEngineConfig {
  //
  static const kTimeLimit = 'eleeye_timeLimit';
  static const kKnowledge = 'eleeye_knowledge';
  static const kPruning = 'eleeye_pruning';
  static const kRandomness = 'eleeye_randomness';
  static const kUseBook = 'eleeye_useBook';

  final Profile _profile;
  EleeyeEngineConfig(this._profile);

  int get timeLimit => _profile[kTimeLimit] ?? 3;

  // none, small, medium, large
  String get knowledge => _profile[kKnowledge] ?? 'medium';

  String get pruning => _profile[kPruning] ?? 'medium';

  String get randomness => _profile[kRandomness] ?? 'medium';

  bool get useBook => _profile[kUseBook] ?? true;

  Profile get profile => _profile;

  save() async => await _profile.save();

  timeLimitPlus() {
    if (timeLimit < 90) _profile[kTimeLimit] = timeLimit + 1;
  }

  timeLimitReduce() {
    if (timeLimit > 1) _profile[kTimeLimit] = timeLimit - 1;
  }
}
