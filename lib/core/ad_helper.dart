import 'dart:io';

class AdHelper {
  // App Open Ad Unit ID
  static String appOpenAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/9257395921' // Demo/Test
          : 'ca-app-pub-8456214794435697~1867004994'; // Ganti dengan produksi
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Adaptive Banner Ad Unit ID
  static String adaptiveBannerAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/9214589741' // Demo/Test
          : 'YOUR_PRODUCTION_ADAPTIVE_BANNER_AD_UNIT_ID';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Fixed Size Banner Ad Unit ID
  static String bannerAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/6300978111' // Demo/Test
          : 'ca-app-pub-8456214794435697/7950015855'; // Produksi
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Interstitial Ad Unit ID
  static String interstitialAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/1033173712' // Demo/Test
          : 'ca-app-pub-8456214794435697/3305066947';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Rewarded Ad Unit ID
  static String rewardedAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/5224354917' // Demo/Test
          : 'ca-app-pub-8456214794435697/4846181654';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Rewarded Interstitial Ad Unit ID
  static String rewardedInterstitialAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/5354046379' // Demo/Test
          : 'YOUR_PRODUCTION_REWARDED_INTERSTITIAL_AD_UNIT_ID';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Native Ad Unit ID
  static String nativeAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/2247696110' // Demo/Test
          : 'YOUR_PRODUCTION_NATIVE_AD_UNIT_ID';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Native Video Ad Unit ID
  static String nativeVideoAdUnitId({bool isTest = false}) {
    if (Platform.isAndroid) {
      return isTest
          ? 'ca-app-pub-3940256099942544/1044960115' // Demo/Test
          : 'YOUR_PRODUCTION_NATIVE_VIDEO_AD_UNIT_ID';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}