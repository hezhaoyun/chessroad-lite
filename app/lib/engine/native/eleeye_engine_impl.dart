import 'dart:io';

import 'package:chessroad/config/local_data.dart';
import 'package:eleeye_engine/eleeye_engine.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../cchess/phase.dart';
import '../../common/prt.dart';
import '../engine.dart';
import '../config/eleeye_engine_config.dart';

class EleeyeEngineImpl extends NativeEngine {
  //
  static final engine = EleeyeEngine();

  @override
  Future<void> startup() async {
    await engine.startup();
    await _setBookFile();
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
  Future<void> applyConfig() async {
    //
    final config = EleeyeEngineConfig(LocalData().profile);

    await send('setoption knowledge ${config.knowledge}');
    await send('setoption pruning ${config.pruning}');
    await send('setoption randomness ${config.randomness}');
    await send('setoption usebook ${config.useBook}');
  }

  @override
  String buildPositionCmd(Phase phase) {
    return phase.buildPositionCommand(forEleeye: true);
  }

  Future<void> _setBookFile() async {
    //
    final docDir = await getApplicationDocumentsDirectory();
    final bookFile = File('${docDir.path}/eleeye_book.dat');

    try {
      if (!await bookFile.exists()) {
        await bookFile.create(recursive: true);
        final bytes = await rootBundle.load('assets/eleeye_book.dat');
        await bookFile.writeAsBytes(bytes.buffer.asUint8List());
      }
    } catch (e) {
      prt(e.toString());
    }

    await send('setoption bookfiles ${bookFile.path}');
  }
}
