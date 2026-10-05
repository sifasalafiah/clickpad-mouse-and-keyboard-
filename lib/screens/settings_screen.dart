import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bluetooth HID Status Card
          const Text('Bluetooth Connection Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bluetooth_connected, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Native Bluetooth HID Hardware Emulation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      onPressed: () => _bleService.openSystemBluetoothSettings(),
                      icon: const Icon(Icons.settings_bluetooth, size: 18),
                      label: const Text('Open Phone Bluetooth Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mouse & Touchpad Controls
          const Text('Touchpad & Input Tuning', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                      const Text('Mouse Sensitivity', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('${_settings.mouseSensitivity.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
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
                      const Text('Scroll Speed', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('${_settings.scrollSensitivity.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
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
                    title: const Text('Cursor Acceleration', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Speeds up cursor when flicking finger quickly', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const Divider(color: AppColors.border, height: 12),

                  // Haptics Switch
                  SwitchListTile(
                    value: _settings.enableHaptics,
                    onChanged: (val) => _settings.setEnableHaptics(val),
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tactile Haptic Feedback', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text('Vibrates on taps, clicks, and key presses', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // About Card
          Card(
            color: AppColors.surfaceElevated,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DeskRemote Bluetooth HID v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Seamless Bluetooth Mouse & Keyboard controller for macOS, Windows, and Linux.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
}
