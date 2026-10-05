import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection_type.dart';
import '../models/device_model.dart';
import '../models/input_command.dart';
import 'bluetooth_service.dart';
import 'settings_service.dart';

class ConnectionService extends ChangeNotifier {
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
    _bleService.onStatusChanged = (status, device, msg) {
      _status = status;
      _connectedDevice = device;
      _statusMessage = msg;
      if (status == ConnectionStateStatus.connected && device != null) {
        SettingsService.instance.saveLastConnectedDevice(device.name, device.id);
      }
      notifyListeners();
    };

    checkCurrentConnection();
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
    _statusMessage = 'Pairing Bluetooth HID with ${device.name}...';
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
    } else {
      // Check if native Bluetooth HID host is actually connected despite pair API return string
      final currentHost = await _bleService.checkCurrentConnectedHost();
      if (currentHost != null) {
        _status = ConnectionStateStatus.connected;
        _connectedDevice = currentHost;
        _statusMessage = 'Connected as Hardware Mouse/Keyboard to ${currentHost.name}';
        _pingMs = 3;
        SettingsService.instance.saveLastConnectedDevice(currentHost.name, currentHost.id);
        success = true;
      } else {
        _status = ConnectionStateStatus.failed;
        _connectedDevice = null;
        _statusMessage = 'Failed to pair Bluetooth with ${device.name}';
      }
    }

    notifyListeners();
    return success;
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    _status = ConnectionStateStatus.disconnected;
    _connectedDevice = null;
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  void sendCommand(InputCommand command) {
    if (!isConnected) return;
    _bleService.sendCommand(command);
  }
}
