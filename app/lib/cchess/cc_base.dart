class Side {
  //
  static const unknown = '-';
  static const red = 'w';
  static const black = 'b';

  static String of(String piece) {
    if ('RNBAKCP'.contains(piece)) return red;
    if ('rnbakcp'.contains(piece)) return black;
    return unknown;
  }

  static bool sameSide(String p1, String p2) {
    return of(p1) == of(p2);
  }

  static String opponent(String side) {
    if (side == red) return black;
    if (side == black) return red;
    return side;
  }
}

class Piece {
  //
  static const empty = ' ';
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

  static const names = {
    empty: '',
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

  String captured = Piece.empty;

  // 'step' is the ucci engine's move-string
  late String step;
  String? stepName;

  // 这一步走完后的 FEN 记数，用于悔棋时恢复 FEN 步数 Counter
  String counterMarks = '';

  Move(
    this.from,
    this.to, {
    this.captured = Piece.empty,
    this.counterMarks = '',
  }) {
    //
    fx = from % 9;
    fy = from ~/ 9;

    tx = to % 9;
    ty = to ~/ 9;

    if (fx < 0 || fx > 8 || fy < 0 || fy > 9) {
      throw 'Error: Invalid Step (from:$from, to:$to)';
    }

    step = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    step += String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
  }

  Move.fromCoordinate(this.fx, this.fy, this.tx, this.ty) {
    //
    from = fx + fy * 9;
    to = tx + ty * 9;
    captured = Piece.empty;

    step = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    step += String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
  }

  Move.fromEngineStep(this.step) {
    //
    if (!validateEngineStep(step)) {
      throw 'Error: Invalid Step: $step';
    }

    fx = step[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    fy = 9 - (step[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    tx = step[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    ty = 9 - (step[3].codeUnitAt(0) - '0'.codeUnitAt(0));

    from = fx + fy * 9;
    to = tx + ty * 9;

    captured = Piece.empty;
  }

  String asEngineStep() {
    return '${String.fromCharCode('a'.codeUnitAt(0) + fx)}${9 - fy}'
        '${String.fromCharCode('a'.codeUnitAt(0) + tx)}${9 - ty}';
  }

  static bool validateEngineStep(String step) {
    //
    if (step.length < 4) return false;

    final fx = step[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fy = 9 - (step[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    if (fx < 0 || fx > 8 || fy < 0 || fy > 9) return false;

    final tx = step[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final ty = 9 - (step[3].codeUnitAt(0) - '0'.codeUnitAt(0));
    if (tx < 0 || tx > 8 || ty < 0 || ty > 9) return false;

    return true;
  }
}

enum BattleResult { pending, win, lose, draw }
