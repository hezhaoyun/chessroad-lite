import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pikafish_engine/pikafish.dart';

import '../cchess/phase.dart';
import '../common/prt.dart';
import '../config/local_data.dart';
import 'engine.dart';
import 'pikafish_config.dart';

class PikafishEngine extends Engine {
  //
  static const kInfoPrefix = 'info ';
  static const kScoreIndicator = 'score ';

  factory PikafishEngine() => _instance;
  static final PikafishEngine _instance = PikafishEngine._internal();

  PikafishEngine._internal() {
    _setupEngine();
  }

  late Pikafish _engine;
  late StreamSubscription _subscription;

  EngineCallback? callback;

  _setupEngine() {
    _engine = Pikafish();
    _subscriber();
  }

  void _subscriber() {
    //
    _subscription = _engine.stdout.listen((line) {
      //
      prt('engine=> $line');

      if (callback == null) return;

      if (line.startsWith('info')) {
        callback!(EngineResponse(EngineType.pikafish, EngineInfo.parse(line)));
      } else if (line.startsWith('bestmove')) {
        callback!(EngineResponse(EngineType.pikafish, Bestmove.parse(line)));
      } else if (line.startsWith('nobestmove')) {
        callback!(EngineResponse(EngineType.pikafish, NoBestmove()));
      }
    });
  }

  @override
  Future<void> startup() async {
    //
    while (_engine.state.value == PikafishState.starting) {
      await Future.delayed(const Duration(microseconds: 100));
    }

    _engine.stdin = 'uci';

    await _setupNnue();
  }

  _setupNnue() async {
    //
    final appDocDir = await getApplicationDocumentsDirectory();
    final nnueFile = File('${appDocDir.path}/pikafish.nnue');

    if (!(await nnueFile.exists())) {
      await nnueFile.create(recursive: true);
      final bytes = await rootBundle.load('assets/pikafish.nnue');
      await nnueFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }

    _engine.stdin = 'setoption name EvalFile value ${nnueFile.path}';
  }

  @override
  Future<void> applyConfig() async {
    //
    final config = PikafishConfig(LocalData().profile);

    _engine.stdin = 'setoption name Threads value ${config.threads}';
    _engine.stdin = 'setoption name Hash value ${config.hashSize}';
    _engine.stdin = 'setoption name Ponder value ${config.ponder}';
    _engine.stdin = 'setoption name Skill Level value ${config.level}';
  }

  @override
  Future<bool> search(Phase phase, EngineCallback callback,
      {String? ponder}) async {
    //
    this.callback = callback;

    final position = phase.lastCapturedPhase;
    final moves = phase.movesAfterLastCaptured;

    var pos = 'position fen $position', go = '';
    if (moves != '') pos += ' moves $moves';

    if (ponder != null) {
      pos += ponder;
      go = 'go ponder infinite';
    } else {
      var timeLimit = PikafishConfig(LocalData().profile).timeLimit;
      if (timeLimit <= 90) timeLimit *= 1000;
      go = 'go movetime $timeLimit';
    }

    _engine.stdin = pos;
    _engine.stdin = go;

    return true;
  }

  @override
  void ponderhit() {
    //
    _engine.stdin = 'ponderhit';

    final timeLimit = PikafishConfig(LocalData().profile).timeLimit;
    scheduleStop(Duration(microseconds: timeLimit));
  }

  @override
  void scheduleStop(Duration? duration) {
    //
    if (duration == null) {
      _engine.stdin = 'stop';
    } else {
      Future.delayed(duration, () => _engine.stdin = 'stop');
    }
  }

  @override
  Future<void> shutdown() async {
    _engine.dispose();
    _subscription.cancel();
  }
}
