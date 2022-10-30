import 'package:flutter/material.dart';

class Ruler {
  //
  static double statusBarHeight(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return top > 0 ? top : -1;
  }

  static const kOperationBarHeight = 54.0;

  static const kBoardMargin = 10.0;
  static const kBoardPadding = 5.0;
  static const kBoardDigitsHeight = 20.0;
  static const kBoardDigitsTextFontSize = 18.0;

  static const kPuzzleBookMargin = 16.0;
  static const kPuzzleBookSpacing = 20.0;

  static const kReviewPaddingH = 10.0;
  static const kReviewPaddingV = 5.0;
  static const kReviewBoxSide = 14.0;

  static const kProperAspectRatio = 16.0 / 9.0;

  static double aspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height / size.width;
  }

  static bool isLongScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height / size.width >= 18 / 9;
  }
}
