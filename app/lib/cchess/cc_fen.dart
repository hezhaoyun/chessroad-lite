import 'phase.dart';
import 'cc_base.dart';
import 'move_recorder.dart';

class Fen {
  //
  static const fenChars = 'RNBAKCPrnbakcp';
  static const defaultLayout =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR';
  static const defaultPhase =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';

  static String phaseToFen(Phase phase) {
    //
    var fen = '';

    for (var row = 0; row < 10; row++) {
      //
      var emptyCounter = 0;

      for (var column = 0; column < 9; column++) {
        //
        final piece = phase.pieceAt(row * 9 + column);

        if (piece == Piece.empty) {
          //
          emptyCounter++;
          //
        } else {
          //
          if (emptyCounter > 0) {
            fen += emptyCounter.toString();
            emptyCounter = 0;
          }

          fen += piece;
        }
      }

      if (emptyCounter > 0) fen += emptyCounter.toString();

      if (row < 9) fen += '/';
    }

    fen += ' ${phase.side}';

    // 王车易位和吃过路兵标志
    fen += ' - - ';

    // step counter
    fen += phase.stepCount; // ?? '0 1';

    return fen;
  }

  static String toFen(
    List<String> pieces, {
    String side = Side.red,
    String? stepCounter,
  }) {
    //
    var fen = '';

    for (var row = 0; row < 10; row++) {
      //
      var emptyCounter = 0;

      for (var column = 0; column < 9; column++) {
        //
        final piece = pieces[row * 9 + column];

        if (piece == Piece.empty) {
          //
          emptyCounter++;
          //
        } else {
          //
          if (emptyCounter > 0) {
            fen += emptyCounter.toString();
            emptyCounter = 0;
          }

          fen += piece;
        }
      }

      if (emptyCounter > 0) fen += emptyCounter.toString();

      if (row < 9) fen += '/';
    }

    fen += ' $side';

    // 王车易位和吃过路兵标志
    fen += ' - - ';

    // step counter
    fen += stepCounter ?? '0 1';

    return fen;
  }

  static String layoutOfFen(String fen) {
    final pos = fen.indexOf(' - - ');
    return (pos < 0) ? fen : fen.substring(0, pos);
  }

  static Phase? phaseFromFen(String fen) {
    //
    final pos = fen.indexOf(' ');
    final fullFen = pos > 0 && (fen.length - pos) >= ' w - - 0 1'.length;

    final layout = fen.substring(0, fullFen ? pos : fen.length);
    final pieces = loadPieces(layout);
    if (pieces == null) return null;

    final String side; // side: w/b
    final String counterMark; // 无吃子步数和回合数

    if (fullFen) {
      side = fen.substring(pos + 1, pos + 2);
      final flagPos = fen.indexOf(' - - ', pos + 2); // ' - - '，王车易位标志和吃过路兵标志
      counterMark = flagPos > 0 ? fen.substring(flagPos + 5) : '0 1';
    } else {
      side = Side.red;
      counterMark = '0 1';
    }

    try {
      final recorder = MoveRecorder.fromCounterMarks(counterMark);
      return Phase(pieces, side, recorder);
    } catch (e) {
      return null;
    }
  }

  static List<String>? loadPieces(String layout) {
    //
    if (layout.length < 23) return null;

    final endPos = layout.indexOf(' ');
    if (endPos > -1) layout = layout.substring(0, endPos);

    final rows = layout.split('/');
    if (rows.length != 10) return null;

    final pieces = List<String>.filled(90, '');

    for (var row = 0; row < 10; row++) {
      //
      final chars = rows[row];

      var col = 0, length = chars.length;

      for (var i = 0; i < length; i++) {
        //
        final c = chars[i];
        final code = c.codeUnitAt(0);

        if (code > '0'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)) {
          //
          final count = code - '0'.codeUnitAt(0);

          for (var j = 0; j < count; j++) {
            pieces[row * 9 + col + j] = Piece.empty;
          }

          col += count;
        } else if (isFenChar(c)) {
          pieces[row * 9 + col] = c;
          col++;
        } else {
          return null;
        }
      }

      if (col != 9) return null;
    }

    return pieces;
  }

  static String crManualBoardToFen(String initBoard) {
    //
    if (initBoard == '' || initBoard.length != 64) {
      return Fen.defaultPhase;
    }

    final board = List<String>.filled(90, '');
    for (var i = 0; i < board.length; i++) {
      board[i] = Piece.empty;
    }

    const pieces = 'RNBAKABNRCCPPPPPrnbakabnrccppppp';

    for (var i = 0; i < 32; i++) {
      //
      final piece = pieces[i];
      final pos = int.parse(initBoard.substring(i * 2, (i + 1) * 2));
      if (pos == 99) continue; // 不在棋盘上了

      final col = pos ~/ 10, row = pos % 10;
      board[row * 9 + col] = piece;
    }

    return Fen.toFen(board);
  }

  static String phaseToCrManualBoard(Phase origin) {
    //
    const pieces = 'RNBAKABNRCCPPPPPrnbakabnrccppppp';

    final piecesOnBoard = <String>[];

    for (var i = 0; i < 90; i++) {
      piecesOnBoard.add(origin.pieceAt(i));
    }

    var board = '';

    for (var i = 0; i < pieces.length; i++) {
      //
      final index = piecesOnBoard.indexOf(pieces[i]);

      if (index > -1) {
        final row = index ~/ 9, col = index % 9;
        board += '$col$row';
        piecesOnBoard[index] = Piece.empty;
      } else {
        board += '99';
      }
    }

    return board;
  }

  static bool isFenChar(String c) {
    return fenChars.contains(c);
  }
}
