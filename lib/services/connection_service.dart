import 'package:flutter/widgets.dart';
import '../models/connection_type.dart';
import '../models/device_model.dart';
import '../models/input_command.dart';
import 'bluetooth_service.dart';
import 'settings_service.dart';

class ConnectionService extends ChangeNotifier with WidgetsBindingObserver {
  static final ConnectionService instance = ConnectionService._internal();
  ConnectionService._internal();

  final ConnectionType _activeType = ConnectionType.bluetoothHid;
  ConnectionStateStatus _status = ConnectionStateStatus.disconnected;
  DiscoveredDevice? _connectedDevice;
  String? _statusMessage;
  int _pingMs = 0;

  final BluetoothBleService _bleService = BluetoothBleService.instance;

  ConnectionType get activeType => _activeType;
  ConnectionStateStatus get status => _status;
  DiscoveredDevice? get connectedDevice => _connectedDevice;
  String? get statusMessage => _statusMessage;
  int get pingMs => _pingMs;
  bool get isConnected => _status == ConnectionStateStatus.connected;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _bleService.onStatusChanged = (status, device, msg) {
      if (status == ConnectionStateStatus.disconnected && _status == ConnectionStateStatus.connecting) {
        _status = ConnectionStateStatus.failed;
        _statusMessage = 'Could not connect to ${device?.name ?? "Desktop"}. Please make sure Bluetooth is ON on your computer.';
      } else {
        _status = status;
        _statusMessage = msg;
      }
      _connectedDevice = device;
      if (status == ConnectionStateStatus.connected && device != null) {
        SettingsService.instance.saveLastConnectedDevice(device.name, device.id);
      }
      notifyListeners();
    };

    checkCurrentConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkCurrentConnection();
    }
  }

  Future<void> checkCurrentConnection() async {
    final connectedDev = await _bleService.checkCurrentConnectedHost();
    if (connectedDev != null) {
      _status = ConnectionStateStatus.connected;
      _connectedDevice = connectedDev;
      _statusMessage = 'Connected as Hardware Mouse/Keyboard to ${connectedDev.name}';
      _pingMs = 3;
      SettingsService.instance.saveLastConnectedDevice(connectedDev.name, connectedDev.id);
      notifyListeners();
    } else if (_status == ConnectionStateStatus.connected) {
      _status = ConnectionStateStatus.disconnected;
      _connectedDevice = null;
      _statusMessage = 'Disconnected';
      notifyListeners();
    }
  }

  Future<List<DiscoveredDevice>> startDiscovery() async {
    return await _bleService.startScan();
  }

  void stopDiscovery() {
    _bleService.stopScan();
  }

  Future<bool> connect(DiscoveredDevice device) async {
    _status = ConnectionStateStatus.connecting;
    _statusMessage = 'Connecting to ${device.name}...';
    notifyListeners();

    // If device.id is a placeholder or native host is already connected, check native status
    if (device.id == 'NATIVE-HID-CONNECTED' || device.id.isEmpty) {
      final currentHost = await _bleService.checkCurrentConnectedHost();
      if (currentHost != null) {
        _status = ConnectionStateStatus.connected;
        _connectedDevice = currentHost;
        _statusMessage = 'Connected as Hardware Mouse/Keyboard to ${currentHost.name}';
        _pingMs = 3;
        SettingsService.instance.saveLastConnectedDevice(currentHost.name, currentHost.id);
        notifyListeners();
        return true;
      }
    }

    bool success = await _bleService.connect(device);

    if (success) {
      _status = ConnectionStateStatus.connected;
      _connectedDevice = device;
      _statusMessage = 'Connected as Hardware Mouse/Keyboard to ${device.name}';
      _pingMs = 3;
      SettingsService.instance.saveLastConnectedDevice(device.name, device.id);
      notifyListeners();
      return true;
    }

    // If async connection was initiated (status is connecting), wait for native callback or poll for up to 8 seconds
    if (_status == ConnectionStateStatus.connecting) {
      int secondsPassed = 0;
      while (secondsPassed < 8 && _status == ConnectionStateStatus.connecting) {
        await Future.delayed(const Duration(seconds: 1));
        secondsPassed++;

        final currentHost = await _bleService.checkCurrentConnectedHost();
        if (currentHost != null) {
          _status = ConnectionStateStatus.connected;
          _connectedDevice = currentHost;
          _statusMessage = 'Connected as Hardware Mouse/Keyboard to ${currentHost.name}';
          _pingMs = 3;
          SettingsService.instance.saveLastConnectedDevice(currentHost.name, currentHost.id);
          notifyListeners();
          return true;
        }
      }

      // If state is still connecting or disconnected after polling/timeout, set to failed
      if (_status == ConnectionStateStatus.connecting || _status == ConnectionStateStatus.disconnected) {
        _status = ConnectionStateStatus.failed;
        _connectedDevice = null;
        _statusMessage = 'Could not connect to ${device.name}. Please make sure Bluetooth is ON on your computer.';
        notifyListeners();
        return false;
      }
    } else if (_status != ConnectionStateStatus.connected) {
      _status = ConnectionStateStatus.failed;
      _connectedDevice = null;
      _statusMessage = 'Failed to pair Bluetooth with ${device.name}';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return isConnected;
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    _status = ConnectionStateStatus.disconnected;
    _connectedDevice = null;
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  void sendCommand(InputCommand command) {
    _bleService.sendCommand(command);
  }
}
