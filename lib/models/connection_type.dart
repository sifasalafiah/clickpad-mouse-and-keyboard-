enum ConnectionType {
  bluetoothHid,
}

enum ConnectionStateStatus {
  disconnected,
  pairing,
  connecting,
  connected,
  failed,
}

extension ConnectionTypeExtension on ConnectionType {
  String get label => 'Native Bluetooth HID';
  String get description => 'Emulates a standard Bluetooth Mouse & Keyboard hardware device (No app needed on PC)';
}
