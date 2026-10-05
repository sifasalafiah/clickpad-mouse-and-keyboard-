import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection_type.dart';
import '../models/device_model.dart';
import '../models/input_command.dart';
import 'bluetooth_service.dart';

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
      notifyListeners();
    };
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

    bool success = await _bleService.connect(device);

    if (success) {
      _status = ConnectionStateStatus.connected;
      _connectedDevice = device;
      _statusMessage = 'Connected as Hardware Mouse/Keyboard to ${device.name}';
      _pingMs = 3;
    } else {
      _status = ConnectionStateStatus.failed;
      _connectedDevice = null;
      _statusMessage = 'Failed to pair Bluetooth with ${device.name}';
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
