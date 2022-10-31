import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageState with ChangeNotifier {
  //
  String _status = '...';
  String get status => _status;

  double _stepTimeOpponent = 0;
  double get stepTimeOpponent => _stepTimeOpponent;

  double _stepTimeSelf = 0;
  double get stepTimeSelf => _stepTimeSelf;

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
      _stepTimeSelf = selfTimer['step_time'];
      _gameTimeSelf = selfTimer['game_time'];

      _stepTimeOpponent = opponentTimer['step_time'];
      _gameTimeOpponent = opponentTimer['game_time'];
    } catch (_) {}

    if (notify) notifyListeners();
  }
}
