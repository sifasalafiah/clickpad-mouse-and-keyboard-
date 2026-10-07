import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/bluetooth_pairing_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ad_service.dart';
import 'services/connection_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep screen awake (prevent auto-lock/sleep while using touchpad/keyboard)
  try {
    await WakelockPlus.enable();
  } catch (e) {
    debugPrint('Wakelock error: $e');
  }

  // Initialize persistent settings, connection, IAP, and AdMob services
  await SettingsService.instance.init();
  await IapService.instance.init();
  ConnectionService.instance.init();
  await AdService.instance.init();

  runApp(const ClickPadApp());
}

class ClickPadApp extends StatelessWidget {
  const ClickPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickPad - PC Mouse & Keyboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppRootWrapper(),
    );
  }
}

class AppRootWrapper extends StatefulWidget {
  const AppRootWrapper({super.key});

  @override
  State<AppRootWrapper> createState() => _AppRootWrapperState();
}

class _AppRootWrapperState extends State<AppRootWrapper> {
  final ConnectionService _connService = ConnectionService.instance;

  @override
  void initState() {
    super.initState();
    _connService.addListener(_onConnectionStatusChanged);

    // Show App Open Ad if loaded after initial rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.showAppOpenAdIfAvailable();
    });
  }

  @override
  void dispose() {
    _connService.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }

  void _onConnectionStatusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to MainNavigationScreen (Touchpad) when connected to PC.
    // Return to BluetoothPairingScreen when disconnected from PC.
    if (_connService.isConnected) {
      return const MainNavigationScreen();
    } else {
      return const BluetoothPairingScreen();
    }
  }
}
