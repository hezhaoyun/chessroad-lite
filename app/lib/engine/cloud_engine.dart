import 'dart:math';

import '../common/prt.dart';
import '../engine/analysis.dart';
import '../engine/engine.dart';
import 'chess_db.dart';
import '../cchess/cc_fen.dart';
import '../cchess/position.dart';

class CloudEngine {
  //
  factory CloudEngine() => _instance;

  static final CloudEngine _instance = CloudEngine._();

  CloudEngine._();

  EngineCallback? callback;

  Future<bool> search(Position position, EngineCallback callback,
      {String? ponder, String? banMoves}) async {
    //
    this.callback = callback;

    final fen = Fen.positionToFen(position);

    final response = await ChessDB.query(fen, banMoves: banMoves);
    if (response == null) {
      callback(EngineResponse(EngineType.cloudLibrary, Error('Network Error')));
      return false;
    }

    if (response.startsWith('move')) {
      //
      final move = _randomMove(response);

      if (move != null) {
        callback(
          EngineResponse(EngineType.cloudLibrary, Bestmove(move['move'])),
        );
        return true;
      }
    }

    return false;
  }

  Future<EngineResponse> analysis(Position position) async {
    //
    final fen = Fen.positionToFen(position);
    var response = await ChessDB.query(fen);

    if (response == null) {
      return EngineResponse(EngineType.cloudLibrary, Error('Network error'));
    }

    if (response.startsWith('move')) {
      //
      final items = AnalysisFetcher.fetch(response);

      if (items.isEmpty) {
        return EngineResponse(EngineType.cloudLibrary, Error('no-result'));
      }

      return EngineResponse(EngineType.cloudLibrary, Analysis(items));
    }

    prt('ChessDB.query: $response\n');
    return EngineResponse(EngineType.cloudLibrary, Error('Unknown error'));
  }

  Map<String, dynamic>? _randomMove(String response) {
    ///
    /// move:b2a2,score:-236,rank:0,note:? (00-00),winrate:32.85
    ///
    final moves = <Map<String, dynamic>>[];

    final segments = response.split('|');
    var minScore = -0xFFFF;

    for (var i = 0; i < segments.length; i++) {
      //
      final kvps = _fetchResponseTokens(segments[i]);

      final score = int.tryParse(kvps['score']!) ?? minScore;
      if (score <= minScore) break;

      minScore = score;
      moves.add(kvps);
    }

    if (moves.isNotEmpty) {
      return moves[Random().nextInt(moves.length)];
    }

    return null;
  }

  Map<String, String> _fetchResponseTokens(String move) {
    //
    final kvps = <String, String>{};

    move.split(',').forEach((token) {
      //
      final kv = token.split(':');

      if (kv.length == 2) {
        //
        final key = kv[0];
        String value = kv[1];

        if (key == 'score') {
          final pos = value.indexOf(' (');
          if (pos > -1) value = value.substring(0, pos);
        }

        kvps[key] = value;
      }
    });

    return kvps;
  }
}
