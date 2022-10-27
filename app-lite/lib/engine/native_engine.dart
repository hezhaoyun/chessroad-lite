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
    engineChanged();
  }

  Future<void> engineChanged() async {
    //
    await _engine?.shutdown();

    if (LocalData().engineName.value == NativeEngine.kNameChallenger) {
      _engine = ChallengerEngineImpl();
    } else if (LocalData().engineName.value == NativeEngine.kNamePikafish) {
      _engine = PikafishEngineImpl();
    } else {
      _engine = EleeyeEngineImpl();
    }

    await _engine?.startup();
  }

  NativeEngine? _engine;
  String? _scoreInfo;

  @override
  Future<void> startup() async {
    if (_engine == null) return;
    await _engine!.startup();
    await waitResponse(['ucciok'], sleep: 10, times: 20);
  }

  @override
  Future<void> applyConfig(NativeEngineConfig config) async {
    if (_engine == null) return;
    await _engine!.applyConfig(config);
    await waitResponse([], sleep: 10, times: 20);
  }

  @override
  Future<void> send(String command) async {
    await _engine?.send(command);
    prt('>>> $command');
  }

  @override
  Future<String?> read() async {
    final data = await _engine?.read();
    if (data != null) prt('<<< $data');
    return data;
  }

  @override
  Future<void> shutdown() async => await _engine?.shutdown();

  @override
  Future<bool> isReady() async => await _engine?.isReady() ?? false;

  @override
  Future<bool> isThinking() async => await _engine?.isThinking() ?? false;

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

    send(_engine!.buildPositionCmd(phase));
    send(_engine!.buildGoCmd(timeLimit: timeLimit, depth: depth));

    final waitTimes = _engine!.waitTimes(timeLimit: timeLimit, depth: depth);

    final response = await waitResponse(
      [Engine.kBestMove, Engine.kNoBestMove],
      sleep: 100,
      times: waitTimes + 100,
    );

    if (response.startsWith(Engine.kBestMove)) {
      //
      // move a3a4 info depth 11 score 123 pv
      final regx = RegExp(r'bestmove\s(.{4}).+score\s(\-?\d+)');
      final match = regx.firstMatch(response);

      if (match != null) {
        final step = match.group(1)!;
        final score = int.parse(match.group(2)!);
        return EngineResponse(
          Engine.kMove,
          Engine.kNative,
          value: Move.fromEngineStep(step, score: score),
        );
      }

      // move a3a4
      final regxWithoutInfo = RegExp(r'move\s(.{4})');
      final matchWithoutInfo = regxWithoutInfo.firstMatch(response);

      if (matchWithoutInfo != null) {
        final step = matchWithoutInfo.group(1)!;
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

  Future<String> waitResponse(
    List<String> prefixes, {
    sleep = 100,
    times = 350,
  }) async {
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
