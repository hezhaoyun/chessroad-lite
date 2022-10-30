import 'package:flutter/material.dart';

import '../config/local_data.dart';

// Channels
const kChannelCommon = 'Common';
const kChannelMainland = 'Mainland';
const kChannelCurrent = kChannelMainland;

enum GameScene {
  unknown,
  battle,
}

bool isVs(GameScene scene) => true;

class GameColors {
  //
  static const logoColor = Color(0xFF6D000D);
  static const activeColor = Color(0xFF4DA736);

  static const primary = Color(0xFF461220);
  static const secondary = Color(0x99461220);

  static const darkBackground = Colors.brown;
  static const lightBackground = Color(0xFFEEE0CB);
  static const specialBackground = Color(0xFF555555);
  static const menuBackground = Color(0xFFEFDECF);

  static const boardBackground = Color(0xFFEBC38D);

  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Color(0x99FFFFFF);

  static const boardLine = Color(0x996D000D);
  static const boardTips = Color(0x666D000D);

  static const lightLine = Color(0x336D000D);
}

class BoardTheme {
  //
  static const defaultTheme = BoardTheme();
  static const highContrastTheme = BoardTheme(
    blackPieceColor: Colors.black,
    blackPieceTextColor: Colors.white,
    redPieceColor: Colors.white,
    redPieceTextColor: Colors.black,
  );

  final Color focusPosition, blurPosition;
  final Color blackPieceColor, blackPieceBorderColor;
  final Color redPieceColor, redPieceBorderColor;
  final Color blackPieceTextColor, redPieceTextColor;

  const BoardTheme({
    this.focusPosition = const Color(0xCCFF8B00),
    this.blurPosition = const Color(0xCCFF8B00),
    this.blackPieceColor = const Color(0xFF222222),
    this.blackPieceBorderColor = const Color(0xFFFF8B00),
    this.redPieceColor = const Color(0xFF7B0000),
    this.redPieceBorderColor = const Color(0xFFFF8B00),
    this.blackPieceTextColor = const Color(0xCCFFFFFF),
    this.redPieceTextColor = const Color(0xCCFFFFFF),
  });
}

class GameFonts {
  //
  static TextStyle uicp({
    double? fontSize,
    Color color = GameColors.primary,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontFamily: LocalData().uiFont.value,
      height: height,
    );
  }

  static TextStyle ui({
    double? fontSize,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontFamily: LocalData().uiFont.value,
      height: height,
    );
  }

  static TextStyle art({
    double? fontSize,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontFamily: LocalData().artFont.value,
      height: height,
    );
  }

  static TextStyle artForce({
    double? fontSize,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontFamily: LocalData().artFont.value,
      height: height,
    );
  }
}
