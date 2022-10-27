import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pikafish_engine_method_channel.dart';

abstract class PikafishEnginePlatform extends PlatformInterface {
  /// Constructs a PikafishEnginePlatform.
  PikafishEnginePlatform() : super(token: _token);

  static final Object _token = Object();

  static PikafishEnginePlatform _instance = MethodChannelPikafishEngine();

  /// The default instance of [PikafishEnginePlatform] to use.
  ///
  /// Defaults to [MethodChannelPikafishEngine].
  static PikafishEnginePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PikafishEnginePlatform] when
  /// they register themselves.
  static set instance(PikafishEnginePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> startup() {
    throw UnimplementedError('startup() has not been implemented.');
  }

  Future<void> send(String command) {
    throw UnimplementedError('send() has not been implemented.');
  }

  Future<String?> read() {
    throw UnimplementedError('read() has not been implemented.');
  }

  Future<bool?> isReady() {
    throw UnimplementedError('isReady() has not been implemented.');
  }

  Future<bool?> isThinking() {
    throw UnimplementedError('isThinking() has not been implemented.');
  }

  Future<void> shutdown() {
    throw UnimplementedError('shutdown() has not been implemented.');
  }
}
