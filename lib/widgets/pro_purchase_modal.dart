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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        reverseDuration: const Duration(milliseconds: 250),
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
  late final bool _initiallyHadPro;
  late final bool _initiallyHadJoystick;

  @override
  void initState() {
    super.initState();
    _initiallyHadPro = _iapService.isPro;
    _initiallyHadJoystick = _iapService.isJoystickUnlocked;
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
    // Only auto-close if newly unlocked during this session
    if (_iapService.isPro && !_initiallyHadPro) {
      _safeClose(
        successMessage:
            '🎉 ClickPad PRO Lifetime Successfully Activated! All features & Ad-Free unlocked.',
      );
      return;
    } else if (_iapService.isJoystickUnlocked && !_initiallyHadJoystick) {
      _safeClose(
        successMessage:
            '🎮 Joystick Game Pass Successfully Activated! Virtual Gamepad unlocked.',
      );
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            children: [
              // 1. Top Bar with Close 'X' Button on Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFD700,
                      ).withAlpha(AppColors.palette.isLight ? 35 : 25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withAlpha(120),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'PREMIUM PASS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.palette.isLight
                                ? const Color(0xFFB45309)
                                : const Color(0xFFFFD700),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticHelper.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    tooltip: 'Close',
                    splashRadius: 22,
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // 2. Crown Hero Icon & Title
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFFFFD700,
                  ).withAlpha(AppColors.palette.isLight ? 35 : 25),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFFFD700),
                  size: 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ClickPad PRO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Unlock all features with zero ads forever',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              // 3. Rich Feature Checklist Card (With Icons & Subtitles)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildFeatureTile(
                      Icons.sports_esports_rounded,
                      'Virtual Gamepad & Joystick',
                      '360° Analog Stick, D-Pad, and responsive ABXY buttons',
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureTile(
                      Icons.handyman_rounded,
                      'Complete Desktop Tools',
                      'Macro Deck, Mouse Jiggler, Numpad, & Media Remote',
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureTile(
                      Icons.dashboard_customize_rounded,
                      'Custom Layout & Remapping',
                      'Freely reposition, resize, and personalize controls',
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureTile(
                      Icons.block_rounded,
                      '100% Ad-Free Experience',
                      'Zero banners or popup interruptions forever',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 4. Pricing Options Cards
              Builder(
                builder: (context) {
                  final proProduct = _iapService.products
                      .cast<ProductDetails?>()
                      .firstWhere(
                        (p) => p?.id == IapService.proLifetimeId,
                        orElse: () => null,
                      );
                  final joystickProduct = _iapService.products
                      .cast<ProductDetails?>()
                      .firstWhere(
                        (p) => p?.id == IapService.joystickPassId,
                        orElse: () => null,
                      );

                  final isStoreLoading = _iapService.isLoading;
                  final proPrice =
                      proProduct?.price ?? (isStoreLoading ? '...' : '-');
                  final joystickPrice =
                      joystickProduct?.price ?? (isStoreLoading ? '...' : '-');
                  final isJoystickOwned =
                      _iapService.isJoystickUnlocked && !_iapService.isPro;

                  return Column(
                    children: [
                      _buildPricingCard(
                        title: isJoystickOwned
                            ? 'Upgrade to Pro Lifetime'
                            : 'Pro Lifetime Pass',
                        badge: isJoystickOwned ? 'NO ADS' : 'BEST VALUE',
                        price: proPrice,
                        subtitle: isJoystickOwned
                            ? 'Remove all ads forever & unlock complete tools'
                            : 'One-time purchase, unlock all features forever',
                        isPrimary: true,
                        onTap: () => _handleUnlock(isLifetime: true),
                      ),
                      const SizedBox(height: 8),
                      _buildPricingCard(
                        title: 'Joystick Game Pass Only',
                        badge: isJoystickOwned ? 'OWNED' : null,
                        price: isJoystickOwned ? 'Active' : joystickPrice,
                        subtitle: isJoystickOwned
                            ? 'Already unlocked on this device'
                            : 'Dedicated Virtual Gamepad Controller access',
                        isPrimary: false,
                        isOwned: isJoystickOwned,
                        onTap: isJoystickOwned
                            ? null
                            : () => _handleUnlock(isLifetime: false),
                      ),
                    ],
                  );
                },
              ),

              const Spacer(flex: 1),

              // 5. Free Demo / Trial Button (Watch Reward Ad)
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
                  icon: Icon(
                    Icons.ondemand_video_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: Text(
                    _iapService.isTrialActive
                        ? 'Extend Free Trial (+3 Min Free)'
                        : 'Watch Video for 3-Min Free Trial',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 42),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // 6. Restore Purchases Button
              TextButton(
                onPressed: () async {
                  HapticHelper.selectionClick();
                  await _iapService.restorePurchases();
                  if (context.mounted) {
                    if (_iapService.isPro) {
                      _safeClose(
                        successMessage:
                            '🎉 ClickPad PRO Lifetime successfully restored!',
                      );
                    } else if (_iapService.isJoystickUnlocked) {
                      _safeClose(
                        successMessage:
                            '🎮 Joystick Game Pass successfully restored!',
                      );
                    } else {
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
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(
                AppColors.palette.isLight ? 20 : 30,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withAlpha(
                  AppColors.palette.isLight ? 45 : 55,
                ),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    VoidCallback? onTap,
    bool isOwned = false,
  }) {
    final isInteractive = onTap != null && !_isProcessing;
    return InkWell(
      onTap: isInteractive ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isOwned ? 0.75 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.primary.withAlpha(
                    AppColors.palette.isLight ? 25 : 30,
                  )
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOwned
                                  ? AppColors.success.withAlpha(35)
                                  : const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(6),
                              border: isOwned
                                  ? Border.all(
                                      color: AppColors.success,
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isOwned
                                    ? AppColors.success
                                    : Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
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
                  color: isOwned
                      ? AppColors.success
                      : (isPrimary ? AppColors.primary : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUnlock({required bool isLifetime}) async {
    HapticHelper.mediumImpact();
    setState(() => _isProcessing = true);

    final targetId = isLifetime
        ? IapService.proLifetimeId
        : IapService.joystickPassId;
    final storeProduct = _iapService.products
        .cast<ProductDetails?>()
        .firstWhere((p) => p?.id == targetId, orElse: () => null);

    // If Google Play / App Store product is loaded and store is available, trigger real checkout
    if (storeProduct != null && _iapService.isAvailable) {
      final started = await _iapService.buyProduct(storeProduct);
      if (mounted) setState(() => _isProcessing = false);
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start store checkout. Please check Google Play / App Store account.',
            ),
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
