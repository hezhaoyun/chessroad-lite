import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageState with ChangeNotifier {
  //
  String _status = '...';
  String get status => _status;

  double _stepTimeOppo = 0;
  double get stepTimeOppo => _stepTimeOppo;

  double _stepTimeSelf = 0;
  double get stepTimeSelf => _stepTimeSelf;

  double _gameTimeOppo = 0;
  double get gameTimeOppo => _gameTimeOppo;

  double _gameTimeSelf = 0;
  double get gameTimeSelf => _gameTimeSelf;

  changeStatus(String newValue, {notify = true}) {
    _status = newValue;
    if (notify) notifyListeners();
  }

  updateClock(
    Map<String, dynamic> selfTimer,
    Map<String, dynamic> oppoTimer, {
    notify = true,
  }) {
    //
    try {
      _stepTimeSelf = selfTimer['step_time'];
      _gameTimeSelf = selfTimer['game_time'];

      _stepTimeOppo = oppoTimer['step_time'];
      _gameTimeOppo = oppoTimer['game_time'];
    } catch (_) {}

    if (notify) notifyListeners();
  }
}
