import 'dart:async';

import 'package:chessroad/config/local_data.dart';
import 'package:chessroad/engine/config/challenger_engine_config.dart';

import '../common/prt.dart';
import '../engine/engine.dart';
import 'config/eleeye_engine_config.dart';
import 'config/pikafish_engine_config.dart';
import 'native_engine.dart';
import '../cchess/phase.dart';
import 'cloud_engine.dart';

class HybridEngine extends NativeEngine {
  //
  CloudEngine? _cloudEngine;
  NativeEngineImpl? _nativeEngine;

  @override
  Future<void> startup() async {
    //
    await shutdown();

    _cloudEngine = CloudEngine();
    await _cloudEngine!.startup();

    _nativeEngine = NativeEngineImpl();
    await _nativeEngine!.startup();
  }

  @override
  Future<void> applyConfig() async {
    await _nativeEngine!.applyConfig();
  }

  nativeEngineChanged() async {
    await _nativeEngine?.engineChanged();
  }

  @override
  Future<void> shutdown() async {
    //
    if (_cloudEngine != null) {
      await _cloudEngine!.shutdown();
      _cloudEngine = null;
    }

    if (_nativeEngine != null) {
      await _nativeEngine!.shutdown();
      _nativeEngine = null;
    }
  }

  @override
  Future<EngineResponse> search(Phase phase, {int? timeLimit}) async {
    //
    if (LocalData().cloudEngineEnabled.value) {
      //
      final response = await Future.any([
        _cloudEngine!.search(phase),
        Future.delayed(Duration(seconds: timeLimit ?? 4), () {
          return EngineResponse(Engine.kTimeout, Engine.kCloud);
        }),
      ]);

      prt('cloudResponse: ${response.type}');

      if (response.type == Engine.kMove) {
        return response;
      }
    }

    if (timeLimit == null) {
      final engineName = LocalData().engineName.value;

      if (engineName == NativeEngine.kNameChallenger) {
        timeLimit = ChallengerEngineConfig(LocalData().profile).timeLimit;
      } else if (engineName == NativeEngine.kNamePikafish) {
        timeLimit = PikafishEngineConfig(LocalData().profile).timeLimit;
      } else {
        timeLimit = EleeyeEngineConfig(LocalData().profile).timeLimit;
      }
    }

    final nativeResponse = await _nativeEngine!.search(
      phase,
      timeLimit: timeLimit,
    );
    prt('nativeResponse: ${nativeResponse.type}');

    return nativeResponse;
  }
}
