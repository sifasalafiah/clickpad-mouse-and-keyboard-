import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'iap_service.dart';

class AdService extends ChangeNotifier with WidgetsBindingObserver {
  static final AdService instance = AdService._internal();
  AdService._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appOpenLoadTime;

  bool _initialized = false;
  bool _canRequestAds = false;
  bool _isPrivacyOptionsRequired = false;

  bool get canRequestAds => _canRequestAds;
  bool get isPrivacyOptionsRequired => _isPrivacyOptionsRequired;

  /// Initialize Google Mobile Ads SDK with GDPR / UMP Consent Gathering
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      WidgetsBinding.instance.addObserver(this);
      IapService.instance.addListener(_onIapChanged);

      // If user is already ClickPad PRO, completely skip ads and consent
      if (IapService.instance.isPro) {
        debugPrint(
          'User is ClickPad PRO: Skipping consent gathering and ads initialization.',
        );
        _canRequestAds = false;
        _isPrivacyOptionsRequired = false;
        return;
      }

      // 1. Gather GDPR / US State UMP Consent (Google User Messaging Platform)
      await _gatherConsent();

      // 2. Initialize MobileAds SDK if user consent is obtained or ads can be served
      if (_canRequestAds) {
        await MobileAds.instance.initialize();
        if (!IapService.instance.isPro) {
          loadAppOpenAd();
        }
      }
    } catch (e) {
      debugPrint('AdService initialization error: $e');
    }
  }

  /// Gather GDPR / UMP consent from the user (EEA, UK, and US State Regulations)
  Future<void> _gatherConsent() async {
    if (IapService.instance.isPro) {
      _canRequestAds = false;
      _isPrivacyOptionsRequired = false;
      return;
    }
    final completer = Completer<void>();

    if (kDebugMode) {
      await ConsentInformation.instance.reset();
    }

    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: ['7DE9ED6305EE99978DF6F5CAD00ED1C9'],
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            debugPrint('ConsentForm loadAndShow error: ${formError.message}');
          }
          await _checkConsentStatus();
          if (!completer.isCompleted) completer.complete();
        });
      },
      (formError) async {
        debugPrint('ConsentInfoUpdate error: ${formError.message}');
        await _checkConsentStatus();
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () async {
        debugPrint(
          'Consent gathering timeout. Checking current consent status.',
        );
        await _checkConsentStatus();
      },
    );
  }

  Future<void> _checkConsentStatus() async {
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    _isPrivacyOptionsRequired =
        (status == PrivacyOptionsRequirementStatus.required);
    notifyListeners();
  }

  /// Open GDPR privacy options form so users can review or change their consent preferences
  void showPrivacyOptionsForm(
    BuildContext context, {
    VoidCallback? onDismissed,
  }) {
    isSuppressingAppOpenAd = true;
    ConsentForm.showPrivacyOptionsForm((formError) async {
      isSuppressingAppOpenAd = false;
      if (formError != null) {
        debugPrint('PrivacyOptionsForm error: ${formError.message}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load privacy options: ${formError.message}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        await _checkConsentStatus();
        if (_canRequestAds &&
            !IapService.instance.isPro &&
            _appOpenAd == null) {
          loadAppOpenAd();
        }
        onDismissed?.call();
      }
    });
  }

  /// Reset consent state (Useful for debugging/testing GDPR dialog multiple times)
  Future<void> resetConsentForDebug() async {
    await ConsentInformation.instance.reset();
    await _checkConsentStatus();
  }

  void _onIapChanged() {
    if (IapService.instance.isPro) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
    } else if (_canRequestAds && _appOpenAd == null) {
      loadAppOpenAd();
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
    if (IapService.instance.isPro) return;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (IapService.instance.isPro) {
            ad.dispose();
            _appOpenAd = null;
            return;
          }
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
    if (IapService.instance.isPro) return false;
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) <
        const Duration(hours: 4);
  }

  /// Show App Open Ad if available
  void showAppOpenAdIfAvailable() {
    if (IapService.instance.isPro) return;

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

  DateTime? _pausedTime;

  /// Flag to explicitly suppress showing App Open Ad (e.g. when opening system settings or permission prompts)
  bool isSuppressingAppOpenAd = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (IapService.instance.isPro) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedTime = _pausedTime;
      _pausedTime = null;

      // Skip if explicitly suppressed (e.g. while asking permission or system settings)
      if (isSuppressingAppOpenAd) {
        isSuppressingAppOpenAd = false;
        debugPrint(
          'AppOpenAd suppressed due to permission or system dialog flow.',
        );
        return;
      }

      // Skip if app was paused/inactive for less than 4 seconds (e.g. permission popup, system dialog)
      if (pausedTime != null) {
        final durationInBackground = DateTime.now().difference(pausedTime);
        if (durationInBackground.inSeconds < 4) {
          debugPrint(
            'App was paused briefly (${durationInBackground.inSeconds}s). Skipping AppOpenAd.',
          );
          return;
        }
      }

      showAppOpenAdIfAvailable();
    }
  }
}
