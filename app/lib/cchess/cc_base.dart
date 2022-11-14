class PieceColor {
  //
  static const unknown = '-';
  static const red = 'w';
  static const black = 'b';

  static String of(String piece) {
    if ('RNBAKCP'.contains(piece)) return red;
    if ('rnbakcp'.contains(piece)) return black;
    return unknown;
  }

  static bool sameColor(String p1, String p2) {
    return of(p1) == of(p2);
  }

  static String opponent(String color) {
    if (color == red) return black;
    if (color == black) return red;
    return color;
  }
}

class Piece {
  //
  static const noPiece = ' ';
  //
  static const redRook = 'R';
  static const redKnight = 'N';
  static const redBishop = 'B';
  static const redAdvisor = 'A';
  static const redKing = 'K';
  static const redCanon = 'C';
  static const redPawn = 'P';
  //
  static const blackRook = 'r';
  static const blackKnight = 'n';
  static const blackBishop = 'b';
  static const blackAdvisor = 'a';
  static const blackKing = 'k';
  static const blackCanon = 'c';
  static const blackPawn = 'p';

  static const zhName = {
    noPiece: '',
    //
    redRook: '车',
    redKnight: '马',
    redBishop: '相',
    redAdvisor: '仕',
    redKing: '帅',
    redCanon: '炮',
    redPawn: '兵',
    //
    blackRook: '车',
    blackKnight: '马',
    blackBishop: '象',
    blackAdvisor: '士',
    blackKing: '将',
    blackCanon: '炮',
    blackPawn: '卒',
  };

  static bool isRed(String c) => 'RNBAKCP'.contains(c);

  static bool isBlack(String c) => 'rnbakcp'.contains(c);
}

class Move {
  //
  static const invalidIndex = -1;

  late int from, to, fx, fy, tx, ty;

  String captured = Piece.noPiece;

  // 'move' is the ucci engine's move-string
  late String move;
  String? name;

  // 这一步走完后的 FEN 记数，用于悔棋时恢复 FEN 步数 Counter
  String counterMarks = '';

  Move(
    this.from,
    this.to, {
    this.captured = Piece.noPiece,
    this.counterMarks = '',
  }) {
    //
    fx = from % 9;
    fy = from ~/ 9;

    tx = to % 9;
    ty = to ~/ 9;

    if (fx < 0 || fx > 8 || fy < 0 || fy > 9) {
      throw 'Error: Invalid Move (from:$from, to:$to)';
    }

    move = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    move += String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
  }

  Move.fromCoordinate(this.fx, this.fy, this.tx, this.ty) {
    //
    from = fx + fy * 9;
    to = tx + ty * 9;
    captured = Piece.noPiece;

    move = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    move += String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
  }

  Move.fromEngineMove(this.move) {
    //
    if (!isOK(move)) {
      throw 'Error: Invalid Move: $move';
    }

    fx = move[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    fy = 9 - (move[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    tx = move[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    ty = 9 - (move[3].codeUnitAt(0) - '0'.codeUnitAt(0));

    from = fx + fy * 9;
    to = tx + ty * 9;

    captured = Piece.noPiece;
  }

  String asEngineMove() {
    return '${String.fromCharCode('a'.codeUnitAt(0) + fx)}${9 - fy}'
        '${String.fromCharCode('a'.codeUnitAt(0) + tx)}${9 - ty}';
  }

  static bool isOK(String move) {
    //
    if (move.length < 4) return false;

    final fx = move[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fy = 9 - (move[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    if (fx < 0 || fx > 8 || fy < 0 || fy > 9) return false;

    final tx = move[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final ty = 9 - (move[3].codeUnitAt(0) - '0'.codeUnitAt(0));
    if (tx < 0 || tx > 8 || ty < 0 || ty > 9) return false;

    return true;
  }
}

enum GameResult { pending, win, lose, draw }
