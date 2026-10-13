import 'connection_type.dart';

class DiscoveredDevice {
  final String id;
  final String name;
  final ConnectionType type;
  final int rssi; // Signal strength for BLE (-100 to 0)
  final String? ipAddress;
  final int? port;
  final dynamic nativeDeviceHandle; // BluetoothDevice object if BLE
  final DateTime lastSeen;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.type,
    this.rssi = -60,
    this.ipAddress,
    this.port = 8888,
    this.nativeDeviceHandle,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'rssi': rssi,
        'ipAddress': ipAddress,
        'port': port,
        'lastSeen': lastSeen.millisecondsSinceEpoch,
      };

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json) {
    return DiscoveredDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ConnectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConnectionType.bluetoothHid,
      ),
      rssi: json['rssi'] as int? ?? -60,
      ipAddress: json['ipAddress'] as String?,
      port: json['port'] as int?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
          : null,
    );
  }
}
