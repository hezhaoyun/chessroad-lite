import 'dart:async';

import 'package:chessroad/config/local_data.dart';

import '../cchess/cc_base.dart';
import '../cchess/cc_rules.dart';
import '../engine/engine.dart';
import 'pikafish_engine.dart';
import '../cchess/position.dart';
import 'cloud_engine.dart';

class HybridEngine {
  //
  late final CloudEngine _cloudEngine;
  late final PikafishEngine _pikafishEngine;

  factory HybridEngine() => _instance;

  static final HybridEngine _instance = HybridEngine._();

  HybridEngine._() {
    _cloudEngine = CloudEngine();
    _pikafishEngine = PikafishEngine();
  }

  Future<void> startup() async {
    await _pikafishEngine.startup();
    await _pikafishEngine.applyConfig();
  }

  applyNativeEngineConfig() async {
    await _pikafishEngine.applyConfig();
  }

  Future<void> applyConfig() async {
    await _pikafishEngine.applyConfig();
  }

  Future<bool> go(Position position, EngineCallback callback) async {
    //
    if (LocalData().cloudEngineEnabled.value) {
      //
      final result = await Future.any([
        _cloudEngine.search(position, callback),
        Future.delayed(const Duration(seconds: 4), () => false),
      ]);

      if (result) return true;
    }

    return _pikafishEngine.go(position, callback);
  }

  Future<bool> goPonder(
      Position position, EngineCallback callback, String ponder) async {
    return _pikafishEngine.goPonder(position, callback, ponder);
  }

  Future<bool> goHint(Position position, EngineCallback callback) async {
    return _pikafishEngine.goHint(position, callback);
  }

  Future<void> ponderhit() async {
    return _pikafishEngine.ponderhit();
  }

  Future<void> stopPonder() async {
    return _pikafishEngine.stopPonder();
  }

  Future<void> shutdown() async {
    await _pikafishEngine.shutdown();
  }

  GameResult scanGameResult(Position position, String playerSide) {
    //
    final turnForPerson = (position.sideToMove == playerSide);

    if (position.isLongCheck()) {
      // born 'repeat' position by oppo
      return turnForPerson ? GameResult.win : GameResult.lose;
    }

    if (ChessRules.beCheckmated(position)) {
      return turnForPerson ? GameResult.lose : GameResult.win;
    }

    return (position.halfMove > 120) ? GameResult.draw : GameResult.pending;
  }

  Future<void> newGame() async => _pikafishEngine.newGame();
}
