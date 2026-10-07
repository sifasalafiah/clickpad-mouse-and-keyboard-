import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IapService extends ChangeNotifier {
  static final IapService instance = IapService._internal();
  IapService._internal();

  static const String proLifetimeId = 'clickpad_pro_lifetime';
  static const String joystickPassId = 'clickpad_joystick_pass';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPro = false;
  bool _isJoystickUnlocked = false;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isLoading = false;

  // Demo Trial State
  bool _isTrialActive = false;
  int _trialSecondsLeft = 0;
  bool _hasUsedTrial = false;
  Timer? _trialTimer;

  bool get isPro => _isPro || _isJoystickUnlocked || _isTrialActive;
  bool get isProLifetime => _isPro;
  bool get isJoystickUnlocked => _isJoystickUnlocked || _isPro;
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get isLoading => _isLoading;
  bool get isTrialActive => _isTrialActive;
  int get trialSecondsLeft => _trialSecondsLeft;
  bool get hasUsedTrial => _hasUsedTrial;
  bool get canStartTrial => !_hasUsedTrial && !_isPro && !_isJoystickUnlocked;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('isProUnlocked') ?? false;
    _isJoystickUnlocked = prefs.getBool('isJoystickUnlocked') ?? false;
    _hasUsedTrial = prefs.getBool('hasUsedTrial') ?? false;

    // Check if active trial is still running from previous session
    final trialEndTime = prefs.getInt('trialEndTime') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (trialEndTime > now) {
      final remaining = ((trialEndTime - now) / 1000).ceil();
      _startTrialTimer(remaining);
    } else if (trialEndTime > 0) {
      _hasUsedTrial = true;
      await prefs.setBool('hasUsedTrial', true);
    }

    notifyListeners();

    // Check store availability
    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _onPurchaseUpdated,
          onDone: () => _subscription?.cancel(),
          onError: (error) {
            debugPrint('IAP Stream Error: $error');
          },
        );
        await queryProducts();
      }
    } catch (e) {
      debugPrint('IAP Init Exception: $e');
    }
  }

  Future<void> queryProducts() async {
    if (!_isAvailable) return;

    _isLoading = true;
    notifyListeners();

    try {
      const Set<String> ids = {proLifetimeId, joystickPassId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

      if (response.error == null) {
        _products = response.productDetails;
      } else {
        debugPrint('Query Product Error: ${response.error}');
      }
    } catch (e) {
      debugPrint('queryProducts Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _isLoading = false;
          debugPrint('Purchase Error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _deliverProduct(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
        _isLoading = false;
      }
    }
    notifyListeners();
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final prefs = await SharedPreferences.getInstance();
    if (purchaseDetails.productID == proLifetimeId) {
      _isPro = true;
      await prefs.setBool('isProUnlocked', true);
    } else if (purchaseDetails.productID == joystickPassId) {
      _isJoystickUnlocked = true;
      await prefs.setBool('isJoystickUnlocked', true);
    }
    notifyListeners();
  }

  // Buy Real Product via Store
  Future<bool> buyProduct(ProductDetails productDetails) async {
    _isLoading = true;
    notifyListeners();

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('buyProduct Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Restore Store Purchases
  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isAvailable) {
        await _iap.restorePurchases();
      }
    } catch (e) {
      debugPrint('restorePurchases Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Instant Unlock for Testing / Sandbox / Demo
  Future<void> unlockProSimulated({bool joystickOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (joystickOnly) {
      _isJoystickUnlocked = true;
      await prefs.setBool('isJoystickUnlocked', true);
    } else {
      _isPro = true;
      _isJoystickUnlocked = true;
      await prefs.setBool('isProUnlocked', true);
      await prefs.setBool('isJoystickUnlocked', true);
    }
    notifyListeners();
  }

  // Start 3-Minute Free Trial (One-Time Only)
  bool startFreeTrial({int durationSeconds = 180}) {
    if (_hasUsedTrial || isPro) return false;

    _hasUsedTrial = true;
    _startTrialTimer(durationSeconds);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasUsedTrial', true);
      final endTime = DateTime.now().millisecondsSinceEpoch + (durationSeconds * 1000);
      prefs.setInt('trialEndTime', endTime);
    });

    return true;
  }

  void _startTrialTimer(int durationSeconds) {
    _trialTimer?.cancel();
    _isTrialActive = true;
    _trialSecondsLeft = durationSeconds;
    notifyListeners();

    _trialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trialSecondsLeft > 1) {
        _trialSecondsLeft--;
        notifyListeners();
      } else {
        _isTrialActive = false;
        _trialSecondsLeft = 0;
        _hasUsedTrial = true;
        _trialTimer?.cancel();
        notifyListeners();
      }
    });
  }

  // Reset Trial (for testing / debug)
  Future<void> resetTrialForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasUsedTrial');
    await prefs.remove('trialEndTime');
    _hasUsedTrial = false;
    _isTrialActive = false;
    _trialSecondsLeft = 0;
    _trialTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _trialTimer?.cancel();
    super.dispose();
  }
}
