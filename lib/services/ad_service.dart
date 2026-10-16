import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
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

    final params = ConsentRequestParameters();

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
              backgroundColor: AppColors.error,
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

  /// Platform-specific Rewarded Ad Unit ID
  /// Uses Production Ad Unit IDs in Release Mode (`kReleaseMode`), and Test IDs in Debug/Profile Mode.
  String get rewardedAdUnitId {
    if (kReleaseMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ca-app-pub-4676075129526023/9846434887'; // Android Reward Production ID
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-4676075129526023/3221316784'; // iOS Reward Production ID
      }
    }

    // Debug & Profile Test IDs
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Rewarded Test ID
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // Android Rewarded Test ID
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

  /// Show Confirmation Dialog, load Rewarded Ad with loading indicator, and activate 3-minute trial on reward.
  Future<void> showRewardedTrialFlow(
    BuildContext context, {
    VoidCallback? onSuccess,
  }) async {
    HapticHelper.mediumImpact();

    // 1. Confirmation Modal First (Styled with exact width, height, and card layout as PRO Exclusive Feature)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(
                    AppColors.palette.isLight ? 45 : 30,
                  ),
                ),
                child: Icon(
                  Icons.ondemand_video_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                IapService.instance.isTrialActive
                    ? 'Extend Free Trial (+3 Mins)'
                    : '3-Minute Free Trial',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                IapService.instance.isTrialActive
                    ? 'Watch a short sponsored video to add 3 more minutes to your active session.'
                    : 'Watch a short sponsored video to unlock full access to the Virtual Gamepad & Joystick for 3 minutes for free. You can use this anytime!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  IapService.instance.isTrialActive
                      ? 'Watch Video (+3 Mins)'
                      : 'Watch Video & Unlock',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 2. Show Loading Dialog
    isSuppressingAppOpenAd = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'Loading reward video...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 3. Request Rewarded Ad with timeout
    RewardedAd? loadedAd;
    try {
      final completer = Completer<RewardedAd?>();

      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('RewardedAd failed to load: $error');
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );

      loadedAd = await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('Exception while loading rewarded ad: $e');
      loadedAd = null;
    }

    // Dismiss Loading Dialog
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // 4. If ad is not filled, show unavailable modal
    if (loadedAd == null) {
      isSuppressingAppOpenAd = false;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.warning.withAlpha(160),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withAlpha(35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withAlpha(
                        AppColors.palette.isLight ? 45 : 30,
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ad Unavailable',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An ad is currently not available. Please try again later.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    // 5. If filled, show Rewarded Ad & apply trial on reward
    bool userEarnedReward = false;

    loadedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isSuppressingAppOpenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        Future.delayed(const Duration(seconds: 2), () {
          isSuppressingAppOpenAd = false;
        });

        if (userEarnedReward) {
          onSuccess?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        isSuppressingAppOpenAd = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to play reward video. Please try again.'),
            ),
          );
        }
      },
    );

    loadedAd.show(
      onUserEarnedReward: (ad, reward) {
        userEarnedReward = true;
        IapService.instance.startFreeTrial(durationSeconds: 180);
      },
    );
  }
}
