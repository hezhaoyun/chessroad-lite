import 'dart:async';

import '../common/prt.dart';
import '../cchess/cc_base.dart';
import '../cchess/phase.dart';
import '../config/local_data.dart';
import 'native_engine_config.dart';
import 'engine.dart';
import 'native/eleeye_engine_impl.dart';
import 'native/challenger_engine_impl.dart';
import 'native/pikafish_engine_impl.dart';

class NativeEngineImpl extends NativeEngine {
  //
  static const kInfoPrefix = 'info ';
  static const kScoreIndicator = 'score ';

  factory NativeEngineImpl() => _instance;
  static final NativeEngineImpl _instance = NativeEngineImpl._internal();

  NativeEngineImpl._internal() {
    setupEngine();
  }

  String? _scoreInfo;
  NativeEngine? _currentEngine;

  setupEngine() {
    //
    final engineName = LocalData().engineName.value;

    if (engineName == NativeEngine.kNameChallenger) {
      _currentEngine = ChallengerEngineImpl();
    } else if (engineName == NativeEngine.kNamePikafish) {
      _currentEngine = PikafishEngineImpl();
    } else {
      _currentEngine = EleeyeEngineImpl();
    }
  }

  Future<void> engineChanged() async {
    //
    await shutdown();

    setupEngine();

    await startup();
  }

  @override
  Future<void> startup() async {
    //
    if (_currentEngine == null) return;
    await _currentEngine!.startup();

    final engineName = LocalData().engineName.value;

    if (engineName == NativeEngine.kNameChallenger) {
      await _currentEngine!.send('ucinewgame');
    } else if (engineName == NativeEngine.kNamePikafish) {
      await _currentEngine!.send('ucinewgame');
    } else {
      await _currentEngine!.send('newgame');
    }

    await waitResponse(['ucciok'], times: 30);
  }

  @override
  Future<void> applyConfig(NativeEngineConfig config) async {
    if (_currentEngine == null) return;
    await _currentEngine!.applyConfig(config);
    await waitResponse([], times: 20);
  }

  @override
  Future<void> send(String command) async {
    await _currentEngine?.send(command);
    prt('>>> $command');
  }

  @override
  Future<String?> read() async {
    final data = await _currentEngine?.read();
    if (data != null) prt('<<< $data');
    return data;
  }

  @override
  Future<void> shutdown() async {
    await _currentEngine?.shutdown();
    await waitResponse([], times: 20);
  }

  @override
  Future<bool> isReady() async {
    return await _currentEngine?.isReady() ?? false;
  }

  @override
  Future<bool> isThinking() async {
    return await _currentEngine?.isThinking() ?? false;
  }

  @override
  Future<EngineResponse> search(
    Phase phase, {
    int? timeLimit,
    int? depth,
  }) async {
    //
    if (await isThinking()) {
      await send('stop');
      final response = await waitResponse(
        [Engine.kBestMove, Engine.kNoBestMove],
        sleep: 50,
        times: 10,
      );
      prt('search.wait-stop-thinking: $response');
    }

    send(_currentEngine!.buildPositionCmd(phase));
    send(_currentEngine!.buildGoCmd(timeLimit: timeLimit, depth: depth));

    final waitTimes = _currentEngine!.waitTimes(
      timeLimit: timeLimit,
      depth: depth,
    );

    final response = await waitResponse(
      [Engine.kBestMove, Engine.kNoBestMove],
      sleep: 100,
      times: waitTimes + 1000,
    );

    // bestmove h9g7 info depth 10 seldepth 13 multipv 1 score cp -75 nodes 14091
    // nps 6358 hashfull 4 tbhits 0 time 2216 pv h9g7 h0g2 i9h9 i0h0 b9c7 h0h4 c9e7
    // c3c4 h7i7 h4h9 g7h9 g3g4

    if (response.startsWith(Engine.kBestMove)) {
      //
      // pikafish
      var regx = RegExp(
        r'bestmove (.{4}) info .*depth (\d+) .*score cp (-?\d+) .*nodes (\d+) .*time (\d+) .*pv\s?(.*)',
      );
      var match = regx.firstMatch(response);

      if (match != null) {
        //
        final step = match.group(1)!;
        final depth = int.parse(match.group(2)!);
        final score = int.parse(match.group(3)!);
        final nodes = int.parse(match.group(4)!);
        final time = int.parse(match.group(5)!);
        final pv = match.group(6)!;

        return EngineResponse(
          Engine.kMove,
          Engine.kNative,
          value: Move.fromEngineStep(
            step,
            score: score,
            depth: depth,
            nodes: nodes,
            time: time,
            pv: pv,
          ),
        );
      }

      // eleeye / challenger
      // move a3a4 info depth 11 score 123 pv
      regx = RegExp(r'bestmove\s(.{4}).+score\s(\-?\d+)');
      match = regx.firstMatch(response);

      if (match != null) {
        final step = match.group(1)!;
        final score = int.parse(match.group(2)!);
        return EngineResponse(
          Engine.kMove,
          Engine.kNative,
          value: Move.fromEngineStep(step, score: score),
        );
      }

      // ...
      // move a3a4
      regx = RegExp(r'move\s(.{4})');
      match = regx.firstMatch(response);

      if (match != null) {
        final step = match.group(1)!;
        return EngineResponse(
          Engine.kMove,
          Engine.kNative,
          value: Move.fromEngineStep(step),
        );
      }

      return EngineResponse(Engine.kDataError, Engine.kNative);
    }

    if (response.startsWith(Engine.kNoBestMove)) {
      return EngineResponse(Engine.kNoBestMove, Engine.kNative);
    }

    return EngineResponse(Engine.kTimeout, Engine.kNative);
  }

  Future<String> waitResponse(List<String> prefixes,
      {sleep = 100, times = 350}) async {
    //
    if (times <= 0) return '';

    String? response = await read();

    if (response != null) {
      //
      for (var prefix in prefixes) {
        //
        if (response!.startsWith(prefix)) {
          //
          if (prefix == Engine.kBestMove && _scoreInfo != null) {
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
