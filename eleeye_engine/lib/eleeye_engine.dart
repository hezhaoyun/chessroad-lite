import 'eleeye_engine_platform_interface.dart';

class EleeyeEngine {
  Future<void> startup() {
    return EleeyeEnginePlatform.instance.startup();
  }

  Future<void> send(String command) {
    return EleeyeEnginePlatform.instance.send(command);
  }

  Future<String?> read() {
    return EleeyeEnginePlatform.instance.read();
  }

  Future<bool?> isReady() {
    return EleeyeEnginePlatform.instance.isReady();
  }

  Future<bool?> isThinking() {
    return EleeyeEnginePlatform.instance.isThinking();
  }

  Future<void> shutdown() {
    return EleeyeEnginePlatform.instance.shutdown();
  }
}
