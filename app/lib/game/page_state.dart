import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageState with ChangeNotifier {
  //
  String _status = '...';
  String get status => _status;

  double _moveTimeOpponent = 0;
  double get moveTimeOpponent => _moveTimeOpponent;

  double _moveTimeSelf = 0;
  double get moveTimeSelf => _moveTimeSelf;

  double _gameTimeOpponent = 0;
  double get gameTimeOpponent => _gameTimeOpponent;

  double _gameTimeSelf = 0;
  double get gameTimeSelf => _gameTimeSelf;

  changeStatus(String newValue, {notify = true}) {
    _status = newValue;
    if (notify) notifyListeners();
  }

  updateClock(
    Map<String, dynamic> selfTimer,
    Map<String, dynamic> opponentTimer, {
    notify = true,
  }) {
    //
    try {
      _moveTimeSelf = selfTimer['move_time'];
      _gameTimeSelf = selfTimer['game_time'];

      _moveTimeOpponent = opponentTimer['move_time'];
      _gameTimeOpponent = opponentTimer['game_time'];
    } catch (_) {}

    if (notify) notifyListeners();
  }
}
