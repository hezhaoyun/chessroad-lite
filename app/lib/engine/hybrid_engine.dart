import 'dart:async';

import 'package:chessroad/config/local_data.dart';

import '../engine/engine.dart';
import 'pikafish_engine.dart';
import '../cchess/phase.dart';
import 'cloud_engine.dart';

class HybridEngine extends Engine {
  //
  late CloudEngine _cloudEngine;
  late PikafishEngine _nativeEngine;
  EngineCallback? callback;

  @override
  Future<void> startup() async {
    //
    _cloudEngine = CloudEngine();
    await _cloudEngine.startup();

    _nativeEngine = PikafishEngine();
    await _nativeEngine.startup();
  }

  @override
  Future<void> applyConfig() async {
    await _nativeEngine.applyConfig();
  }

  @override
  Future<void> shutdown() async {
    await _cloudEngine.shutdown();
    await _nativeEngine.shutdown();
  }

  @override
  Future<bool> search(Phase phase, EngineCallback callback,
      {String? ponder}) async {
    //
    this.callback = callback;

    if (LocalData().cloudEngineEnabled.value) {
      //
      final result = await Future.any([
        _cloudEngine.search(phase, callback),
        Future.delayed(const Duration(seconds: 4), () => false),
      ]);

      if (result) return true;
    }

    return _nativeEngine.search(phase, callback, ponder: ponder);
  }

  @override
  Future<void> ponderhit() async => await _nativeEngine.ponderhit();

  @override
  Future<void> missPonder() async => await _nativeEngine.missPonder();
}
