import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ad_service.dart';
import '../models/connection_type.dart';
import '../models/device_model.dart';
import '../models/input_command.dart';

class BluetoothBleService {
  static final BluetoothBleService instance = BluetoothBleService._internal();
  BluetoothBleService._internal() {
    _initChannelListener();
  }

  BluetoothDevice? _connectedBleDevice;
  BluetoothCharacteristic? _hidReportCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;
  
  Function(ConnectionStateStatus status, DiscoveredDevice? device, String? message)? onStatusChanged;
  Function(DiscoveredDevice device)? onDeviceDiscovered;

  // Platform Channel for Native Android Bluetooth HID Device Registration
  static const MethodChannel _nativeHidChannel = MethodChannel('com.sekala.clickpad/bluetooth_hid');

  void _initChannelListener() {
    _nativeHidChannel.setMethodCallHandler((call) async {
      if (call.method == 'onConnectionChanged') {
        final isConnected = call.arguments['isConnected'] as bool? ?? false;
        final deviceName = call.arguments['deviceName'] as String? ?? 'Connected Desktop';
        final deviceAddress = call.arguments['deviceAddress'] as String? ?? '';
        final deviceId = deviceAddress.isNotEmpty ? deviceAddress : 'NATIVE-HID-CONNECTED';

        if (isConnected) {
          final device = DiscoveredDevice(
            id: deviceId,
            name: deviceName,
            type: ConnectionType.bluetoothHid,
          );
          onStatusChanged?.call(
            ConnectionStateStatus.connected,
            device,
            'Connected to $deviceName via Bluetooth HID',
          );
        } else {
          onStatusChanged?.call(
            ConnectionStateStatus.disconnected,
            null,
            'Bluetooth Disconnected',
          );
        }
      } else if (call.method == 'onDeviceDiscovered') {
        final name = call.arguments['name'] as String? ?? 'Bluetooth Device';
        final address = call.arguments['address'] as String? ?? '';
        if (address.isNotEmpty) {
          final device = DiscoveredDevice(
            id: address,
            name: name,
            type: ConnectionType.bluetoothHid,
            rssi: -45,
          );
          onDeviceDiscovered?.call(device);
        }
      }
    });

    // Check if host is already connected on startup
    checkConnectedHost();
  }

  Future<void> checkConnectedHost() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _nativeHidChannel.invokeMethod('getConnectedHost');
        if (result != null && result is Map) {
          final name = result['name'] as String? ?? 'Connected Desktop';
          final device = DiscoveredDevice(
            id: result['address'] as String? ?? 'NATIVE-HID-HOST',
            name: name,
            type: ConnectionType.bluetoothHid,
          );
          onStatusChanged?.call(
            ConnectionStateStatus.connected,
            device,
            'Connected to $name',
          );
        }
      } catch (_) {}
    }
  }

  Future<List<DiscoveredDevice>> startScan() async {
    final Map<String, DiscoveredDevice> foundDevices = {};

    try {
      if (kIsWeb) return [];

      // 1. Fetch Native Android Bonded/Paired Devices
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final List? nativePaired = await _nativeHidChannel.invokeMethod('getPairedDevices');
          if (nativePaired != null) {
            for (var item in nativePaired) {
              if (item is Map) {
                final name = item['name'] as String? ?? 'Paired Device';
                final addr = item['address'] as String? ?? '';
                foundDevices[addr] = DiscoveredDevice(
                  id: addr,
                  name: name,
                  type: ConnectionType.bluetoothHid,
                  rssi: -45,
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Native paired query error: $e");
        }
      }

      // 2. Verify Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        return foundDevices.values.toList();
      }

      // Turn on Bluetooth adapter if disabled
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }

      // 3. Fetch OS Paired / Bonded Devices via flutter_blue_plus
      try {
        final bonded = await FlutterBluePlus.bondedDevices;
        for (BluetoothDevice device in bonded) {
          final name = device.platformName.isNotEmpty ? device.platformName : device.advName;
          if (name.isNotEmpty) {
            foundDevices[device.remoteId.str] = DiscoveredDevice(
              id: device.remoteId.str,
              name: name,
              type: ConnectionType.bluetoothHid,
              rssi: -45,
              nativeDeviceHandle: device,
            );
          }
        }
      } catch (e) {
        debugPrint("Bonded fetch error: $e");
      }

      // 4. Perform Bluetooth Scan for nearby Desktop & PC
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          final name = r.device.platformName.isNotEmpty ? r.device.platformName : r.device.advName;
          if (name.isNotEmpty) {
            foundDevices[r.device.remoteId.str] = DiscoveredDevice(
              id: r.device.remoteId.str,
              name: name,
              type: ConnectionType.bluetoothHid,
              rssi: r.rssi,
              nativeDeviceHandle: r.device,
            );
          }
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();

      return foundDevices.values.toList();
    } catch (e) {
      debugPrint("Bluetooth Scan Exception: $e");
      return foundDevices.values.toList();
    }
  }

  void stopScan() {
    try {
      FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
    } catch (_) {}
  }

  // Make phone discoverable as ClickPad Mouse to nearby Mac/PC
  Future<bool> makeDiscoverable() async {
    AdService.instance.isSuppressingAppOpenAd = true;
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final res = await _nativeHidChannel.invokeMethod('makeDiscoverable');
        return res == true;
      } catch (e) {
        debugPrint("makeDiscoverable error: $e");
        return false;
      }
    }
    return true;
  }

  // Open Native Bluetooth Pairing Settings on Phone
  Future<void> openSystemBluetoothSettings() async {
    AdService.instance.isSuppressingAppOpenAd = true;
    try {
      await _nativeHidChannel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  // Check if native Bluetooth HID host is already connected on OS level
  Future<DiscoveredDevice?> checkCurrentConnectedHost() async {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final res = await _nativeHidChannel.invokeMethod('getConnectedHost');
        if (res != null && res is Map) {
          final name = res['name'] as String? ?? 'Connected Desktop';
          final address = res['address'] as String? ?? 'NATIVE-HID-CONNECTED';
          final device = DiscoveredDevice(
            id: address.isNotEmpty ? address : 'NATIVE-HID-CONNECTED',
            name: name,
            type: ConnectionType.bluetoothHid,
          );
          onStatusChanged?.call(
            ConnectionStateStatus.connected,
            device,
            'Connected to $name via Bluetooth HID',
          );
          return device;
        }
      } catch (e) {
        debugPrint('checkCurrentConnectedHost error: $e');
      }
    }
    return null;
  }

  Future<bool> connect(DiscoveredDevice device) async {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        onStatusChanged?.call(ConnectionStateStatus.connecting, device, 'Pairing Bluetooth with ${device.name}...');
        final res = await _nativeHidChannel.invokeMethod('pairDevice', {'address': device.id});
        debugPrint("Native pair result: $res");
        
        if (res == 'connected') {
          onStatusChanged?.call(ConnectionStateStatus.connected, device, 'Connected to ${device.name}');
          return true;
        } else if (res == 'connecting_started' || res == 'bonding_started' || res == 'bonded') {
          onStatusChanged?.call(ConnectionStateStatus.connecting, device, 'Connecting to ${device.name}...');
          return false;
        }
      } catch (e) {
        debugPrint("Pairing error: $e");
      }
    }

    // Fallback for GATT connection
    if (device.nativeDeviceHandle == null) {
      onStatusChanged?.call(
        ConnectionStateStatus.connected,
        device,
        'Active Bluetooth HID Mouse with ${device.name}',
      );
      return true;
    }

    try {
      final BluetoothDevice bleDevice = device.nativeDeviceHandle as BluetoothDevice;
      
      onStatusChanged?.call(ConnectionStateStatus.connecting, device, 'Pairing Bluetooth HID with ${device.name}...');
      await bleDevice.connect(timeout: const Duration(seconds: 10));
      _connectedBleDevice = bleDevice;

      // Discover GATT HID services
      List<BluetoothService> services = await bleDevice.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _hidReportCharacteristic = char;
            break;
          }
        }
      }

      _connectionStateSubscription = bleDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _hidReportCharacteristic = null;
          _connectedBleDevice = null;
          onStatusChanged?.call(ConnectionStateStatus.disconnected, null, 'Bluetooth Disconnected');
        }
      });

      onStatusChanged?.call(
        ConnectionStateStatus.connected,
        device,
        'Connected as Bluetooth HID Mouse/Keyboard to ${device.name}',
      );
      return true;
    } catch (e) {
      debugPrint("Bluetooth Connection Error: $e");
      onStatusChanged?.call(ConnectionStateStatus.failed, null, 'Bluetooth Connect Failed: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    _connectionStateSubscription?.cancel();

    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _nativeHidChannel.invokeMethod('disconnect');
      } catch (_) {}
    }

    if (_connectedBleDevice != null) {
      try {
        await _connectedBleDevice!.disconnect();
      } catch (_) {}
      _connectedBleDevice = null;
      _hidReportCharacteristic = null;
    }
    onStatusChanged?.call(ConnectionStateStatus.disconnected, null, 'Disconnected');
  }

  void sendCommand(InputCommand command) {
    int buttonMask = 0;
    if (command.button == 'left') buttonMask |= 0x01;
    if (command.button == 'right') buttonMask |= 0x02;
    if (command.button == 'middle') buttonMask |= 0x04;

    int dx = command.dx.clamp(-127.0, 127.0).toInt();
    int dy = command.dy.clamp(-127.0, 127.0).toInt();
    int wheel = command.type == CommandType.scroll ? command.dy.clamp(-127.0, 127.0).toInt() : 0;

    // Send via Native Android / iOS Bluetooth HID Service
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _nativeHidChannel.invokeMethod('sendMouseReport', {
          'button': buttonMask,
          'dx': dx,
          'dy': dy,
          'wheel': wheel,
        });
      } catch (e) {
        debugPrint("Native HID Error: $e");
      }
    }

    // Also send via GATT if GATT characteristic is active
    if (_hidReportCharacteristic != null) {
      final reportBytes = [
        buttonMask & 0xFF,
        dx < 0 ? (256 + dx) : dx,
        dy < 0 ? (256 + dy) : dy,
        wheel < 0 ? (256 + wheel) : wheel,
      ];
      try {
        _hidReportCharacteristic!.write(reportBytes, withoutResponse: true);
      } catch (_) {}
    }
  }

  void sendKeyboardScancode(int modifier, int keycode) {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _nativeHidChannel.invokeMethod('sendKeyboardReport', {
          'modifier': modifier,
          'keycode': keycode,
        });
      } catch (e) {
        debugPrint("Native Keyboard HID Error: $e");
      }
    }
  }

  void sendKeyboardState(int modifier, List<int> keycodes) {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _nativeHidChannel.invokeMethod('sendKeyboardState', {
          'modifier': modifier,
          'keycodes': keycodes,
        });
      } catch (e) {
        debugPrint("Native Keyboard HID Error: $e");
      }
    }
  }
}
