import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_type.dart';
import '../utils/haptic_helper.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  double _mouseSensitivity = 1.8;
  double _scrollSensitivity = 1.5;
  bool _enableAcceleration = true;
  bool _enableHaptics = true;
  ConnectionType _preferredConnectionType = ConnectionType.bluetoothHid;
  String _lastServerIp = '192.168.1.100';
  int _lastServerPort = 8888;
  String _lastDeviceName = '';

  double get mouseSensitivity => _mouseSensitivity;
  double get scrollSensitivity => _scrollSensitivity;
  bool get enableAcceleration => _enableAcceleration;
  bool get enableHaptics => _enableHaptics;
  ConnectionType get preferredConnectionType => _preferredConnectionType;
  String get lastServerIp => _lastServerIp;
  int get lastServerPort => _lastServerPort;
  String get lastDeviceName => _lastDeviceName;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mouseSensitivity = prefs.getDouble('mouseSensitivity') ?? 1.8;
    _scrollSensitivity = prefs.getDouble('scrollSensitivity') ?? 1.5;
    _enableAcceleration = prefs.getBool('enableAcceleration') ?? true;
    _enableHaptics = prefs.getBool('enableHaptics') ?? true;
    _lastServerIp = prefs.getString('lastServerIp') ?? '192.168.1.100';
    _lastServerPort = prefs.getInt('lastServerPort') ?? 8888;
    _lastDeviceName = prefs.getString('lastDeviceName') ?? '';
    
    final connStr = prefs.getString('preferredConnectionType');
    if (connStr != null) {
      _preferredConnectionType = ConnectionType.values.firstWhere(
        (e) => e.name == connStr,
        orElse: () => ConnectionType.bluetoothHid,
      );
    }
    
    HapticHelper.enabled = _enableHaptics;
    notifyListeners();
  }

  Future<void> setMouseSensitivity(double value) async {
    _mouseSensitivity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mouseSensitivity', value);
  }

  Future<void> setScrollSensitivity(double value) async {
    _scrollSensitivity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('scrollSensitivity', value);
  }

  Future<void> setEnableAcceleration(bool value) async {
    _enableAcceleration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableAcceleration', value);
  }

  Future<void> setEnableHaptics(bool value) async {
    _enableHaptics = value;
    HapticHelper.enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableHaptics', value);
  }

  Future<void> setPreferredConnectionType(ConnectionType type) async {
    _preferredConnectionType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredConnectionType', type.name);
  }

  Future<void> setLastServerInfo(String ip, int port, {String? deviceName}) async {
    _lastServerIp = ip;
    _lastServerPort = port;
    if (deviceName != null) _lastDeviceName = deviceName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastServerIp', ip);
    await prefs.setInt('lastServerPort', port);
    if (deviceName != null) await prefs.setString('lastDeviceName', deviceName);
  }
}
