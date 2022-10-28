import 'package:sprintf/sprintf.dart';

import 'cc_base.dart';

class MoveRecorder {
  //
  // 无吃子步数、总回合数
  var halfMove = 0, fullMove = 0;
  final _history = <Move>[];

  MoveRecorder({this.halfMove = 0, this.fullMove = 0});

  MoveRecorder.fromCounterMarks(String marks) {
    //
    var segments = marks.split(' ');
    if (segments.length != 2) {
      throw 'Error: Invalid Counter Marks: $marks';
    }

    halfMove = int.parse(segments[0]);
    fullMove = int.parse(segments[1]);
  }

  MoveRecorder.fromOther(MoveRecorder other) {
    halfMove = other.halfMove;
    fullMove = other.fullMove;
  }

  void stepIn(Move move, String side) {
    //
    if (move.captured != Piece.empty) {
      halfMove = 0;
    } else {
      halfMove++;
    }

    if (fullMove == 0) {
      fullMove++;
    } else if (side == Side.black) {
      fullMove++;
    }

    _history.add(move);
  }

  Move? removeLast() {
    if (_history.isEmpty) return null;
    return _history.removeLast();
  }

  Move? get last => _history.isEmpty ? null : _history.last;

  List<Move> reverseMovesToPrevCapture() {
    //
    var moves = <Move>[];

    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].captured != Piece.empty) break;
      moves.add(_history[i]);
    }

    return moves;
  }

  String movesAfterLastCaptured() {
    //
    var steps = '', posAfterLastCaptured = -1;

    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].captured != Piece.empty) {
        posAfterLastCaptured = i;
        break;
      }
    }

    for (var i = posAfterLastCaptured + 1; i < _history.length; i++) {
      steps += ' ${_history[i].step}';
    }

    return steps.isNotEmpty ? steps.substring(1) : '';
  }

  String allMoves() {
    //
    var steps = '';

    for (var i = 0; i < _history.length; i++) {
      steps += ' ${_history[i].step}';
    }

    return steps.isNotEmpty ? steps.substring(1) : '';
  }

  String buildManualText() {
    //
    var manualText = '';

    for (var i = 0; i < _history.length; i += 2) {
      //
      final n = (i / 2 + 1).toInt();
      final np = '${n < 10 ? ' ' : ''}$n';

      manualText += '$np. ${_history[i].stepName}';

      if (i + 1 < _history.length) {
        manualText += '　${_history[i + 1].stepName}\n';
      }
    }

    if (manualText.isEmpty) {
      manualText = '--';
    }

    return manualText;
  }

  String buildMoveListForManual() {
    //
    var result = '';

    for (var move in _history) {
      result += '${move.fx}${move.fy}${move.tx}${move.ty}';
    }

    return result;
  }

  int get historyLength => _history.length;

  Move stepAt(int index) => _history[index];

  @override
  String toString() {
    return '$halfMove $fullMove';
  }
}
