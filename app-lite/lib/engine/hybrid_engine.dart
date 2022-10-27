import 'dart:async';

import 'package:chessroad/config/local_data.dart';

import '../common/prt.dart';
import '../engine/engine.dart';
import 'native_engine.dart';
import '../cchess/phase.dart';
import 'cloud_engine.dart';
import 'native_engine_config.dart';

class HybridEngine extends NativeEngine {
  //
  CloudEngine? _cloudEngine;
  NativeEngineImpl? _nativeEngine;
  NativeEngineConfig? _lastConfig;

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
  Future<void> applyConfig(NativeEngineConfig config) async {
    //
    if (_lastConfig == config) return;

    await _nativeEngine!.applyConfig(config);
    _lastConfig = config;
  }

  nativeEngineChanged() async {
    _nativeEngine?.engineChanged();
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
  Future<EngineResponse> search(Phase phase,
      {int? timeLimit, int? depth}) async {
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

    final nativeReponse = await _nativeEngine!.search(
      phase,
      timeLimit: _lastConfig!.timeLimit,
      depth: _lastConfig!.depth,
    );
    prt('nativeReponse: ${nativeReponse.type}');

    return nativeReponse;
  }
}
