import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/bluetooth_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/pro_purchase_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final IapService _iapService = IapService.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _iapService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _iapService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _iapService.isPro;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ClickPad PRO Membership Card
          Card(
            color: isPro ? const Color(0xFF1E2215) : const Color(0xFF1C1E26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isPro ? const Color(0xFFFFD700) : AppColors.primary,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPro
                          ? const Color(0xFFFFD700).withAlpha(30)
                          : AppColors.primary.withAlpha(30),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: isPro ? const Color(0xFFFFD700) : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro ? 'ClickPad PRO Active' : 'Upgrade to ClickPad PRO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPro ? const Color(0xFFFFD700) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPro
                              ? 'Virtual Gamepad, Zero Ads, & Premium Themes Unlocked'
                              : 'Unlock Joystick Gamepad, Motion Control, & Ad-Free UX',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      HapticHelper.mediumImpact();
                      ProPurchaseModal.show(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPro ? const Color(0xFFFFD700) : AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isPro ? 'Manage' : 'Upgrade',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bluetooth HID Status Card
          const Text(
            'Bluetooth Connection Profile',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bluetooth_connected, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Native Bluetooth HID Hardware Emulation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your smartphone acts as a physical Bluetooth Mouse & Keyboard hardware device. Zero software or scripts required on your PC or Mac.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _bleService.openSystemBluetoothSettings(),
                      icon: const Icon(Icons.settings_bluetooth, size: 18),
                      label: const Text('Open Phone Bluetooth Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Appearance & Exclusive Themes
          _buildThemeSection(isPro),
          const SizedBox(height: 20),

          // Mouse & Touchpad Controls
          const Text(
            'Touchpad & Input Tuning',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mouse Sensitivity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mouse Sensitivity',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_settings.mouseSensitivity.toStringAsFixed(1)}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.mouseSensitivity,
                    min: 0.5,
                    max: 4.0,
                    divisions: 35,
                    onChanged: (val) => _settings.setMouseSensitivity(val),
                  ),
                  const SizedBox(height: 12),

                  // Scroll Sensitivity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scroll Speed',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_settings.scrollSensitivity.toStringAsFixed(1)}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.scrollSensitivity,
                    min: 0.5,
                    max: 4.0,
                    divisions: 35,
                    onChanged: (val) => _settings.setScrollSensitivity(val),
                  ),
                  const SizedBox(height: 12),

                  // Acceleration Switch
                  SwitchListTile(
                    value: _settings.enableAcceleration,
                    onChanged: (val) => _settings.setEnableAcceleration(val),
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Cursor Acceleration',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Speeds up cursor when flicking finger quickly',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Divider(color: AppColors.border, height: 12),

                  // Haptics Switch
                  SwitchListTile(
                    value: _settings.enableHaptics,
                    onChanged: (val) => _settings.setEnableHaptics(val),
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Tactile Haptic Feedback',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Vibrates on taps, clicks, and key presses',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Privacy & GDPR Ad Consent Card
          const Text(
            'Privacy & Legal',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'GDPR & Advertising Privacy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? '100% Ad-Free PRO active. No personalized advertising or tracking cookies are collected.'
                        : 'Manage your consent preferences for personalized ads, measurement, and privacy under European GDPR / UK regulations.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (!isPro) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticHelper.selectionClick();
                          AdService.instance.showPrivacyOptionsForm(context);
                        },
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Change Privacy & Consent Choices'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          HapticHelper.lightImpact();
                          await AdService.instance.resetConsentForDebug();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('GDPR Consent reset! Restart or re-open app to test EEA consent flow.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.restart_alt, size: 16, color: AppColors.textMuted),
                        label: const Text(
                          'Reset GDPR Consent (EEA Debug Test)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // About Card
          Card(
            color: AppColors.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ClickPad',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Seamless Bluetooth Mouse, Keyboard, & Gamepad controller for macOS, Windows, and Linux.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(bool isPro) {
    final currentMode = _settings.currentThemeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Appearance & Themes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700).withAlpha(80)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 12, color: Color(0xFFFFD700)),
                    SizedBox(width: 4),
                    Text(
                      'PRO Themes',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final palette = AppColors.palettes[mode]!;
                final isSelected = currentMode == mode;
                final isLocked = palette.isPro && !isPro;

                return InkWell(
                  onTap: () {
                    if (isLocked) {
                      HapticHelper.mediumImpact();
                      ProPurchaseModal.show(context);
                    } else {
                      HapticHelper.selectionClick();
                      _settings.setThemeMode(mode);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // Color Swatch Preview
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.background,
                            border: Border.all(
                              color: isSelected ? palette.primary : palette.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: palette.primary.withAlpha(100),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    palette.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (palette.isPro) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isLocked
                                            ? const Color(0xFFFFD700).withAlpha(30)
                                            : AppColors.success.withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isLocked ? 'PRO' : 'UNLOCKED',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: isLocked ? const Color(0xFFFFD700) : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                palette.subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Status Indicator
                        if (isLocked)
                          const Icon(Icons.lock_outline, color: Color(0xFFFFD700), size: 18)
                        else if (isSelected)
                          Icon(Icons.check_circle, color: palette.primary, size: 20)
                        else
                          Icon(Icons.radio_button_unchecked, color: AppColors.textMuted.withAlpha(120), size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
