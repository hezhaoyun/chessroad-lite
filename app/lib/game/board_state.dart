import 'package:chessroad/engine/engine.dart';
import 'package:flutter/material.dart';
import '../cchess/cc_base.dart';
import '../cchess/cc_fen.dart';
import '../cchess/cc_rules.dart';
import '../cchess/position.dart';
import '../services/audios.dart';
import 'game.dart';

class BoardState with ChangeNotifier {
  //
  late Position _position;
  late int _focusIndex, _blurIndex;
  late double _pieceAnimationValue;

  EngineInfo? _engineInfo;
  Bestmove? bestmove;

  BoardState() {
    _position = Position.startpos;
    _focusIndex = _blurIndex = Move.invalidIndex;
    _pieceAnimationValue = 1;
  }

  setPosition(Position position, {notify = true}) {
    //
    _position = position;
    _focusIndex = _blurIndex = Move.invalidIndex;

    if (notify) notifyListeners();
  }

  bool _boardInverse = false;
  bool get boardInversed => _boardInverse;

  bool _sitUnderside = true;

  inverseBoard(bool inverse, {notify = true, swapSite = false}) {
    //
    _boardInverse = inverse;

    if (swapSite) _sitUnderside = !_sitUnderside;

    if (notify) notifyListeners();
  }

  String get playerSide {
    if (_sitUnderside) return _boardInverse ? PieceColor.black : PieceColor.red;
    return _boardInverse ? PieceColor.red : PieceColor.black;
  }

  String get oppositeSide =>
      playerSide == PieceColor.red ? PieceColor.black : PieceColor.red;

  load(String fen, {notify = false}) {
    //
    final position = Fen.positionFromFen(fen);
    if (position == null) return false;

    _position = position;
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
    if (!_position.move(move)) {
      Audios.playTone('invalid.mp3');
      return false;
    }

    _focusIndex = move.to;
    _blurIndex = move.from;

    if (ChessRules.beChecked(_position)) {
      Audios.playTone('check.mp3');
    } else {
      Audios.playTone(
        lastMoveCaptured != Piece.noPiece ? 'capture.mp3' : 'move.mp3',
      );
    }

    notifyListeners();

    return true;
  }

  regret(GameScene scene, {moves = 2}) {
    //
    // 轮到自己走棋的时候，才能悔棋
    if (isVs(scene) && isOpponentTurn) {
      Audios.playTone('invalid.mp3');
      return;
    }

    var regretted = false;

    /// 悔棋一回合（两步），才能撤回自己上一次的动棋

    for (var i = 0; i < moves; i++) {
      //
      if (!_position.regret()) break;

      final lastMove = _position.lastMove;

      if (lastMove != null) {
        //
        _blurIndex = lastMove.from;
        _focusIndex = lastMove.to;
        //
      } else {
        //
        _blurIndex = _focusIndex = Move.invalidIndex;
      }

      regretted = true;
    }

    if (regretted) {
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

  saveManual(GameScene scene) async => await _position.saveManual(scene);

  buildMoveListForManual() => _position.buildMoveListForManual();

  String get lastMoveCaptured {
    final lastMove = _position.lastMove;
    final captured = lastMove?.captured;
    return captured ?? Piece.noPiece;
  }

  EngineInfo? get engineInfo => _engineInfo;

  set engineInfo(EngineInfo? engineInfo) {
    _engineInfo = engineInfo;
    notifyListeners();
  }

  Position get position => _position;
  int get focusIndex => _focusIndex;
  int get blurIndex => _blurIndex;
  double get pieceAnimationValue => _pieceAnimationValue;

  bool get isMyTurn => _position.sideToMove == playerSide;
  bool get isOpponentTurn => _position.sideToMove == oppositeSide;
}
