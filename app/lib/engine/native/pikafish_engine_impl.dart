import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pikafish_engine/pikafish_engine.dart';

import '../engine.dart';

class PikafishEngineImpl extends NativeEngine {
  //
  static final engine = PikafishEngine();

  bool _started = false;

  @override
  Future<void> startup() async {
    //
    if (_started) return;

    await engine.startup();

    final appDocDir = await getApplicationDocumentsDirectory();
    final nnueFile = File('${appDocDir.path}/pikafish.nnue');

    if (!(await nnueFile.exists())) {
      await nnueFile.create(recursive: true);
      final bytes = await rootBundle.load('assets/pikafish.nnue');
      await nnueFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }

    await send('setoption name EvalFile value ${nnueFile.path}');

    _started = true;
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
