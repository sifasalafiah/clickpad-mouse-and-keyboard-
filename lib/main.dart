import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/bluetooth_pairing_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
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

  // Initialize persistent settings, connection, and IAP
  await SettingsService.instance.init();
  await IapService.instance.init();
  ConnectionService.instance.init();

  runApp(const ClickPadApp());
}

class ClickPadApp extends StatelessWidget {
  const ClickPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final currentMode = SettingsService.instance.currentThemeMode;
        return MaterialApp(
          title: 'ClickPad - PC Mouse & Keyboard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(currentMode),
          home: const AppRootWrapper(),
        );
      },
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
  final SettingsService _settings = SettingsService.instance;
  bool _adServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _connService.addListener(_onStateChanged);
    _settings.addListener(_onStateChanged);

    // Only initialize AdMob and GDPR consent if onboarding is already completed
    if (_settings.hasSeenOnboarding) {
      _initAdService();
    }
  }

  void _initAdService() {
    if (_adServiceInitialized) return;
    _adServiceInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AdService.instance.init();
      AdService.instance.showAppOpenAdIfAvailable();
    });
  }

  @override
  void dispose() {
    _connService.removeListener(_onStateChanged);
    _settings.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    // If onboarding just finished, initialize AdService now
    if (_settings.hasSeenOnboarding && !_adServiceInitialized) {
      _initAdService();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show onboarding screen on first install
    if (!_settings.hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // 2. Navigate to MainNavigationScreen (Touchpad) when connected to PC.
    // Return to BluetoothPairingScreen when disconnected from PC.
    if (_connService.isConnected) {
      return const MainNavigationScreen();
    } else {
      return const BluetoothPairingScreen();
    }
  }
}
