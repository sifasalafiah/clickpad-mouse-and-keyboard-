import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class ConnectionModal extends StatefulWidget {
  const ConnectionModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ConnectionModal(),
    );
  }

  @override
  State<ConnectionModal> createState() => _ConnectionModalState();
}

class _ConnectionModalState extends State<ConnectionModal> {
  final ConnectionService _connService = ConnectionService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;

  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    final devices = await _connService.startDiscovery();
    if (mounted) {
      setState(() {
        _discoveredDevices = devices;
        _isScanning = false;
      });
    }
  }

  void _connectDevice(DiscoveredDevice device) async {
    HapticHelper.mediumImpact();
    Navigator.of(context).pop();
    await _connService.connect(device);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bluetooth, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Bluetooth Mouse & Keyboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                onPressed: _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Seamlessly connects as a hardware Bluetooth mouse & keyboard. No software needed on your PC or Mac!',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Discovered Bluetooth Devices List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isScanning ? 'Scanning Bluetooth devices...' : 'Bluetooth Devices (${_discoveredDevices.length})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton.icon(
                onPressed: () => _bleService.openSystemBluetoothSettings(),
                icon: const Icon(Icons.settings_bluetooth, size: 16),
                label: const Text('OS Settings', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: _discoveredDevices.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bluetooth_searching, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        const Text(
                          'No Bluetooth devices found nearby.\nMake sure Bluetooth is ON on your PC or Mac.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Scan Again'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _discoveredDevices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      return ListTile(
                        onTap: () => _connectDevice(device),
                        tileColor: AppColors.surfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(40),
                          child: const Icon(Icons.bluetooth_connected, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          device.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Signal: ${device.rssi} dBm (Tap to pair)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
