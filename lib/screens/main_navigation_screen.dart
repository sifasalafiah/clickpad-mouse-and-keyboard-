import 'package:flutter/material.dart';
import '../services/connection_service.dart';
import '../services/iap_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/pro_purchase_modal.dart';
import 'joystick_screen.dart';
import 'keyboard_screen.dart';
import 'settings_screen.dart';
import 'touchpad_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ConnectionService _connService = ConnectionService.instance;
  final IapService _iapService = IapService.instance;

  final List<Widget> _screens = const [
    TouchpadScreen(),
    KeyboardScreen(),
    JoystickScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _connService.addListener(_onStateChanged);
    _iapService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _connService.removeListener(_onStateChanged);
    _iapService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connService.isConnected;
    final device = _connService.connectedDevice;
    final isPro = _iapService.isPro;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bluetooth,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ClickPad',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'PC Mouse & Keyboard',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // PRO Upgrade Crown Button (if not unlocked)
          if (!isPro)
            IconButton(
              onPressed: () {
                HapticHelper.mediumImpact();
                ProPurchaseModal.show(context);
              },
              icon: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFFFD700),
                size: 22,
              ),
              tooltip: 'Unlock PRO',
            ),

          // Connection Status Pill Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                HapticHelper.selectionClick();
                _showDisconnectConfirmationDialog(context);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.success.withAlpha(30)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected ? AppColors.success : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.bluetooth,
                      size: 14,
                      color: isConnected
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 95),
                      child: Text(
                        isConnected
                            ? (device?.name ?? 'Connected')
                            : 'Connected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isConnected
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          HapticHelper.selectionClick();
          setState(() => _currentIndex = index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.touch_app_outlined),
            activeIcon: Icon(Icons.touch_app),
            label: 'Touchpad',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.keyboard_outlined),
            activeIcon: Icon(Icons.keyboard),
            label: 'Keyboard',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sports_esports_outlined),
                if (!isPro)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.sports_esports),
            label: 'Joystick',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showDisconnectConfirmationDialog(BuildContext context) {
    final deviceName = _connService.connectedDevice?.name ?? 'Desktop';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Disconnect?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to disconnect Bluetooth HID connection with $deviceName?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _connService.disconnect();
            },
            icon: const Icon(Icons.link_off, size: 16),
            label: const Text('Disconnect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
