import 'package:flutter/material.dart';
import '../../config/local_data.dart';
import '../../game/game.dart';

class BlurHolder extends StatelessWidget {
  //
  final double diameter, squreSide;

  const BlurHolder({
    Key? key,
    required this.diameter,
    required this.squreSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //
    final theme = LocalData().highContrast.value
        ? BoardTheme.highContrastTheme
        : BoardTheme.defaultTheme;

    return Container(
      margin: EdgeInsets.all((squreSide - diameter) / 2),
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(diameter / 2),
        color: theme.blurPosition,
      ),
    );
  }
}
