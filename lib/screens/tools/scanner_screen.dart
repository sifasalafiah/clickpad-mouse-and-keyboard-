import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/connection_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../../utils/hid_helper.dart';

enum ScanSuffix { none, enter, tab }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final SettingsService _settings = SettingsService.instance;

  ScanSuffix _selectedSuffix = ScanSuffix.enter;
  bool _isSending = false;
  DateTime? _lastScanTime;

  final List<String> _scanHistory = [];
  final TextEditingController _manualTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsUpdate);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsUpdate);
    _scannerController.dispose();
    _manualTextController.dispose();
    super.dispose();
  }

  void _onSettingsUpdate() {
    if (mounted) setState(() {});
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isSending) return;
    final now = DateTime.now();

    // Prevent duplicate triggers within 1.2s if continuous mode
    if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 1200) {
      return;
    }

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue != null && rawValue.trim().isNotEmpty) {
      _lastScanTime = now;
      _sendDataToHost(rawValue.trim());
    }
  }

  Future<void> _sendDataToHost(String text) async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      if (!_scanHistory.contains(text)) {
        _scanHistory.insert(0, text);
        if (_scanHistory.length > 30) _scanHistory.removeLast();
      }
    });

    HapticHelper.mediumImpact();

    await HidHelper.instance.sendText(
      text,
      sendEnter: _selectedSuffix == ScanSuffix.enter,
      sendTab: _selectedSuffix == ScanSuffix.tab,
      charDelayMs: 16,
    );

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ConnectionService.instance.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Barcode & QR Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.amber);
                  default:
                    return const Icon(Icons.flash_off);
                }
              },
            ),
            tooltip: 'Flashlight',
            onPressed: () {
              HapticHelper.selectionClick();
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch Camera',
            onPressed: () {
              HapticHelper.selectionClick();
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Viewfinder Box with Aiming Reticle
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: Colors.amber, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Camera error: ${error.errorCode.name}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Please ensure camera permissions are granted in system settings.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Aiming Laser Box Overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isSending ? AppColors.success : AppColors.primary,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isSending ? AppColors.success : AppColors.primary).withAlpha(50),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 2,
                            width: 210,
                            color: (_isSending ? AppColors.success : Colors.redAccent).withAlpha(180),
                          ),
                        ),
                        if (_isSending)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'TYPED TO PC',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Top Connection Indicator Banner
                if (!isConnected)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bluetooth_disabled, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PC not connected. Connect via Bluetooth first.',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Controls & Options Tray
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Suffix Option & Mode (Overflow-safe Wrap)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    const Text('After Scan Send:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSuffixChoice(ScanSuffix.enter, 'Enter ↵'),
                        const SizedBox(width: 6),
                        _buildSuffixChoice(ScanSuffix.tab, 'Tab ⇥'),
                        const SizedBox(width: 6),
                        _buildSuffixChoice(ScanSuffix.none, 'None'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Manual Input Fallback
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _manualTextController,
                          decoration: InputDecoration(
                            hintText: 'Type or paste barcode/text...',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _sendDataToHost(val.trim());
                              _manualTextController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final val = _manualTextController.text.trim();
                        if (val.isNotEmpty) {
                          _sendDataToHost(val);
                          _manualTextController.clear();
                        }
                      },
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scan History List
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.surfaceElevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Scans (${_scanHistory.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        if (_scanHistory.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _scanHistory.clear()),
                            child: Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _scanHistory.isEmpty
                      ? Center(
                          child: Text(
                            'Point camera at any Barcode or QR code to send',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: _scanHistory.length,
                          separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 1),
                          itemBuilder: (context, idx) {
                            final item = _scanHistory[idx];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.qr_code, size: 20, color: AppColors.primary),
                              title: Text(
                                item,
                                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.send_rounded, size: 18),
                                tooltip: 'Re-send to PC',
                                onPressed: () => _sendDataToHost(item),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixChoice(ScanSuffix suffix, String label) {
    final isSelected = _selectedSuffix == suffix;
    return InkWell(
      onTap: () {
        HapticHelper.selectionClick();
        setState(() => _selectedSuffix = suffix);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
