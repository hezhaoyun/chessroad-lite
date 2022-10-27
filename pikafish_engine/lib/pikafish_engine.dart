import 'pikafish_engine_platform_interface.dart';

class PikafishEngine {
  Future<void> startup() {
    return PikafishEnginePlatform.instance.startup();
  }

  Future<void> send(String command) {
    return PikafishEnginePlatform.instance.send(command);
  }

  Future<String?> read() {
    return PikafishEnginePlatform.instance.read();
  }

  Future<bool?> isReady() {
    return PikafishEnginePlatform.instance.isReady();
  }

  Future<bool?> isThinking() {
    return PikafishEnginePlatform.instance.isThinking();
  }

  Future<void> shutdown() {
    return PikafishEnginePlatform.instance.shutdown();
  }
}
