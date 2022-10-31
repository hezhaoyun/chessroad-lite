import 'phase.dart';
import 'cc_base.dart';

class ChessRules {
  //
  static bool beChecked(Phase phase) {
    //
    final myKingPos = findKingPos(phase);

    final opponentPhase = Phase.clone(phase);
    opponentPhase.turnSide();

    final opponentSteps = enumSteps(opponentPhase);

    for (var step in opponentSteps) {
      if (step.to == myKingPos) return true;
    }

    return false;
  }

  static bool willBeChecked(Phase phase, Move move) {
    //
    final tempPhase = Phase.clone(phase);
    tempPhase.moveTest(move);

    return beChecked(tempPhase);
  }

  static bool willKingsMeeting(Phase phase, Move move) {
    //
    final tempPhase = Phase.clone(phase);
    tempPhase.moveTest(move);

    for (var col = 3; col < 6; col++) {
      //
      var foundKingAlready = false;

      for (var row = 0; row < 10; row++) {
        //
        final piece = tempPhase.pieceAt(row * 9 + col);

        if (!foundKingAlready) {
          if (piece == Piece.redKing || piece == Piece.blackKing) {
            foundKingAlready = true;
          }
          if (row > 2) break;
        } else {
          if (piece == Piece.redKing || piece == Piece.blackKing) return true;
          if (piece != Piece.empty) break;
        }
      }
    }

    return false;
  }

  static bool beKilled(Phase phase) {
    //
    final steps = ChessRules.enumSteps(phase);

    for (var step in steps) {
      if (ChessRules.validate(phase, step)) return false;
    }

    return true;
  }

  static List<Move> enumSteps(Phase phase) {
    //
    final steps = <Move>[];

    for (var row = 0; row < 10; row++) {
      //
      for (var col = 0; col < 9; col++) {
        //
        final from = row * 9 + col;
        final piece = phase.pieceAt(from);

        if (Side.of(piece) != phase.side) continue;

        List<Move> pieceSteps;

        if (piece == Piece.redKing || piece == Piece.blackKing) {
          pieceSteps = enumKingSteps(phase, row, col, from);
        } else if (piece == Piece.redAdvisor || piece == Piece.blackAdvisor) {
          pieceSteps = enumAdvisorSteps(phase, row, col, from);
        } else if (piece == Piece.redBishop || piece == Piece.blackBishop) {
          pieceSteps = enumBishopSteps(phase, row, col, from);
        } else if (piece == Piece.redKnight || piece == Piece.blackKnight) {
          pieceSteps = enumKnightSteps(phase, row, col, from);
        } else if (piece == Piece.redRook || piece == Piece.blackRook) {
          pieceSteps = enumRookSteps(phase, row, col, from);
        } else if (piece == Piece.redCanon || piece == Piece.blackCanon) {
          pieceSteps = enumCanonSteps(phase, row, col, from);
        } else if (piece == Piece.redPawn || piece == Piece.blackPawn) {
          pieceSteps = enumPawnSteps(phase, row, col, from);
        } else {
          continue;
        }

        steps.addAll(pieceSteps);
      }
    }

    return steps;
  }

  static bool validate(Phase phase, Move move) {
    //
    if (Side.of(phase.pieceAt(move.to)) == phase.side) return false;

    final piece = phase.pieceAt(move.from);

    var valid = false;

    if (piece == Piece.redKing || piece == Piece.blackKing) {
      valid = validateKingStep(phase, move);
    } else if (piece == Piece.redAdvisor || piece == Piece.blackAdvisor) {
      valid = validateAdvisorStep(phase, move);
    } else if (piece == Piece.redBishop || piece == Piece.blackBishop) {
      valid = validateBishopStep(phase, move);
    } else if (piece == Piece.redKnight || piece == Piece.blackKnight) {
      valid = validateKnightStep(phase, move);
    } else if (piece == Piece.redRook || piece == Piece.blackRook) {
      valid = validateRookStep(phase, move);
    } else if (piece == Piece.redCanon || piece == Piece.blackCanon) {
      valid = validateCanonStep(phase, move);
    } else if (piece == Piece.redPawn || piece == Piece.blackPawn) {
      valid = validatePawnStep(phase, move);
    }

    if (!valid) return false;

    if (willBeChecked(phase, move)) return false;

    if (willKingsMeeting(phase, move)) return false;

    return true;
  }

  static List<Move> enumKingSteps(Phase phase, int row, int col, int from) {
    //
    final offsetList = [
      [-1, 0],
      [0, -1],
      [1, 0],
      [0, 1]
    ];

    final redRange = [66, 67, 68, 75, 76, 77, 84, 85, 86];
    final blackRange = [3, 4, 5, 12, 13, 14, 21, 22, 23];
    final range = (phase.side == Side.red ? redRange : blackRange);

    final steps = <Move>[];

    for (var i = 0; i < 4; i++) {
      //
      final offset = offsetList[i];
      final to = (row + offset[0]) * 9 + col + offset[1];

      if (!posOnBoard(to) || Side.of(phase.pieceAt(to)) == phase.side) {
        continue;
      }

      if (binarySearch(range, 0, range.length - 1, to) > -1) {
        steps.add(Move(from, to));
      }
    }

    return steps;
  }

  static List<Move> enumAdvisorSteps(Phase phase, int row, int col, int from) {
    //
    final offsetList = [
      [-1, -1],
      [1, -1],
      [-1, 1],
      [1, 1]
    ];

    final redRange = [66, 68, 76, 84, 86];
    final blackRange = [3, 5, 13, 21, 23];
    final range = phase.side == Side.red ? redRange : blackRange;

    final steps = <Move>[];

    for (var i = 0; i < 4; i++) {
      //
      final offset = offsetList[i];
      final to = (row + offset[0]) * 9 + col + offset[1];

      if (!posOnBoard(to) || Side.of(phase.pieceAt(to)) == phase.side) {
        continue;
      }

      if (binarySearch(range, 0, range.length - 1, to) > -1) {
        steps.add(Move(from, to));
      }
    }

    return steps;
  }

  static List<Move> enumBishopSteps(Phase phase, int row, int col, int from) {
    //
    final heartOffsetList = [
      [-1, -1],
      [1, -1],
      [-1, 1],
      [1, 1]
    ];

    final offsetList = [
      [-2, -2],
      [2, -2],
      [-2, 2],
      [2, 2]
    ];

    final redRange = [47, 51, 63, 67, 71, 83, 87];
    final blackRange = [2, 6, 18, 22, 26, 38, 42];
    final range = phase.side == Side.red ? redRange : blackRange;

    final steps = <Move>[];

    for (var i = 0; i < 4; i++) {
      //
      final heartOffset = heartOffsetList[i];
      final heart = (row + heartOffset[0]) * 9 + (col + heartOffset[1]);

      if (!posOnBoard(heart) || phase.pieceAt(heart) != Piece.empty) {
        continue;
      }

      final offset = offsetList[i];
      final to = (row + offset[0]) * 9 + (col + offset[1]);

      if (!posOnBoard(to) || Side.of(phase.pieceAt(to)) == phase.side) {
        continue;
      }

      if (binarySearch(range, 0, range.length - 1, to) > -1) {
        steps.add(Move(from, to));
      }
    }

    return steps;
  }

  static List<Move> enumKnightSteps(Phase phase, int row, int col, int from) {
    //
    final offsetList = [
      [-2, -1],
      [-1, -2],
      [1, -2],
      [2, -1],
      [2, 1],
      [1, 2],
      [-1, 2],
      [-2, 1]
    ];
    final footOffsetList = [
      [-1, 0],
      [0, -1],
      [0, -1],
      [1, 0],
      [1, 0],
      [0, 1],
      [0, 1],
      [-1, 0]
    ];

    final steps = <Move>[];

    for (var i = 0; i < 8; i++) {
      //
      final offset = offsetList[i];
      final nr = row + offset[0], nc = col + offset[1];

      if (nr < 0 || nr > 9 || nc < 0 || nc > 9) continue;

      final to = nr * 9 + nc;
      if (!posOnBoard(to) || Side.of(phase.pieceAt(to)) == phase.side) {
        continue;
      }

      final footOffset = footOffsetList[i];
      final fr = row + footOffset[0], fc = col + footOffset[1];
      final foot = fr * 9 + fc;

      if (!posOnBoard(foot) || phase.pieceAt(foot) != Piece.empty) {
        continue;
      }

      steps.add(Move(from, to));
    }

    return steps;
  }

  static List<Move> enumRookSteps(Phase phase, int row, int col, int from) {
    //
    final steps = <Move>[];

    // to left
    for (var c = col - 1; c >= 0; c--) {
      final to = row * 9 + c;
      final target = phase.pieceAt(to);

      if (target == Piece.empty) {
        steps.add(Move(from, to));
      } else {
        if (Side.of(target) != phase.side) {
          steps.add(Move(from, to));
        }
        break;
      }
    }

    // to top
    for (var r = row - 1; r >= 0; r--) {
      final to = r * 9 + col;
      final target = phase.pieceAt(to);

      if (target == Piece.empty) {
        steps.add(Move(from, to));
      } else {
        if (Side.of(target) != phase.side) {
          steps.add(Move(from, to));
        }
        break;
      }
    }

    // to right
    for (var c = col + 1; c < 9; c++) {
      final to = row * 9 + c;
      final target = phase.pieceAt(to);

      if (target == Piece.empty) {
        steps.add(Move(from, to));
      } else {
        if (Side.of(target) != phase.side) {
          steps.add(Move(from, to));
        }
        break;
      }
    }

    // to down
    for (var r = row + 1; r < 10; r++) {
      final to = r * 9 + col;
      final target = phase.pieceAt(to);

      if (target == Piece.empty) {
        steps.add(Move(from, to));
      } else {
        if (Side.of(target) != phase.side) {
          steps.add(Move(from, to));
        }
        break;
      }
    }

    return steps;
  }

  static List<Move> enumCanonSteps(Phase phase, int row, int col, int from) {
    //
    final steps = <Move>[];
    // to left
    var overPiece = false;

    for (var c = col - 1; c >= 0; c--) {
      final to = row * 9 + c;
      final target = phase.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.empty) {
          steps.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.empty) {
          if (Side.of(target) != phase.side) {
            steps.add(Move(from, to));
          }
          break;
        }
      }
    }

    // to top
    overPiece = false;

    for (var r = row - 1; r >= 0; r--) {
      final to = r * 9 + col;
      final target = phase.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.empty) {
          steps.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.empty) {
          if (Side.of(target) != phase.side) {
            steps.add(Move(from, to));
          }
          break;
        }
      }
    }

    // to right
    overPiece = false;

    for (var c = col + 1; c < 9; c++) {
      final to = row * 9 + c;
      final target = phase.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.empty) {
          steps.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.empty) {
          if (Side.of(target) != phase.side) {
            steps.add(Move(from, to));
          }
          break;
        }
      }
    }

    // to bottom
    overPiece = false;

    for (var r = row + 1; r < 10; r++) {
      final to = r * 9 + col;
      final target = phase.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.empty) {
          steps.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.empty) {
          if (Side.of(target) != phase.side) {
            steps.add(Move(from, to));
          }
          break;
        }
      }
    }

    return steps;
  }

  static List<Move> enumPawnSteps(Phase phase, int row, int col, int from) {
    //
    var to = (row + (phase.side == Side.red ? -1 : 1)) * 9 + col;

    final steps = <Move>[];

    if (posOnBoard(to) && Side.of(phase.pieceAt(to)) != phase.side) {
      steps.add(Move(from, to));
    }

    if ((phase.side == Side.red && row < 5) ||
        (phase.side == Side.black && row > 4)) {
      //
      if (col > 0) {
        to = row * 9 + col - 1;
        if (posOnBoard(to) && Side.of(phase.pieceAt(to)) != phase.side) {
          steps.add(Move(from, to));
        }
      }

      if (col < 8) {
        to = row * 9 + col + 1;
        if (posOnBoard(to) && Side.of(phase.pieceAt(to)) != phase.side) {
          steps.add(Move(from, to));
        }
      }
    }

    return steps;
  }

  static bool validateKingStep(Phase phase, Move move) {
    //
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    final isUpDownMove = (adx == 0 && ady == 1);
    final isLeftRightMove = (adx == 1 && ady == 0);

    if (!isUpDownMove && !isLeftRightMove) return false;

    final redRange = [66, 67, 68, 75, 76, 77, 84, 85, 86];
    final blackRange = [3, 4, 5, 12, 13, 14, 21, 22, 23];
    final range = (phase.side == Side.red) ? redRange : blackRange;

    return binarySearch(range, 0, range.length - 1, move.to) >= 0;
  }

  static bool validateAdvisorStep(Phase phase, Move move) {
    //
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    if (adx != 1 || ady != 1) return false;

    final redRange = [66, 68, 76, 84, 86], blackRange = [3, 5, 13, 21, 23];
    final range = (phase.side == Side.red) ? redRange : blackRange;

    return binarySearch(range, 0, range.length - 1, move.to) >= 0;
  }

  static bool validateBishopStep(Phase phase, Move move) {
    //
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    if (adx != 2 || ady != 2) return false;

    final redRange = [47, 51, 63, 67, 71, 83, 87],
        blackRange = [2, 6, 18, 22, 26, 38, 42];
    final range = (phase.side == Side.red) ? redRange : blackRange;

    if (binarySearch(range, 0, range.length - 1, move.to) < 0) return false;

    if (move.tx > move.fx) {
      if (move.ty > move.fy) {
        final heart = (move.fy + 1) * 9 + move.fx + 1;
        if (phase.pieceAt(heart) != Piece.empty) return false;
      } else {
        final heart = (move.fy - 1) * 9 + move.fx + 1;
        if (phase.pieceAt(heart) != Piece.empty) return false;
      }
    } else {
      if (move.ty > move.fy) {
        final heart = (move.fy + 1) * 9 + move.fx - 1;
        if (phase.pieceAt(heart) != Piece.empty) return false;
      } else {
        final heart = (move.fy - 1) * 9 + move.fx - 1;
        if (phase.pieceAt(heart) != Piece.empty) return false;
      }
    }

    return true;
  }

  static bool validateKnightStep(Phase phase, Move move) {
    //
    final dx = move.tx - move.fx, dy = move.ty - move.fy;
    final adx = abs(dx), ady = abs(dy);

    if (!(adx == 1 && ady == 2) && !(adx == 2 && ady == 1)) return false;

    if (adx > ady) {
      if (dx > 0) {
        final foot = move.fy * 9 + move.fx + 1;
        if (phase.pieceAt(foot) != Piece.empty) return false;
      } else {
        final foot = move.fy * 9 + move.fx - 1;
        if (phase.pieceAt(foot) != Piece.empty) return false;
      }
    } else {
      if (dy > 0) {
        final foot = (move.fy + 1) * 9 + move.fx;
        if (phase.pieceAt(foot) != Piece.empty) return false;
      } else {
        final foot = (move.fy - 1) * 9 + move.fx;
        if (phase.pieceAt(foot) != Piece.empty) return false;
      }
    }

    return true;
  }

  static bool validateRookStep(Phase phase, Move move) {
    //
    final dx = move.tx - move.fx, dy = move.ty - move.fy;

    if (dx != 0 && dy != 0) return false;

    if (dy == 0) {
      if (dx < 0) {
        for (var i = move.fx - 1; i > move.tx; i--) {
          if (phase.pieceAt(move.fy * 9 + i) != Piece.empty) return false;
        }
      } else {
        for (var i = move.fx + 1; i < move.tx; i++) {
          if (phase.pieceAt(move.fy * 9 + i) != Piece.empty) return false;
        }
      }
    } else {
      if (dy < 0) {
        for (var i = move.fy - 1; i > move.ty; i--) {
          if (phase.pieceAt(i * 9 + move.fx) != Piece.empty) return false;
        }
      } else {
        for (var i = move.fy + 1; i < move.ty; i++) {
          if (phase.pieceAt(i * 9 + move.fx) != Piece.empty) return false;
        }
      }
    }

    return true;
  }

  static bool validateCanonStep(Phase phase, Move move) {
    //
    final dx = move.tx - move.fx, dy = move.ty - move.fy;

    if (dx != 0 && dy != 0) return false;

    if (dy == 0) {
      //
      if (dx < 0) {
        //
        var overPiece = false;

        for (var i = move.fx - 1; i > move.tx; i--) {
          //
          if (phase.pieceAt(move.fy * 9 + i) != Piece.empty) {
            //
            if (overPiece) return false;

            if (phase.pieceAt(move.to) == Piece.empty) return false;
            overPiece = true;
          }
        }

        if (!overPiece && phase.pieceAt(move.to) != Piece.empty) return false;
        //
      } else {
        //
        var overPiece = false;

        for (var i = move.fx + 1; i < move.tx; i++) {
          //
          if (phase.pieceAt(move.fy * 9 + i) != Piece.empty) {
            //
            if (overPiece) return false;

            if (phase.pieceAt(move.to) == Piece.empty) return false;
            overPiece = true;
          }
        }

        if (!overPiece && phase.pieceAt(move.to) != Piece.empty) return false;
      }
    } else {
      //
      if (dy < 0) {
        //
        var overPiece = false;

        for (var i = move.fy - 1; i > move.ty; i--) {
          //
          if (phase.pieceAt(i * 9 + move.fx) != Piece.empty) {
            //
            if (overPiece) return false;

            if (phase.pieceAt(move.to) == Piece.empty) return false;
            overPiece = true;
          }
        }

        if (!overPiece && phase.pieceAt(move.to) != Piece.empty) return false;
        //
      } else {
        //
        var overPiece = false;

        for (var i = move.fy + 1; i < move.ty; i++) {
          //
          if (phase.pieceAt(i * 9 + move.fx) != Piece.empty) {
            //
            if (overPiece) return false;

            if (phase.pieceAt(move.to) == Piece.empty) return false;
            overPiece = true;
          }
        }

        if (!overPiece && phase.pieceAt(move.to) != Piece.empty) return false;
      }
    }

    return true;
  }

  static bool validatePawnStep(Phase phase, Move move) {
    //
    final dy = move.ty - move.fy;
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    if (adx > 1 || ady > 1 || (adx + ady) > 1) return false;

    if (phase.side == Side.red) {
      //
      if (move.fy > 4 && adx != 0) return false;
      if (dy > 0) return false;
      //
    } else {
      //
      if (move.fy < 5 && adx != 0) return false;
      if (dy < 0) return false;
    }

    return true;
  }

  static bool posOnBoard(int pos) {
    return pos > -1 && pos < 90;
  }

  static int findKingPos(Phase phase) {
    //
    for (var i = 0; i < 90; i++) {
      //
      final piece = phase.pieceAt(i);

      if (piece == Piece.redKing || piece == Piece.blackKing) {
        if (phase.side == Side.of(piece)) return i;
      }
    }

    return -1;
  }

  static int abs(int value) {
    return value > 0 ? value : -value;
  }

  static int binarySearch(List<int> array, int start, int end, int key) {
    //
    if (start > end) return -1;

    if (array[start] == key) return start;
    if (array[end] == key) return end;

    final middle = start + (end - start) ~/ 2;
    if (array[middle] == key) return middle;

    if (key < array[middle]) {
      return binarySearch(array, start + 1, middle - 1, key);
    }

    return binarySearch(array, middle + 1, end - 1, key);
  }
}
