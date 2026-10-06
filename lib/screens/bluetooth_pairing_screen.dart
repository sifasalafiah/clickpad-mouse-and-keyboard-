import 'package:flutter/material.dart';
import '../models/connection_type.dart';
import '../models/device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({super.key});

  @override
  State<BluetoothPairingScreen> createState() => _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen>
    with SingleTickerProviderStateMixin {
  final ConnectionService _connService = ConnectionService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final SettingsService _settings = SettingsService.instance;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _selectedPlatformTab =
      0; // 0: macOS, 1: Windows, 2: Linux, 3: iPad/Tablet

  @override
  void initState() {
    super.initState();

    _connService.addListener(_onConnectionChanged);

    // Pulsing radar animation for "Waiting Connection" state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bleService.makeDiscoverable();
  }

  @override
  void dispose() {
    _connService.removeListener(_onConnectionChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onConnectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = _connService.status;
    final isConnecting =
        status == ConnectionStateStatus.connecting ||
        status == ConnectionStateStatus.pairing;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.bluetooth,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ClickPad',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'PC Mouse & Keyboard',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _bleService.openSystemBluetoothSettings(),
                    icon: const Icon(Icons.settings_bluetooth, size: 16),
                    label: const Text(
                      'BT Settings',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Last Connected Device Quick Reconnect Card
              if (_settings.hasLastConnectedDevice && !isConnecting) ...[
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: AppColors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history,
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
                                  'LAST CONNECTED DEVICE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _settings.lastDeviceName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticHelper.mediumImpact();
                              _connService.connect(
                                DiscoveredDevice(
                                  id: _settings.lastDeviceId,
                                  name: _settings.lastDeviceName,
                                  type: ConnectionType.bluetoothHid,
                                ),
                              );
                            },
                            icon: const Icon(Icons.bolt, size: 16),
                            label: const Text(
                              'Connect',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Connection Failed Alert Card
              if (status == ConnectionStateStatus.failed && !isConnecting) ...[
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: AppColors.error.withAlpha(25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.error.withAlpha(120),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Connection Failed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _connService.statusMessage ??
                                      'Could not connect. Please make sure Bluetooth is ON on your computer.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_settings.hasLastConnectedDevice) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                HapticHelper.mediumImpact();
                                _connService.connect(
                                  DiscoveredDevice(
                                    id: _settings.lastDeviceId,
                                    name: _settings.lastDeviceName,
                                    type: ConnectionType.bluetoothHid,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: AppColors.error,
                              ),
                              label: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Dynamic Main Card (Connecting Loading vs Waiting Radar)
              if (isConnecting) ...[
                // Loading State Card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: AppColors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Connecting to ${_settings.lastDeviceName.isNotEmpty ? _settings.lastDeviceName : "Desktop"}...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _connService.statusMessage ??
                                'Establishing Bluetooth HID connection...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticHelper.selectionClick();
                              _connService.disconnect();
                            },
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text(
                              'Cancel Connection',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Radar Pulsing Waiting Screen
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: AppColors.surfaceElevated,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Animated Pulsing Beacon Icon
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withAlpha(30),
                                border: Border.all(
                                  color: AppColors.primaryLight,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(60),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bluetooth_searching,
                                size: 42,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Waiting for Bluetooth Connection...',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sensors,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'BT Name: ClickPad',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Instruction Tabs Header for macOS, Windows, Linux, Tablet
              const Text(
                'How to Connect on Your Device',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPlatformChip(0, 'macOS', Icons.apple),
                    const SizedBox(width: 8),
                    _buildPlatformChip(1, 'Windows', Icons.window),
                    const SizedBox(width: 8),
                    _buildPlatformChip(2, 'Linux', Icons.terminal),
                    const SizedBox(width: 8),
                    _buildPlatformChip(3, 'iPad / Tablet', Icons.tablet_mac),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Step-by-Step Instructions Card
              Card(
                color: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildInstructionContent(_selectedPlatformTab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformChip(int index, String label, IconData icon) {
    final isSelected = _selectedPlatformTab == index;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        HapticHelper.selectionClick();
        setState(() => _selectedPlatformTab = index);
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.textMuted,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primaryLight : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildInstructionContent(int tabIndex) {
    switch (tabIndex) {
      case 0: // macOS
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepRow(
              number: '1',
              title: 'Open macOS System Settings',
              desc: 'Click Apple Menu -> System Settings -> Bluetooth.',
            ),
            _StepRow(
              number: '2',
              title: 'Look Under "Nearby Devices"',
              desc: 'Wait for "ClickPad Mouse" to appear.',
            ),
            _StepRow(
              number: '3',
              title: 'Click Connect & Pair',
              desc:
                  'Accept the Bluetooth pairing prompt. App unlocks automatically!',
            ),
          ],
        );
      case 1: // Windows 10/11
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepRow(
              number: '1',
              title: 'Open Windows Settings',
              desc: 'Press Win + I -> Bluetooth & Devices.',
            ),
            _StepRow(
              number: '2',
              title: 'Click Add Device',
              desc: 'Choose "Bluetooth" (Mice, keyboards, pens, etc.).',
            ),
            _StepRow(
              number: '3',
              title: 'Select ClickPad Mouse',
              desc: 'Click "ClickPad Mouse" to pair & connect.',
            ),
          ],
        );
      case 2: // Linux
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepRow(
              number: '1',
              title: 'Open Bluetooth Manager',
              desc: 'Open Settings -> Bluetooth or Blueman Manager.',
            ),
            _StepRow(
              number: '2',
              title: 'Scan Nearby Devices',
              desc: 'Search for "ClickPad Mouse".',
            ),
            _StepRow(
              number: '3',
              title: 'Click Pair & Connect',
              desc: 'Accept pairing request to start controlling Linux.',
            ),
          ],
        );
      case 3: // iPad / Android Tablet
      default:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepRow(
              number: '1',
              title: 'Open Settings',
              desc: 'Go to Settings -> Bluetooth on your iPad / Tablet.',
            ),
            _StepRow(
              number: '2',
              title: 'Other Devices',
              desc: 'Look for "ClickPad Mouse" under Other Devices.',
            ),
            _StepRow(
              number: '3',
              title: 'Tap to Pair',
              desc: 'Tap to pair. Touchpad & Keyboard will activate instantly!',
            ),
          ],
        );
    }
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _StepRow({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withAlpha(40),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
