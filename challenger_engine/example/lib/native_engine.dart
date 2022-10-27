import 'package:flutter/material.dart';
import 'package:challenger_engine/challenger_engine.dart';

class NativeEngine {
  //
  static const kInfoPrefix = 'info ';
  static const kScoreIndicator = 'score ';

  String? _scoreInfo;

  final _enginePlugin = ChallengerEngine();

  Future<void> startup() async {
    await _enginePlugin.startup();
  }

  Future<void> send(String command) async {
    await _enginePlugin.send(command);
  }

  Future<String?> read() async {
    return await _enginePlugin.read();
  }

  Future<void> shutdown() async {
    await _enginePlugin.shutdown();
  }

  Future<bool?> isReady() async {
    return await _enginePlugin.isReady();
  }

  Future<bool?> isThinking() async {
    return await _enginePlugin.isThinking();
  }

  Future<String> waitResponse(List<String> prefixes, {sleep = 100, times = 350}) async {
    //
    if (times <= 0) return '';

    String? response = (await read())?.trim();
    debugPrint('response: ${response ?? '.'}');

    if (response != null) {
      //
      for (var prefix in prefixes) {
        //
        if (response!.startsWith(prefix)) {
          //
          if (prefix == 'bestmove' && _scoreInfo != null) {
            response += ' $_scoreInfo';
            _scoreInfo = null;
          }

          return response;
        }

        if (response.startsWith(kInfoPrefix) && response.contains(kScoreIndicator)) {
          _scoreInfo = response;
        }
      }
    }

    return Future<String>.delayed(
      Duration(milliseconds: sleep),
      () => waitResponse(prefixes, sleep: sleep, times: times - 1),
    );
  }
}
