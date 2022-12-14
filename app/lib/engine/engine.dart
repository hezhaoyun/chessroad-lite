import '../cchess/phase.dart';

class EngineResponse {
  final String type;
  final String engine;
  final dynamic value;
  EngineResponse(this.type, this.engine, {this.value});
}

abstract class Engine {
  //
  static const kCloud = 'cloud-engine';
  static const kNative = 'native-engine';

  static const kMove = 'move';
  static const kScore = 'score';

  static const kBestMove = 'bestmove';
  static const kNoBestMove = 'nobestmove';

  static const kTimeout = 'timeout';
  static const kNetworkError = 'network-error';
  static const kDataError = 'data-error';
  static const kUnknownError = 'unknown-error';

  Future<void> startup() async {}

  Future<void> send(String command) async {}

  Future<String?> read() async => null;

  Future<void> shutdown() async {}

  Future<bool> isReady() async => true;

  Future<bool> isThinking() async => false;

  Future<EngineResponse> search(Phase phase, {int? timeLimit}) async {
    return EngineResponse(kUnknownError, kUnknownError, value: '');
  }
}

abstract class NativeEngine extends Engine {
  //
  static const kNameEleeye = '象眼';
  static const kNameChallenger = '挑战者';
  static const kNamePikafish = '皮卡鱼';

  static final kEngineNames = [
    kNameEleeye,
    kNameChallenger,
    kNamePikafish,
  ];

  Future<void> applyConfig() async {}

  String buildPositionCmd(Phase phase) {
    return phase.buildPositionCommand();
  }

  String buildGoCmd({int? timeLimit}) {
    return 'go time $timeLimit';
  }

  int waitTimes({int? timeLimit}) => timeLimit! ~/ 10;
}
