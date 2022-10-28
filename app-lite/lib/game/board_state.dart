import 'package:flutter/material.dart';
import '../cchess/cc_base.dart';
import '../cchess/cc_fen.dart';
import '../cchess/cc_rules.dart';
import '../cchess/phase.dart';
import '../services/audios.dart';
import 'game.dart';

class BoardState with ChangeNotifier {
  //
  late Phase _phase;
  late int _focusIndex, _blurIndex;
  late double _pieceAnimationValue;

  BoardState() {
    _phase = Phase.defaultPhase();
    _focusIndex = _blurIndex = Move.invalidIndex;
    _pieceAnimationValue = 1;
  }

  setPhase(Phase phase, {notify = true}) {
    //
    _phase = phase;
    _focusIndex = _blurIndex = Move.invalidIndex;

    if (notify) notifyListeners();
  }

  bool _boardInversed = false;
  bool get boardInversed => _boardInversed;

  bool _sitUnderside = true;

  inverseBoard(bool inverse, {notify = true, swapSite = false}) {
    //
    _boardInversed = inverse;

    if (swapSite) {
      _sitUnderside = !_sitUnderside;
    }

    if (notify) notifyListeners();
  }

  String get playerSide {
    if (_sitUnderside) return _boardInversed ? Side.black : Side.red;
    return _boardInversed ? Side.red : Side.black;
  }

  String get oppositeSide => playerSide == Side.red ? Side.black : Side.red;

  load(String fen, {notify = false}) {
    //
    final phase = Fen.phaseFromFen(fen);
    if (phase == null) return false;

    _phase = phase;
    _focusIndex = _blurIndex = Move.invalidIndex;

    if (notify) notifyListeners();

    return true;
  }

  pieceAnimationUpdate(double pieceAnimationValue) {
    _pieceAnimationValue = pieceAnimationValue;
    notifyListeners();
  }

  select(int index) {
    //
    _focusIndex = index;
    _blurIndex = Move.invalidIndex;
    Audios.playTone('click.mp3');

    notifyListeners();
  }

  bool move(Move move) {
    //
    if (!_phase.move(move)) {
      Audios.playTone('invalid.mp3');
      return false;
    }

    _focusIndex = move.to;
    _blurIndex = move.from;

    if (ChessRules.beChecked(_phase)) {
      Audios.playTone('check.mp3');
    } else {
      Audios.playTone(
        lastMoveCaptured != Piece.empty ? 'capture.mp3' : 'move.mp3',
      );
    }

    notifyListeners();

    return true;
  }

  regret(GameScene scene, {steps = 2}) {
    //
    // 轮到自己走棋的时候，才能悔棋
    if (isVs(scene) && isOppoTurn) {
      Audios.playTone('invalid.mp3');
      return;
    }

    var regreted = false;

    /// 悔棋一回合（两步），才能撤回自己上一次的动棋

    for (var i = 0; i < steps; i++) {
      //
      if (!_phase.regret()) break;

      final lastMove = _phase.lastMove;

      if (lastMove != null) {
        //
        _blurIndex = lastMove.from;
        _focusIndex = lastMove.to;
        //
      } else {
        //
        _blurIndex = _focusIndex = Move.invalidIndex;
      }

      regreted = true;
    }

    if (regreted) {
      Audios.playTone('regret.mp3');
      notifyListeners();
    } else {
      Audios.playTone('invalid.mp3');
    }
  }

  clearFocus({notify = true}) {
    _focusIndex = _blurIndex = Move.invalidIndex;
    if (notify) notifyListeners();
  }

  saveManual(GameScene scene) async => await _phase.saveManual(scene);

  buildMoveListForManual() => _phase.buildMoveListForManual();

  String get lastMoveCaptured {
    final lastMove = _phase.lastMove;
    final captured = lastMove?.captured;
    return captured ?? Piece.empty;
  }

  Phase get phase => _phase;
  int get focusIndex => _focusIndex;
  int get blurIndex => _blurIndex;
  double get pieceAnimationValue => _pieceAnimationValue;

  bool get isMyTurn => _phase.side == playerSide;
  bool get isOppoTurn => _phase.side == oppositeSide;
}
