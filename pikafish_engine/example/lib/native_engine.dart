import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pikafish_engine/pikafish_engine.dart';
import 'package:flutter/material.dart';

class NativeEngine {
  //
  static const kInfoPrefix = 'info ';
  static const kScoreIndicator = 'score ';

  String? _scoreInfo;

  final _enginePlugin = PikafishEngine();

  Future<void> startup() async {
    //
    await _enginePlugin.startup();
    await waitResponse(['ucciok'], sleep: 10, times: 20);

    final appDocDir = await getApplicationDocumentsDirectory();
    final nnueFile = File('${appDocDir.path}/pikafish.nnue');

    if (!(await nnueFile.exists())) {
      await nnueFile.create(recursive: true);
      final bytes = await rootBundle.load('assets/pikafish.nnue');
      await nnueFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }

    final command = 'setoption name EvalFile value ${nnueFile.path}';
    await _enginePlugin.send(command);
  }

  Future<void> send(String command) async {
    await _enginePlugin.send(command);
  }

  Future<String?> read() async {
    return await _enginePlugin.read();
  }

  Future<void> shutdown() async {
    await _enginePlugin.shutdown();
    await waitResponse(['bye'], sleep: 10, times: 20);
  }

  Future<bool?> isReady() async {
    return await _enginePlugin.isReady();
  }

  Future<bool?> isThinking() async {
    return await _enginePlugin.isThinking();
  }

  Future<String> waitResponse(List<String> prefixes,
      {sleep = 100, times = 350}) async {
    //
    if (times <= 0) return '';

    String? response = await read();
    debugPrint('response: $response');

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
      }

      if (response!.startsWith(kInfoPrefix) &&
          response.contains(kScoreIndicator)) {
        _scoreInfo = response;
      }
    }

    return Future<String>.delayed(
      Duration(milliseconds: sleep),
      () => waitResponse(prefixes, sleep: sleep, times: times - 1),
    );
  }
}
