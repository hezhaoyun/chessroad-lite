import 'challenger_engine_platform_interface.dart';

class ChallengerEngine {
  Future<void> startup() {
    return ChallengerEnginePlatform.instance.startup();
  }

  Future<void> send(String command) {
    return ChallengerEnginePlatform.instance.send(command);
  }

  Future<String?> read() {
    return ChallengerEnginePlatform.instance.read();
  }

  Future<bool?> isReady() {
    return ChallengerEnginePlatform.instance.isReady();
  }

  Future<bool?> isThinking() {
    return ChallengerEnginePlatform.instance.isThinking();
  }

  Future<void> shutdown() {
    return ChallengerEnginePlatform.instance.shutdown();
  }
}
