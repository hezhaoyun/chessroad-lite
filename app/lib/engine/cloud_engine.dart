import 'dart:math';
import '../common/prt.dart';
import '../engine/analysis.dart';
import '../engine/engine.dart';
import 'chess_db.dart';
import '../cchess/cc_base.dart';
import '../cchess/cc_fen.dart';
import '../cchess/phase.dart';

class CloudEngine extends Engine {
  //
  static String? banMoves;

  late DateTime _startTime;

  @override
  Future<EngineResponse> search(Phase phase,
      {int? timeLimit, int? depth}) async {
    //
    final fen = Fen.phaseToFen(phase);

    final response = await ChessDB.query(fen, banMoves: banMoves);
    if (response == null) {
      return EngineResponse(Engine.kNetworkError, Engine.kCloud);
    }

    if (response.startsWith(Engine.kMove)) {
      //
      final step = randomStep(response);

      if (step != null) {
        if (Move.validateEngineStep(step[Engine.kMove])) {
          return EngineResponse(
            Engine.kMove,
            Engine.kCloud,
            value: Move.fromEngineStep(
              step[Engine.kMove],
              score: int.parse(step[Engine.kScore]),
            ),
          );
        }
      }

      prt('data-error: $response');

      return EngineResponse(Engine.kDataError, Engine.kCloud);
    }

    prt('ChessDB.query: $response\n');
    return EngineResponse(Engine.kUnknownError, Engine.kCloud);
  }

  Future<EngineResponse> think(Phase phase, {bool byUser = true}) async {
    //
    if (byUser) {
      _startTime = DateTime.now();
    } else {
      final current = DateTime.now();
      if (current.difference(_startTime).inSeconds > 90) {
        return EngineResponse(Engine.kTimeout, Engine.kCloud);
      }
    }

    final fen = Fen.phaseToFen(phase);

    var response = await ChessDB.query(fen);
    if (response == null) {
      return EngineResponse(Engine.kNetworkError, Engine.kCloud);
    }

    if (response.startsWith(Engine.kMove)) {
      //
      final step = randomStep(response);

      if (step != null) {
        //
        if (Move.validateEngineStep(step[Engine.kMove])) {
          return EngineResponse(
            Engine.kMove,
            Engine.kCloud,
            value: Move.fromEngineStep(
              step[Engine.kMove],
              score: int.parse(step[Engine.kScore]),
            ),
          );
        }
      } else {
        //
        if (byUser) {
          response = await ChessDB.requestComputeBackground(fen);
          prt('ChessDB.requestComputeBackground: $response\n');
        }

        return Future<EngineResponse>.delayed(
            const Duration(seconds: 5), () => think(phase, byUser: false));
      }
    }

    prt('ChessDB.query: $response\n');
    return EngineResponse(Engine.kUnknownError, Engine.kCloud);
  }

  static Future<EngineResponse> analysis(Phase phase) async {
    //
    final fen = Fen.phaseToFen(phase);
    var response = await ChessDB.query(fen);

    if (response == null) {
      return EngineResponse(Engine.kNetworkError, Engine.kCloud);
    }

    if (response.startsWith(Engine.kMove)) {
      final items = AnalysisFetcher.fetch(response);
      if (items.isEmpty) return EngineResponse('no-result', Engine.kCloud);
      return EngineResponse('analysis', Engine.kCloud, value: items);
    }

    prt('ChessDB.query: $response\n');
    return EngineResponse(Engine.kUnknownError, Engine.kCloud);
  }

  static Map<String, dynamic>? randomStep(String response) {
    ///
    /// ove:b2a2,score:-236,rank:0,note:? (00-00),winrate:32.85
    ///
    final steps = <Map<String, dynamic>>[];

    final segments = response.split('|');
    var minScore = -0xFFFF;

    for (var i = 0; i < segments.length; i++) {
      //
      final kvps = fetchResponseTokens(segments[i]);

      final score = int.tryParse(kvps[Engine.kScore]!) ?? minScore;
      if (score <= minScore) break;

      minScore = score;
      steps.add(kvps);
    }

    if (steps.isNotEmpty) {
      return steps[Random().nextInt(steps.length)];
    }

    return null;
  }

  static Map<String, String> fetchResponseTokens(String step) {
    //
    final kvps = <String, String>{};

    step.split(',').forEach((token) {
      //
      final kv = token.split(':');

      if (kv.length == 2) {
        //
        final key = kv[0];
        String value = kv[1];

        if (key == Engine.kScore) {
          final pos = value.indexOf(' (');
          if (pos > -1) value = value.substring(0, pos);
        }

        kvps[key] = value;
      }
    });

    return kvps;
  }
}
