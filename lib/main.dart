import 'package:flutter/material.dart';
import 'screens/bluetooth_pairing_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ad_service.dart';
import 'services/connection_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent settings, connection, and AdMob services
  await SettingsService.instance.init();
  ConnectionService.instance.init();
  await AdService.instance.init();

  runApp(const ClickPadApp());
}

class ClickPadApp extends StatelessWidget {
  const ClickPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickPad - Mouse & Keyboard Controller',
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
    // Only navigate to Main Navigation Screen (with Navbar) once a device is successfully paired & connected
    if (_connService.isConnected) {
      return const MainNavigationScreen();
    } else {
      return const BluetoothPairingScreen();
    }
  }
}
