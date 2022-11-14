import 'position.dart';
import 'cc_base.dart';

class ChessRules {
  //
  static bool beChecked(Position position) {
    //
    final myKingPos = findKingPos(position);

    final opponentPosition = Position.clone(position);
    opponentPosition.turnSide();

    final opponentMoves = enumMoves(opponentPosition);

    for (var move in opponentMoves) {
      if (move.to == myKingPos) return true;
    }

    return false;
  }

  static bool willBeChecked(Position position, Move move) {
    //
    final tempPosition = Position.clone(position);
    tempPosition.moveTest(move);

    return beChecked(tempPosition);
  }

  static bool willKingsMeet(Position position, Move move) {
    //
    final tempPosition = Position.clone(position);
    tempPosition.moveTest(move);

    for (var file = 3; file < 6; file++) {
      //
      var foundKingAlready = false;

      for (var rank = 0; rank < 10; rank++) {
        //
        final piece = tempPosition.pieceAt(rank * 9 + file);

        if (!foundKingAlready) {
          if (piece == Piece.redKing || piece == Piece.blackKing) {
            foundKingAlready = true;
          }
          if (rank > 2) break;
        } else {
          if (piece == Piece.redKing || piece == Piece.blackKing) return true;
          if (piece != Piece.noPiece) break;
        }
      }
    }

    return false;
  }

  static bool beCheckmated(Position position) {
    //
    final moves = ChessRules.enumMoves(position);

    for (var move in moves) {
      if (ChessRules.validate(position, move)) return false;
    }

    return true;
  }

  static List<Move> enumMoves(Position position) {
    //
    final moves = <Move>[];

    for (var rank = 0; rank < 10; rank++) {
      //
      for (var file = 0; file < 9; file++) {
        //
        final from = rank * 9 + file;
        final piece = position.pieceAt(from);

        if (PieceColor.of(piece) != position.sideToMove) continue;

        List<Move> pieceMoves;

        if (piece == Piece.redKing || piece == Piece.blackKing) {
          pieceMoves = enumKingMoves(position, rank, file, from);
        } else if (piece == Piece.redAdvisor || piece == Piece.blackAdvisor) {
          pieceMoves = enumAdvisorMoves(position, rank, file, from);
        } else if (piece == Piece.redBishop || piece == Piece.blackBishop) {
          pieceMoves = enumBishopMoves(position, rank, file, from);
        } else if (piece == Piece.redKnight || piece == Piece.blackKnight) {
          pieceMoves = enumKnightMoves(position, rank, file, from);
        } else if (piece == Piece.redRook || piece == Piece.blackRook) {
          pieceMoves = enumRookMoves(position, rank, file, from);
        } else if (piece == Piece.redCanon || piece == Piece.blackCanon) {
          pieceMoves = enumCanonMoves(position, rank, file, from);
        } else if (piece == Piece.redPawn || piece == Piece.blackPawn) {
          pieceMoves = enumPawnMoves(position, rank, file, from);
        } else {
          continue;
        }

        moves.addAll(pieceMoves);
      }
    }

    return moves;
  }

  static bool validate(Position position, Move move) {
    //
    if (PieceColor.of(position.pieceAt(move.to)) == position.sideToMove) {
      return false;
    }

    final piece = position.pieceAt(move.from);

    var valid = false;

    if (piece == Piece.redKing || piece == Piece.blackKing) {
      valid = validateKingMove(position, move);
    } else if (piece == Piece.redAdvisor || piece == Piece.blackAdvisor) {
      valid = validateAdvisorMove(position, move);
    } else if (piece == Piece.redBishop || piece == Piece.blackBishop) {
      valid = validateBishopMove(position, move);
    } else if (piece == Piece.redKnight || piece == Piece.blackKnight) {
      valid = validateKnightMove(position, move);
    } else if (piece == Piece.redRook || piece == Piece.blackRook) {
      valid = validateRookMove(position, move);
    } else if (piece == Piece.redCanon || piece == Piece.blackCanon) {
      valid = validateCanonMove(position, move);
    } else if (piece == Piece.redPawn || piece == Piece.blackPawn) {
      valid = validatePawnMove(position, move);
    }

    if (!valid) return false;

    if (willBeChecked(position, move)) return false;

    if (willKingsMeet(position, move)) return false;

    return true;
  }

  static List<Move> enumKingMoves(
      Position position, int rank, int file, int from) {
    //
    final offsetList = [
      [-1, 0],
      [0, -1],
      [1, 0],
      [0, 1]
    ];

    final redRange = [66, 67, 68, 75, 76, 77, 84, 85, 86];
    final blackRange = [3, 4, 5, 12, 13, 14, 21, 22, 23];
    final range =
        (position.sideToMove == PieceColor.red ? redRange : blackRange);

    final moves = <Move>[];

    for (var i = 0; i < 4; i++) {
      //
      final offset = offsetList[i];
      final to = (rank + offset[0]) * 9 + file + offset[1];

      if (!posOnBoard(to) ||
          PieceColor.of(position.pieceAt(to)) == position.sideToMove) {
        continue;
      }

      if (binarySearch(range, 0, range.length - 1, to) > -1) {
        moves.add(Move(from, to));
      }
    }

    return moves;
  }

  static List<Move> enumAdvisorMoves(
      Position position, int rank, int file, int from) {
    //
    final offsetList = [
      [-1, -1],
      [1, -1],
      [-1, 1],
      [1, 1]
    ];

    final redRange = [66, 68, 76, 84, 86];
    final blackRange = [3, 5, 13, 21, 23];
    final range = position.sideToMove == PieceColor.red ? redRange : blackRange;

    final moves = <Move>[];

    for (var i = 0; i < 4; i++) {
      //
      final offset = offsetList[i];
      final to = (rank + offset[0]) * 9 + file + offset[1];

      if (!posOnBoard(to) ||
          PieceColor.of(position.pieceAt(to)) == position.sideToMove) {
        continue;
      }

      if (binarySearch(range, 0, range.length - 1, to) > -1) {
        moves.add(Move(from, to));
      }
    }

    return moves;
  }

  static List<Move> enumBishopMoves(
      Position position, int rank, int file, int from) {
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
    final range = position.sideToMove == PieceColor.red ? redRange : blackRange;

    final moves = <Move>[];

    for (var i = 0; i < 4; i++) {
      //
      final heartOffset = heartOffsetList[i];
      final heart = (rank + heartOffset[0]) * 9 + (file + heartOffset[1]);

      if (!posOnBoard(heart) || position.pieceAt(heart) != Piece.noPiece) {
        continue;
      }

      final offset = offsetList[i];
      final to = (rank + offset[0]) * 9 + (file + offset[1]);

      if (!posOnBoard(to) ||
          PieceColor.of(position.pieceAt(to)) == position.sideToMove) {
        continue;
      }

      if (binarySearch(range, 0, range.length - 1, to) > -1) {
        moves.add(Move(from, to));
      }
    }

    return moves;
  }

  static List<Move> enumKnightMoves(
      Position position, int rank, int file, int from) {
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

    final moves = <Move>[];

    for (var i = 0; i < 8; i++) {
      //
      final offset = offsetList[i];
      final nr = rank + offset[0], nc = file + offset[1];

      if (nr < 0 || nr > 9 || nc < 0 || nc > 9) continue;

      final to = nr * 9 + nc;
      if (!posOnBoard(to) ||
          PieceColor.of(position.pieceAt(to)) == position.sideToMove) {
        continue;
      }

      final footOffset = footOffsetList[i];
      final fr = rank + footOffset[0], fc = file + footOffset[1];
      final foot = fr * 9 + fc;

      if (!posOnBoard(foot) || position.pieceAt(foot) != Piece.noPiece) {
        continue;
      }

      moves.add(Move(from, to));
    }

    return moves;
  }

  static List<Move> enumRookMoves(
      Position position, int rank, int file, int from) {
    //
    final moves = <Move>[];

    // to left
    for (var c = file - 1; c >= 0; c--) {
      final to = rank * 9 + c;
      final target = position.pieceAt(to);

      if (target == Piece.noPiece) {
        moves.add(Move(from, to));
      } else {
        if (PieceColor.of(target) != position.sideToMove) {
          moves.add(Move(from, to));
        }
        break;
      }
    }

    // to top
    for (var r = rank - 1; r >= 0; r--) {
      final to = r * 9 + file;
      final target = position.pieceAt(to);

      if (target == Piece.noPiece) {
        moves.add(Move(from, to));
      } else {
        if (PieceColor.of(target) != position.sideToMove) {
          moves.add(Move(from, to));
        }
        break;
      }
    }

    // to right
    for (var c = file + 1; c < 9; c++) {
      final to = rank * 9 + c;
      final target = position.pieceAt(to);

      if (target == Piece.noPiece) {
        moves.add(Move(from, to));
      } else {
        if (PieceColor.of(target) != position.sideToMove) {
          moves.add(Move(from, to));
        }
        break;
      }
    }

    // to down
    for (var r = rank + 1; r < 10; r++) {
      final to = r * 9 + file;
      final target = position.pieceAt(to);

      if (target == Piece.noPiece) {
        moves.add(Move(from, to));
      } else {
        if (PieceColor.of(target) != position.sideToMove) {
          moves.add(Move(from, to));
        }
        break;
      }
    }

    return moves;
  }

  static List<Move> enumCanonMoves(
      Position position, int rank, int file, int from) {
    //
    final moves = <Move>[];
    // to left
    var overPiece = false;

    for (var c = file - 1; c >= 0; c--) {
      final to = rank * 9 + c;
      final target = position.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.noPiece) {
          moves.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.noPiece) {
          if (PieceColor.of(target) != position.sideToMove) {
            moves.add(Move(from, to));
          }
          break;
        }
      }
    }

    // to top
    overPiece = false;

    for (var r = rank - 1; r >= 0; r--) {
      final to = r * 9 + file;
      final target = position.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.noPiece) {
          moves.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.noPiece) {
          if (PieceColor.of(target) != position.sideToMove) {
            moves.add(Move(from, to));
          }
          break;
        }
      }
    }

    // to right
    overPiece = false;

    for (var c = file + 1; c < 9; c++) {
      final to = rank * 9 + c;
      final target = position.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.noPiece) {
          moves.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.noPiece) {
          if (PieceColor.of(target) != position.sideToMove) {
            moves.add(Move(from, to));
          }
          break;
        }
      }
    }

    // to bottom
    overPiece = false;

    for (var r = rank + 1; r < 10; r++) {
      final to = r * 9 + file;
      final target = position.pieceAt(to);

      if (!overPiece) {
        if (target == Piece.noPiece) {
          moves.add(Move(from, to));
        } else {
          overPiece = true;
        }
      } else {
        if (target != Piece.noPiece) {
          if (PieceColor.of(target) != position.sideToMove) {
            moves.add(Move(from, to));
          }
          break;
        }
      }
    }

    return moves;
  }

  static List<Move> enumPawnMoves(
      Position position, int rank, int file, int from) {
    //
    var to =
        (rank + (position.sideToMove == PieceColor.red ? -1 : 1)) * 9 + file;

    final moves = <Move>[];

    if (posOnBoard(to) &&
        PieceColor.of(position.pieceAt(to)) != position.sideToMove) {
      moves.add(Move(from, to));
    }

    if ((position.sideToMove == PieceColor.red && rank < 5) ||
        (position.sideToMove == PieceColor.black && rank > 4)) {
      //
      if (file > 0) {
        to = rank * 9 + file - 1;
        if (posOnBoard(to) &&
            PieceColor.of(position.pieceAt(to)) != position.sideToMove) {
          moves.add(Move(from, to));
        }
      }

      if (file < 8) {
        to = rank * 9 + file + 1;
        if (posOnBoard(to) &&
            PieceColor.of(position.pieceAt(to)) != position.sideToMove) {
          moves.add(Move(from, to));
        }
      }
    }

    return moves;
  }

  static bool validateKingMove(Position position, Move move) {
    //
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    final isUpDownMove = (adx == 0 && ady == 1);
    final isLeftRightMove = (adx == 1 && ady == 0);

    if (!isUpDownMove && !isLeftRightMove) return false;

    final redRange = [66, 67, 68, 75, 76, 77, 84, 85, 86];
    final blackRange = [3, 4, 5, 12, 13, 14, 21, 22, 23];
    final range =
        (position.sideToMove == PieceColor.red) ? redRange : blackRange;

    return binarySearch(range, 0, range.length - 1, move.to) >= 0;
  }

  static bool validateAdvisorMove(Position position, Move move) {
    //
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    if (adx != 1 || ady != 1) return false;

    final redRange = [66, 68, 76, 84, 86], blackRange = [3, 5, 13, 21, 23];
    final range =
        (position.sideToMove == PieceColor.red) ? redRange : blackRange;

    return binarySearch(range, 0, range.length - 1, move.to) >= 0;
  }

  static bool validateBishopMove(Position position, Move move) {
    //
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    if (adx != 2 || ady != 2) return false;

    final redRange = [47, 51, 63, 67, 71, 83, 87],
        blackRange = [2, 6, 18, 22, 26, 38, 42];
    final range =
        (position.sideToMove == PieceColor.red) ? redRange : blackRange;

    if (binarySearch(range, 0, range.length - 1, move.to) < 0) return false;

    if (move.tx > move.fx) {
      if (move.ty > move.fy) {
        final heart = (move.fy + 1) * 9 + move.fx + 1;
        if (position.pieceAt(heart) != Piece.noPiece) return false;
      } else {
        final heart = (move.fy - 1) * 9 + move.fx + 1;
        if (position.pieceAt(heart) != Piece.noPiece) return false;
      }
    } else {
      if (move.ty > move.fy) {
        final heart = (move.fy + 1) * 9 + move.fx - 1;
        if (position.pieceAt(heart) != Piece.noPiece) return false;
      } else {
        final heart = (move.fy - 1) * 9 + move.fx - 1;
        if (position.pieceAt(heart) != Piece.noPiece) return false;
      }
    }

    return true;
  }

  static bool validateKnightMove(Position position, Move move) {
    //
    final dx = move.tx - move.fx, dy = move.ty - move.fy;
    final adx = abs(dx), ady = abs(dy);

    if (!(adx == 1 && ady == 2) && !(adx == 2 && ady == 1)) return false;

    if (adx > ady) {
      if (dx > 0) {
        final foot = move.fy * 9 + move.fx + 1;
        if (position.pieceAt(foot) != Piece.noPiece) return false;
      } else {
        final foot = move.fy * 9 + move.fx - 1;
        if (position.pieceAt(foot) != Piece.noPiece) return false;
      }
    } else {
      if (dy > 0) {
        final foot = (move.fy + 1) * 9 + move.fx;
        if (position.pieceAt(foot) != Piece.noPiece) return false;
      } else {
        final foot = (move.fy - 1) * 9 + move.fx;
        if (position.pieceAt(foot) != Piece.noPiece) return false;
      }
    }

    return true;
  }

  static bool validateRookMove(Position position, Move move) {
    //
    final dx = move.tx - move.fx, dy = move.ty - move.fy;

    if (dx != 0 && dy != 0) return false;

    if (dy == 0) {
      if (dx < 0) {
        for (var i = move.fx - 1; i > move.tx; i--) {
          if (position.pieceAt(move.fy * 9 + i) != Piece.noPiece) return false;
        }
      } else {
        for (var i = move.fx + 1; i < move.tx; i++) {
          if (position.pieceAt(move.fy * 9 + i) != Piece.noPiece) return false;
        }
      }
    } else {
      if (dy < 0) {
        for (var i = move.fy - 1; i > move.ty; i--) {
          if (position.pieceAt(i * 9 + move.fx) != Piece.noPiece) return false;
        }
      } else {
        for (var i = move.fy + 1; i < move.ty; i++) {
          if (position.pieceAt(i * 9 + move.fx) != Piece.noPiece) return false;
        }
      }
    }

    return true;
  }

  static bool validateCanonMove(Position position, Move move) {
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
          if (position.pieceAt(move.fy * 9 + i) != Piece.noPiece) {
            //
            if (overPiece) return false;

            if (position.pieceAt(move.to) == Piece.noPiece) return false;
            overPiece = true;
          }
        }

        if (!overPiece && position.pieceAt(move.to) != Piece.noPiece) {
          return false;
        }
        //
      } else {
        //
        var overPiece = false;

        for (var i = move.fx + 1; i < move.tx; i++) {
          //
          if (position.pieceAt(move.fy * 9 + i) != Piece.noPiece) {
            //
            if (overPiece) return false;

            if (position.pieceAt(move.to) == Piece.noPiece) return false;
            overPiece = true;
          }
        }

        if (!overPiece && position.pieceAt(move.to) != Piece.noPiece) {
          return false;
        }
      }
    } else {
      //
      if (dy < 0) {
        //
        var overPiece = false;

        for (var i = move.fy - 1; i > move.ty; i--) {
          //
          if (position.pieceAt(i * 9 + move.fx) != Piece.noPiece) {
            //
            if (overPiece) return false;

            if (position.pieceAt(move.to) == Piece.noPiece) return false;
            overPiece = true;
          }
        }

        if (!overPiece && position.pieceAt(move.to) != Piece.noPiece) {
          return false;
        }
        //
      } else {
        //
        var overPiece = false;

        for (var i = move.fy + 1; i < move.ty; i++) {
          //
          if (position.pieceAt(i * 9 + move.fx) != Piece.noPiece) {
            //
            if (overPiece) return false;

            if (position.pieceAt(move.to) == Piece.noPiece) return false;
            overPiece = true;
          }
        }

        if (!overPiece && position.pieceAt(move.to) != Piece.noPiece) {
          return false;
        }
      }
    }

    return true;
  }

  static bool validatePawnMove(Position position, Move move) {
    //
    final dy = move.ty - move.fy;
    final adx = abs(move.tx - move.fx), ady = abs(move.ty - move.fy);

    if (adx > 1 || ady > 1 || (adx + ady) > 1) return false;

    if (position.sideToMove == PieceColor.red) {
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

  static int findKingPos(Position position) {
    //
    for (var i = 0; i < 90; i++) {
      //
      final piece = position.pieceAt(i);

      if (piece == Piece.redKing || piece == Piece.blackKing) {
        if (position.sideToMove == PieceColor.of(piece)) return i;
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
