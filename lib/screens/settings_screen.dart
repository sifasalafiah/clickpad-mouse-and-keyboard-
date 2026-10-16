import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import '../services/ad_service.dart';
import '../services/bluetooth_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/gamepad_layout_editor.dart';
import '../widgets/gamepad_remapping_modal.dart';
import '../widgets/pro_purchase_modal.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final IapService _iapService = IapService.instance;
  String _appVersion = '0.1.0(1)';

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _iapService.addListener(_onSettingsChanged);
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final yamlContent = await rootBundle.loadString('pubspec.yaml');
      final match = RegExp(
        r'^version:\s*([^\s+]+)(?:\+(\d+))?',
        multiLine: true,
      ).firstMatch(yamlContent);
      if (match != null) {
        final ver = match.group(1);
        final build = match.group(2);
        if (ver != null) {
          final formatted = (build != null && build.isNotEmpty)
              ? '$ver($build)'
              : ver;
          if (mounted) {
            setState(() {
              _appVersion = formatted;
            });
            return;
          }
        }
      }
    } catch (_) {}

    try {
      final info = await PackageInfo.fromPlatform();
      var ver = info.version;
      var build = info.buildNumber;
      if (ver.contains('+')) {
        final parts = ver.split('+');
        ver = parts[0];
        if (build.isEmpty && parts.length > 1) {
          build = parts[1];
        }
      }
      final formatted = build.isNotEmpty ? '$ver($build)' : ver;
      if (mounted) {
        setState(() {
          _appVersion = formatted;
        });
      }
    } catch (_) {}
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

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Card(
      color: AppColors.surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withAlpha(100)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider({double indent = 0, double endIndent = 0}) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: AppColors.border.withAlpha(70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _iapService.isPro;
    final isJoystickOnly = _iapService.isJoystickUnlocked && !_iapService.isPro;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ClickPad PRO Membership Card
          Card(
            color: isPro
                ? (AppColors.palette.isLight
                      ? AppColors.surface
                      : const Color(0xFF151C2C))
                : (AppColors.palette.isLight
                      ? AppColors.surface
                      : AppColors.surfaceElevated),
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: (isPro || isJoystickOnly)
                    ? const Color(0xFFFFD700)
                    : AppColors.primary,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isPro || isJoystickOnly)
                          ? const Color(
                              0xFFFFD700,
                            ).withAlpha(AppColors.palette.isLight ? 45 : 30)
                          : AppColors.primary.withAlpha(30),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: (isPro || isJoystickOnly)
                          ? (AppColors.palette.isLight
                                ? const Color(0xFFB45309)
                                : const Color(0xFFFFD700))
                          : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro
                              ? 'ClickPad PRO Active'
                              : (isJoystickOnly
                                    ? 'Joystick Pass Active'
                                    : 'Upgrade to ClickPad PRO'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (isPro || isJoystickOnly)
                                ? (AppColors.palette.isLight
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFFFFD700))
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPro
                              ? '100% Ad-Free, Virtual Gamepad, & Full Tools Unlocked'
                              : (isJoystickOnly
                                    ? 'Virtual Gamepad Unlocked • Upgrade to PRO for 100% Ad-Free & Tools'
                                    : 'Unlock Virtual Gamepad, 100% Ad-Free, & Full Tools'),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        HapticHelper.mediumImpact();
                        ProPurchaseModal.show(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isJoystickOnly ? 'Upgrade PRO' : 'Upgrade',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Bluetooth HID Status Card (1 Card with Sekat)
          _buildSectionHeader('Bluetooth Connection Profile'),
          _buildSectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bluetooth_connected,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Native Bluetooth HID Hardware Emulation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your smartphone acts as a physical Bluetooth Mouse & Keyboard hardware device. Zero software or scripts required on your PC or Mac.',
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
              _buildDivider(),
              InkWell(
                onTap: () => _bleService.openSystemBluetoothSettings(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_bluetooth,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Phone Bluetooth Settings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Appearance (1 Card with Dark / Light Mode Switch)
          _buildThemeSection(),
          const SizedBox(height: 20),

          // 4. Mouse & Touchpad Controls (1 Card with Sekat between each control)
          _buildSectionHeader('Touchpad & Input Tuning'),
          _buildSectionCard(
            children: [
              // Mouse Sensitivity Slider
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mouse Sensitivity',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
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
                    const SizedBox(height: 4),
                    Slider(
                      value: _settings.mouseSensitivity,
                      min: 0.5,
                      max: 4.0,
                      divisions: 35,
                      onChanged: (val) => _settings.setMouseSensitivity(val),
                    ),
                  ],
                ),
              ),
              _buildDivider(indent: 16, endIndent: 16),

              // Scroll Sensitivity Slider
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scroll Speed',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
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
                    const SizedBox(height: 4),
                    Slider(
                      value: _settings.scrollSensitivity,
                      min: 0.5,
                      max: 4.0,
                      divisions: 35,
                      onChanged: (val) => _settings.setScrollSensitivity(val),
                    ),
                  ],
                ),
              ),
              _buildDivider(indent: 16, endIndent: 16),

              // Acceleration Switch
              SwitchListTile(
                value: _settings.enableAcceleration,
                onChanged: (val) => _settings.setEnableAcceleration(val),
                activeThumbColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                title: const Text(
                  'Cursor Acceleration',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(
                  'Speeds up cursor when flicking finger quickly',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              _buildDivider(indent: 16, endIndent: 16),

              // Haptics Switch
              SwitchListTile(
                value: _settings.enableHaptics,
                onChanged: (val) => _settings.setEnableHaptics(val),
                activeThumbColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                title: const Text(
                  'Tactile Haptic Feedback',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                subtitle: Text(
                  'Vibrates on taps, clicks, and key presses',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Gamepad & Controller (1 Card with Sekat)
          _buildSectionHeader('Gamepad & Controller'),
          _buildSectionCard(
            children: [
              InkWell(
                onTap: () {
                  GamepadLayoutEditorScreen.open(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.dashboard_customize,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customize HUD Layout & Sizes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reposition and resize joystick & buttons directly on screen (PUBG style)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              _buildDivider(indent: 62),
              InkWell(
                onTap: () {
                  GamepadRemappingModal.show(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.tune,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customize Button Remapping',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Remap gamepad buttons (ABXY, Shoulders, D-Pad) to any PC key',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6. Privacy & Advertising Consent Card (Only visible for Free / Ad-Supported users, 1 Card with Sekat)
          if (!isPro) ...[
            _buildSectionHeader('Privacy'),
            _buildSectionCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GDPR & US State Advertising Privacy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your consent preferences for personalized ads, measurement, and privacy under European GDPR / UK regulations and US State Privacy laws.',
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
                _buildDivider(),
                InkWell(
                  onTap: () {
                    HapticHelper.selectionClick();
                    AdService.instance.showPrivacyOptionsForm(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Change Privacy & Consent Choices',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // 7. Help & About (1 Card with Sekat)
          _buildSectionHeader('Help & About'),
          _buildSectionCard(
            children: [
              InkWell(
                onTap: () {
                  HapticHelper.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const OnboardingScreen(isRevisit: true),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.primaryLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Feature Guide & Onboarding',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Review walkthrough for touchpad, keyboard, & PC connection',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              _buildDivider(indent: 62),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ClickPad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _appVersion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    final isDark = _settings.currentThemeMode == AppThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance'),
        _buildSectionCard(
          children: [
            SwitchListTile(
              value: isDark,
              onChanged: (val) {
                HapticHelper.selectionClick();
                _settings.setThemeMode(
                  val ? AppThemeMode.dark : AppThemeMode.light,
                );
              },
              activeThumbColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFFF59E0B) : AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                isDark
                    ? 'Midnight Slate dark theme'
                    : 'Crisp Slate light theme',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
