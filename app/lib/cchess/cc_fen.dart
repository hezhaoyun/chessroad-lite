import 'position.dart';
import 'cc_base.dart';
import 'move_recorder.dart';

class Fen {
  //
  static const fenChars = 'RNBAKCPrnbakcp';
  static const defaultLayout =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR';
  static const defaultPosition =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';

  static String positionToFen(Position position) {
    //
    var fen = '';

    for (var rank = 0; rank < 10; rank++) {
      //
      var emptyCounter = 0;

      for (var file = 0; file < 9; file++) {
        //
        final piece = position.pieceAt(rank * 9 + file);

        if (piece == Piece.noPiece) {
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

      if (rank < 9) fen += '/';
    }

    fen += ' ${position.sideToMove}';

    // 王车易位和吃过路兵标志
    fen += ' - - ';

    // move counter
    fen += position.moveCount; // ?? '0 1';

    return fen;
  }

  static String toFen(
    List<String> pieces, {
    String sideToMove = PieceColor.red,
    String? moveCounter,
  }) {
    //
    var fen = '';

    for (var rank = 0; rank < 10; rank++) {
      //
      var emptyCounter = 0;

      for (var file = 0; file < 9; file++) {
        //
        final piece = pieces[rank * 9 + file];

        if (piece == Piece.noPiece) {
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

      if (rank < 9) fen += '/';
    }

    fen += ' $sideToMove';

    // 王车易位和吃过路兵标志
    fen += ' - - ';

    // move counter
    fen += moveCounter ?? '0 1';

    return fen;
  }

  static String layoutOfFen(String fen) {
    final pos = fen.indexOf(' - - ');
    return (pos < 0) ? fen : fen.substring(0, pos);
  }

  static Position? positionFromFen(String fen) {
    //
    final pos = fen.indexOf(' ');
    final fullFen = pos > 0 && (fen.length - pos) >= ' w - - 0 1'.length;

    final layout = fen.substring(0, fullFen ? pos : fen.length);
    final pieces = loadPieces(layout);
    if (pieces == null) return null;

    final String sideToMove; // sideToMove: w/b
    final String counterMark; // 无吃子步数和回合数

    if (fullFen) {
      sideToMove = fen.substring(pos + 1, pos + 2);
      final flagPos = fen.indexOf(' - - ', pos + 2); // ' - - '，王车易位标志和吃过路兵标志
      counterMark = flagPos > 0 ? fen.substring(flagPos + 5) : '0 1';
    } else {
      sideToMove = PieceColor.red;
      counterMark = '0 1';
    }

    try {
      final recorder = MoveRecorder.fromCounterMarks(counterMark);
      return Position(pieces, sideToMove, recorder);
    } catch (e) {
      return null;
    }
  }

  static List<String>? loadPieces(String layout) {
    //
    if (layout.length < 23) return null;

    final endPos = layout.indexOf(' ');
    if (endPos > -1) layout = layout.substring(0, endPos);

    final ranks = layout.split('/');
    if (ranks.length != 10) return null;

    final pieces = List<String>.filled(90, '');

    for (var rank = 0; rank < 10; rank++) {
      //
      final chars = ranks[rank];

      var file = 0, length = chars.length;

      for (var i = 0; i < length; i++) {
        //
        final c = chars[i];
        final code = c.codeUnitAt(0);

        if (code > '0'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)) {
          //
          final count = code - '0'.codeUnitAt(0);

          for (var j = 0; j < count; j++) {
            pieces[rank * 9 + file + j] = Piece.noPiece;
          }

          file += count;
        } else if (isFenChar(c)) {
          pieces[rank * 9 + file] = c;
          file++;
        } else {
          return null;
        }
      }

      if (file != 9) return null;
    }

    return pieces;
  }

  static String crManualBoardToFen(String initBoard) {
    //
    if (initBoard == '' || initBoard.length != 64) {
      return Fen.defaultPosition;
    }

    final board = List<String>.filled(90, '');
    for (var i = 0; i < board.length; i++) {
      board[i] = Piece.noPiece;
    }

    const pieces = 'RNBAKABNRCCPPPPPrnbakabnrccppppp';

    for (var i = 0; i < 32; i++) {
      //
      final piece = pieces[i];
      final pos = int.parse(initBoard.substring(i * 2, (i + 1) * 2));
      if (pos == 99) continue; // 不在棋盘上了

      final file = pos ~/ 10, rank = pos % 10;
      board[rank * 9 + file] = piece;
    }

    return Fen.toFen(board);
  }

  static String positionToCrManualBoard(Position origin) {
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
        final rank = index ~/ 9, file = index % 9;
        board += '$file$rank';
        piecesOnBoard[index] = Piece.noPiece;
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
