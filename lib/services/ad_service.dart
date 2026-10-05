import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService with WidgetsBindingObserver {
  static final AdService instance = AdService._internal();
  AdService._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appOpenLoadTime;

  bool _initialized = false;

  /// Initialize Google Mobile Ads SDK
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await MobileAds.instance.initialize();
      WidgetsBinding.instance.addObserver(this);
      loadAppOpenAd();
    } catch (e) {
      debugPrint('AdService initialization error: $e');
    }
  }

  /// Platform-specific Banner Ad Unit ID
  /// Uses Production Ad Unit IDs in Release Mode (`kReleaseMode`), and Test IDs in Debug/Profile Mode.
  String get bannerAdUnitId {
    if (kReleaseMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ca-app-pub-4676075129526023/2524225514'; // Android Banner Production ID
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-4676075129526023/7685138576'; // iOS Banner Production ID
      }
    }
    
    // Debug & Profile Test IDs
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Banner Test ID
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // Android Banner Test ID
  }

  /// Platform-specific App Open Ad Unit ID
  /// Uses Production Ad Unit IDs in Release Mode (`kReleaseMode`), and Test IDs in Debug/Profile Mode.
  String get appOpenAdUnitId {
    if (kReleaseMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ca-app-pub-4676075129526023/2017878923'; // Android App Open Production ID
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-4676075129526023/3650614087'; // iOS App Open Production ID
      }
    }
    
    // Debug & Profile Test IDs
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // iOS App Open Test ID
    }
    return 'ca-app-pub-3940256099942544/9257395921'; // Android App Open Test ID
  }

  /// Load App Open Ad
  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded successfully');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Check if App Open Ad is available and not expired (valid for 4 hours)
  bool get isAppOpenAdAvailable {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  /// Show App Open Ad if available
  void showAppOpenAdIfAvailable() {
    if (!isAppOpenAdAvailable) {
      debugPrint('AppOpenAd is not available. Loading a new one...');
      loadAppOpenAd();
      return;
    }

    if (_isShowingAppOpenAd) {
      debugPrint('AppOpenAd is already showing.');
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: $error');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd dismissed');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAppOpenAdIfAvailable();
    }
  }
}
