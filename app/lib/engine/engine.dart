import 'package:chessroad/cchess/move_name.dart';
import 'package:chessroad/game/board_state.dart';
import 'package:chessroad/routes/battle/battle_page.dart';

import '../cchess/cc_base.dart';
import '../cchess/position.dart';
import '../common/prt.dart';
import 'analysis.dart';
import 'pikafish_engine.dart';

enum EngineType { cloudLibrary, pikafish }

abstract class Response {
  // empty
}

class NoBestmove extends Response {
  // empty
}

class Error extends Response {
  final String message;
  Error(this.message);
}

class Bestmove extends Response {
  //
  late String bestmove;
  String? ponder;

  Bestmove(this.bestmove, {this.ponder});

  Bestmove.parse(String line) : super() {
    //
    var regx = RegExp(r'bestmove (\w+)');
    var match = regx.firstMatch(line);

    if (match != null) {
      //
      bestmove = match.group(1)!;

      regx = RegExp(r'ponder (\w+)');
      match = regx.firstMatch(line);

      if (match != null) {
        ponder = match.group(1);
      }
    }
  }
}

class EngineInfo extends Response {
  //
  final tokens = <String, int>{};
  final pvs = <String>[];

  EngineInfo.parse(String line) {
    //
    // info depth 10 seldepth 13 multipv 1 score cp -75 nodes 14091
    // nps 6358 hashfull 4 tbhits 0 time 2216 pv h9g7 h0g2 i9h9 i0h0
    // b9c7 h0h4 c9e7 c3c4 h7i7 h4h9 g7h9 g3g4

    // info depth 13 seldepth 16 multipv 1 score cp -30 upperbound
    // nodes 69433 nps 21691 hashfull 31 tbhits 0 time 3201 pv h9g7 h0g2

    // info depth 14 seldepth 19 multipv 1 score cp -18 lowerbound
    // nodes 97595 nps 22915 hashfull 45 tbhits 0 time 4259 pv b9c7

    final regx = RegExp(
      r'info depth (\d+) seldepth (\d+) multipv (\d+) score cp (-?\d+) [upperbound lowerbound]*'
      r'nodes (\d+) nps (\d+) hashfull (\d+) tbhits (\d+) time (\d+) pv (.*)',
    );
    final match = regx.firstMatch(line);

    if (match != null) {
      //
      tokens['depth'] = int.parse(match.group(1)!);
      tokens['seldepth'] = int.parse(match.group(2)!);
      tokens['multipv'] = int.parse(match.group(3)!);
      tokens['score'] = int.parse(match.group(4)!);
      tokens['nodes'] = int.parse(match.group(5)!);
      tokens['nps'] = int.parse(match.group(6)!);
      tokens['hashfull'] = int.parse(match.group(7)!);
      tokens['tbhits'] = int.parse(match.group(8)!);
      tokens['time'] = int.parse(match.group(9)!);

      final pv = match.group(10)!;
      pvs.addAll(pv.split(' '));
    } else {
      prt('*** Not match: $line');
    }
  }

  String followingMoves(BoardState boardState) {
    //
    final position = boardState.position;

    final bestmove = boardState.bestmove?.bestmove;

    final tempPosition = Position.clone(position);

    var names = <String>[];

    if (PikafishEngine().state == EngineState.searching) {
      //
      for (var i = 0; i < pvs.length; i++) {
        //
        var move = Move.fromEngineMove(pvs[i]);
        final name = MoveName.translate(tempPosition, move);
        tempPosition.move(move);

        names.add(name);
      }
    } else if (PikafishEngine().state == EngineState.ready) {
      //
      for (var i = 0; i < pvs.length; i++) {
        //
        if (pvs[i] == bestmove) continue;

        var move = Move.fromEngineMove(pvs[i]);
        final name = MoveName.translate(tempPosition, move);
        tempPosition.move(move);

        names.add(name);
      }
    }

    var result = '';

    if (names.length < 4) {
      result = names.join(' ');
    } else if (names.length < 8) {
      result = '${names.sublist(0, 4).join(' ')}\n';
      result += names.sublist(4).join(' ');
    } else {
      result = '${names.sublist(0, 4).join(' ')}\n';
      result += names.sublist(4, 8).join(' ');
    }

    return result;
  }

  String? score(BoardState boardState, bool negative) {
    //
    final position = boardState.position;
    final playerSide = boardState.playerSide;

    var score = tokens['score'];
    if (score == null) return null;

    final base = (position.sideToMove == playerSide) ? 1 : -1;
    score = score * base * (negative ? -1 : 1);

    final judge = score == 0
        ? '均势'
        : score > 0
            ? '优势'
            : '劣势';

    return '局面 $score ($judge)';
  }

  String? info(BoardState boardState) {
    //
    var score = tokens['score'];
    if (score == null) return null;

    var result = ''
        '深度 ${tokens['depth']}，'
        '节点 ${tokens['nodes']}，'
        '时间 ${tokens['time']}\n';

    result += followingMoves(boardState);

    return result;
  }
}

class Analysis extends Response {
  final List<AnalysisItem> items;
  Analysis(this.items);
}

class EngineResponse {
  final EngineType type;
  final Response response;
  EngineResponse(this.type, this.response);
}

typedef EngineCallback = Function(EngineResponse);
