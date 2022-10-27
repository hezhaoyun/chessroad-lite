import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eleeye_engine_platform_interface.dart';

/// An implementation of [EleeyeEnginePlatform] that uses method channels.
class MethodChannelEleeyeEngine extends EleeyeEnginePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('eleeye_engine');

  @override
  Future<void> startup() async {
    await methodChannel.invokeMethod<int>('startup');
  }

  @override
  Future<void> send(String command) async {
    await methodChannel.invokeMethod<int>('send', command);
  }

  @override
  Future<String?> read() async {
    return await methodChannel.invokeMethod<String>('read');
  }

  @override
  Future<bool?> isReady() async {
    return await methodChannel.invokeMethod<bool>('isReady');
  }

  @override
  Future<bool?> isThinking() async {
    return await methodChannel.invokeMethod<bool>('isThinking');
  }

  @override
  Future<void> shutdown() async {
    await methodChannel.invokeMethod<int>('shutdown');
  }
}
