import 'package:flutter/material.dart';
import '../services/iap_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class ProPurchaseModal extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const ProPurchaseModal({super.key, this.onUnlocked});

  static void show(BuildContext context, {VoidCallback? onUnlocked}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProPurchaseModal(onUnlocked: onUnlocked),
    );
  }

  @override
  State<ProPurchaseModal> createState() => _ProPurchaseModalState();
}

class _ProPurchaseModalState extends State<ProPurchaseModal> {
  final IapService _iapService = IapService.instance;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIapChanged);
    super.dispose();
  }

  void _onIapChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.88),
      decoration: BoxDecoration(
        color: const Color(0xFF14171D),
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
              color: Colors.white24,
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
                  const Text(
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
                  _buildPricingCard(
                    title: 'Pro Lifetime Pass',
                    badge: 'BEST VALUE',
                    price: 'Rp 29.000',
                    subtitle: 'One-time purchase, unlock all features forever',
                    isPrimary: true,
                    onTap: () => _handleUnlock(isLifetime: true),
                  ),
                  const SizedBox(height: 10),
                  _buildPricingCard(
                    title: 'Joystick Game Pass Only',
                    price: 'Rp 15.000',
                    subtitle: 'Dedicated to Virtual Gamepad & Controller features',
                    isPrimary: false,
                    onTap: () => _handleUnlock(isLifetime: false),
                  ),
                  const SizedBox(height: 16),

                  // Free Demo / Trial Button (Single-use only)
                  if (_iapService.canStartTrial) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticHelper.mediumImpact();
                        final started = _iapService.startFreeTrial(durationSeconds: 180);
                        if (started) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 3-Minute Free Trial Active! Enjoy testing the Joystick.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          widget.onUnlocked?.call();
                        }
                      },
                      icon: const Icon(Icons.timer, color: Color(0xFF00E5FF), size: 18),
                      label: const Text(
                        'Try 3-Minute Free Trial',
                        style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_iapService.hasUsedTrial && !_iapService.isPro) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_clock, color: AppColors.textMuted, size: 16),
                          SizedBox(width: 8),
                          Text(
                            '3-Minute Free Trial has already been used',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase status has been updated.')),
                        );
                      }
                    },
                    child: const Text(
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
          color: isPrimary ? AppColors.primary.withAlpha(30) : const Color(0xFF1E222A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppColors.primary : const Color(0xFF2E3542),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                color: isPrimary ? const Color(0xFF00E5FF) : Colors.white,
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

    await _iapService.unlockProSimulated(joystickOnly: !isLifetime);

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLifetime
                ? '🎉 ClickPad PRO Successfully Activated! Enjoy playing.'
                : '🎮 Joystick Pass Successfully Activated!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onUnlocked?.call();
    }
  }
}
