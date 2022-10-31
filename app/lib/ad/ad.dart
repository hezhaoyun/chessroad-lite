import 'dart:io';

import 'package:flutter/material.dart';

/*=hide_for_windows=*/
// import 'package:flutter_pangle_ads/flutter_pangle_ads.dart';
import '../config/local_data.dart';
/*=end=*/

abstract class Ad {
  //
  static const int kAdEnabled = 1;
  static const int kAdDisabled = 0;

  static final Ad _instance =
      (Platform.isIOS || Platform.isAndroid) ? CSJ() : NoAd();

  static Ad get instance => _instance;

  bool get initCompleted;

  Future<void> init();

  Future<dynamic> showSplashVideo(BuildContext context);

  Future<dynamic> showRewardVideo(
    BuildContext context,
    void Function(BuildContext ctx) completed,
  );
}

class NoAd implements Ad {
  //
  @override
  Future<void> init() async {}

  @override
  bool get initCompleted => true;

  @override
  Future<bool> showRewardVideo(
    BuildContext _,
    void Function(BuildContext ctx) __,
  ) async {
    return true;
  }

  @override
  Future<bool> showSplashVideo(BuildContext _) async => true;
}

class CSJ implements Ad {
  //
  bool _initCompleted = false;

  @override
  Future<void> init() async {
    //
    /*=hide_for_windows=*/

    if (!LocalData().acceptedPrivacyPolicy.value) return;

    if (Platform.isIOS) {
      // await FlutterPangleAds.requestIDFA;
    }

    if (Platform.isAndroid) {
      // await FlutterPangleAds.requestPermissionIfNecessary;
    }

    // final appId = Platform.isIOS ? '5314232' : '5315499';
    // await FlutterPangleAds.initAd(appId);

    _initCompleted = true;

    /*=end=*/
  }

  @override
  bool get initCompleted => _initCompleted;

  @override
  Future<dynamic> showSplashVideo(BuildContext context) async {
    //
    /*=hide_for_windows=*/

    // final posId = Platform.isIOS ? '887834277' : '887838824';
    // return FlutterPangleAds.showSplashAd(posId, timeout: 3.5);

    /*=end=*/
  }

  @override
  Future<dynamic> showRewardVideo(
    BuildContext context,
    void Function(BuildContext context) completed,
  ) async {
    //
    /*=hide_for_windows=*/

    // FlutterPangleAds.onEventListener((AdEvent event) {
    //   if (event.action == AdEventAction.onAdReward) {
    //     completed(context);
    //   }
    // });

    // final posId = Platform.isIOS ? '949159175' : '949200970';
    // return FlutterPangleAds.showRewardVideoAd(posId);

    /*=end=*/
  }
}
