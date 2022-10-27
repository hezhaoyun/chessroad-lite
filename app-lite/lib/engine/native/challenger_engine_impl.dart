import 'package:challenger_engine/challenger_engine.dart';

import '../engine.dart';

class ChallengerEngineImpl extends NativeEngine {
  //
  static final engine = ChallengerEngine();

  @override
  Future<void> startup() async {
    await engine.startup();
  }

  @override
  Future<void> send(String command) async {
    await engine.send(command);
  }

  @override
  Future<String?> read() async {
    return await engine.read();
  }

  @override
  Future<void> shutdown() async {
    await engine.shutdown();
  }

  @override
  Future<bool> isReady() async {
    return await engine.isReady() ?? false;
  }

  @override
  Future<bool> isThinking() async {
    return await engine.isThinking() ?? false;
  }

  @override
  String buildGoCmd({int? timeLimit, int? depth}) {
    return 'go movetime $timeLimit';
  }
}
