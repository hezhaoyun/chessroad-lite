import 'dart:async';

import 'package:chessroad/config/local_data.dart';

import '../cchess/cc_base.dart';
import '../cchess/cc_rules.dart';
import '../engine/engine.dart';
import 'pikafish_engine.dart';
import '../cchess/phase.dart';
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

  Future<bool> search(Phase phase, EngineCallback callback,
      {String? ponder}) async {
    //
    if (LocalData().cloudEngineEnabled.value) {
      //
      final result = await Future.any([
        _cloudEngine.search(phase, callback),
        Future.delayed(const Duration(seconds: 4), () => false),
      ]);

      if (result) return true;
    }

    return _pikafishEngine.search(phase, callback, ponder: ponder);
  }

  Future<void> ponderhit() async => _pikafishEngine.ponderhit();

  Future<void> missPonder() async => _pikafishEngine.missPonder();

  Future<void> shutdown() async {
    await _pikafishEngine.shutdown();
  }

  BattleResult scanBattleResult(Phase phase, String playerSide) {
    //
    final turnForPerson = (phase.side == playerSide);

    if (phase.isLongCheck()) {
      // born 'repeat' phase by oppo
      return turnForPerson ? BattleResult.win : BattleResult.lose;
    }

    if (ChessRules.beKilled(phase)) {
      return turnForPerson ? BattleResult.lose : BattleResult.win;
    }

    return (phase.halfMove > 120) ? BattleResult.draw : BattleResult.pending;
  }
}
