import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class ProPurchaseModal extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const ProPurchaseModal({super.key, this.onUnlocked});

  static void show(BuildContext context, {VoidCallback? onUnlocked}) {
    HapticHelper.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        reverseDuration: const Duration(milliseconds: 350),
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (ctx) => ProPurchaseModal(onUnlocked: onUnlocked),
    );
  }

  @override
  State<ProPurchaseModal> createState() => _ProPurchaseModalState();
}

class _ProPurchaseModalState extends State<ProPurchaseModal> {
  final IapService _iapService = IapService.instance;
  bool _isProcessing = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);
    if (_iapService.products.isEmpty && _iapService.isAvailable) {
      _iapService.queryProducts();
    }
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIapChanged);
    super.dispose();
  }

  void _safeClose({String? successMessage}) {
    if (_hasPopped) return;
    _hasPopped = true;
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      widget.onUnlocked?.call();
      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _onIapChanged() {
    if (!mounted || _hasPopped) return;
    if (_iapService.isPro) {
      _safeClose(
        successMessage:
            '🎉 ClickPad PRO Successfully Activated! Enjoy all features.',
      );
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.88),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Crown Hero Icon & Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(50),
                          const Color(0xFFFFD700).withAlpha(40),
                        ],
                      ),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Color(0xFFFFD700),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFFFFD700)],
                    ).createShader(bounds),
                    child: const Text(
                      'ClickPad PRO',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Unlock All Exclusive Remote PC Features',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Feature Checklist Grid
                  _buildFeatureTile(
                    Icons.sports_esports,
                    'Virtual Gamepad & Joystick',
                    'Play PC games from your couch with 360° Analog Stick, D-Pad, & ABXY',
                  ),
                  _buildFeatureTile(
                    Icons.speed,
                    'Zero-Latency Responsiveness',
                    'Hardware-level Bluetooth HID connection with zero input lag',
                  ),
                  _buildFeatureTile(
                    Icons.motion_photos_on,
                    'Gyroscope Steering (Motion Control)',
                    'Steer racing games or navigate using phone gyroscope motion',
                  ),
                  _buildFeatureTile(
                    Icons.block,
                    '100% Ad-Free Experience',
                    'Stay fully focused without any banners or popup ads',
                  ),
                  _buildFeatureTile(
                    Icons.palette,
                    'Exclusive Themes & OLED Dark Mode',
                    'Access all Pebble themes and save phone battery life',
                  ),
                  const SizedBox(height: 20),

                  // Pricing Options Cards
                  Builder(
                    builder: (context) {
                      final proProduct = _iapService.products.cast<ProductDetails?>().firstWhere(
                        (p) => p?.id == IapService.proLifetimeId,
                        orElse: () => null,
                      );
                      final joystickProduct = _iapService.products.cast<ProductDetails?>().firstWhere(
                        (p) => p?.id == IapService.joystickPassId,
                        orElse: () => null,
                      );

                      final isStoreLoading = _iapService.isLoading;
                      final proPrice = proProduct?.price ?? (isStoreLoading ? '...' : '-');
                      final joystickPrice = joystickProduct?.price ?? (isStoreLoading ? '...' : '-');

                      return Column(
                        children: [
                          _buildPricingCard(
                            title: 'Pro Lifetime Pass',
                            badge: 'BEST VALUE',
                            price: proPrice,
                            subtitle: 'One-time purchase, unlock all features forever',
                            isPrimary: true,
                            onTap: () => _handleUnlock(isLifetime: true),
                          ),
                          const SizedBox(height: 10),
                          _buildPricingCard(
                            title: 'Joystick Game Pass Only',
                            price: joystickPrice,
                            subtitle: 'Dedicated to Virtual Gamepad & Controller features',
                            isPrimary: false,
                            onTap: () => _handleUnlock(isLifetime: false),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Free Demo / Trial Button (Watch Reward Ad)
                  if (_iapService.canStartTrial) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        AdService.instance.showRewardedTrialFlow(
                          context,
                          onSuccess: () {
                            if (mounted) {
                              _safeClose(
                                successMessage: _iapService.isTrialActive
                                    ? '🎉 +3 Minutes added to your Free Trial!'
                                    : '🎉 3-Minute Free Trial Active! Enjoy testing the Joystick.',
                              );
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.ondemand_video_rounded, color: Color(0xFF00E5FF), size: 18),
                      label: Text(
                        _iapService.isTrialActive
                            ? 'Extend Free Trial (+3 Min Free)'
                            : 'Watch Video for 3-Min Free Trial',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Restore Purchases Button
                  TextButton(
                    onPressed: () async {
                      HapticHelper.selectionClick();
                      await _iapService.restorePurchases();
                      if (context.mounted) {
                        if (_iapService.isPro) {
                          _safeClose(
                            successMessage:
                                '🎉 Purchases successfully restored!',
                          );
                        } else {
                          _safeClose();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No previous purchases found to restore.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Restore Purchases',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    String? badge,
    required String price,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withAlpha(AppColors.palette.isLight ? 25 : 30)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isPrimary
                    ? (AppColors.palette.isLight
                        ? AppColors.primary
                        : const Color(0xFF00E5FF))
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUnlock({required bool isLifetime}) async {
    HapticHelper.mediumImpact();
    setState(() => _isProcessing = true);

    final targetId = isLifetime ? IapService.proLifetimeId : IapService.joystickPassId;
    final storeProduct = _iapService.products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == targetId,
      orElse: () => null,
    );

    // If Google Play / App Store product is loaded and store is available, trigger real checkout
    if (storeProduct != null && _iapService.isAvailable) {
      final started = await _iapService.buyProduct(storeProduct);
      if (mounted) setState(() => _isProcessing = false);
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start store checkout. Please check Google Play / App Store account.'),
          ),
        );
      }
      return;
    }

    // Fallback: If running in debug / offline / sandbox simulation without configured store product
    await _iapService.unlockProSimulated(joystickOnly: !isLifetime);

    if (mounted) {
      setState(() => _isProcessing = false);
      _safeClose(
        successMessage: isLifetime
            ? '🎉 ClickPad PRO Successfully Activated! Enjoy playing.'
            : '🎮 Joystick Pass Successfully Activated!',
      );
    }
  }
}
