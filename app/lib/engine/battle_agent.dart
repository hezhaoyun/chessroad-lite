import '../cchess/cc_base.dart';
import '../cchess/cc_rules.dart';
import '../cchess/phase.dart';
import 'engine.dart';
import 'hybrid_engine.dart';

class BattleAgent {
  //
  static BattleAgent? _instance;

  late Engine _engine;

  static BattleAgent get shared {
    _instance ??= BattleAgent();
    return _instance!;
  }

  Future<void> startupEngine() async {
    //
    _engine = HybridEngine();
    await _engine.startup();

    await applyNativeEngineConfig();
  }

  applyNativeEngineConfig() async {
    if (_engine is HybridEngine) {
      await (_engine as HybridEngine).applyConfig();
    }
  }

  nativeEngineChanged() async {
    if (_engine is HybridEngine) {
      await (_engine as HybridEngine).nativeEngineChanged();
      await applyNativeEngineConfig();
    }
  }

  Future<EngineResponse> engineThink(Phase phase) async {
    return await _engine.search(phase);
  }

  Future<void> shutdownEngine() async {
    await _engine.shutdown();
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
