import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../services/connection_service.dart';
import '../../services/iap_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';

class NumpadScreen extends StatefulWidget {
  const NumpadScreen({super.key});

  @override
  State<NumpadScreen> createState() => _NumpadScreenState();
}

class _QueuedNumpadKey {
  final int modifier;
  final int scancode;
  const _QueuedNumpadKey(this.modifier, this.scancode);
}

class _NumpadScreenState extends State<NumpadScreen> {
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final SettingsService _settings = SettingsService.instance;
  final IapService _iapService = IapService.instance;
  final List<_QueuedNumpadKey> _keyQueue = [];
  bool _isQueueProcessing = false;
  String _liveExpression = '';

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onServiceUpdate);
    _iapService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _settings.removeListener(_onServiceUpdate);
    _iapService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _enqueueKey(int scancode, {int modifier = 0}) {
    _keyQueue.add(_QueuedNumpadKey(modifier, scancode));
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing || _keyQueue.isEmpty) return;
    _isQueueProcessing = true;
    while (_keyQueue.isNotEmpty) {
      final item = _keyQueue.removeAt(0);
      _bleService.sendKeyboardScancode(item.modifier, item.scancode);
      // Jeda 65ms memberikan jeda rilis >45ms yang aman untuk filter debounce Windows/macOS/Linux
      await Future.delayed(const Duration(milliseconds: 65));
    }
    _isQueueProcessing = false;
  }

  void _onKeyPress(String label, int scancode, {int modifier = 0}) {
    HapticHelper.lightImpact();
    _enqueueKey(scancode, modifier: modifier);

    setState(() {
      if (scancode == 0x2A) {
        // Backspace
        if (_liveExpression.isNotEmpty) {
          _liveExpression = _liveExpression.substring(0, _liveExpression.length - 1);
        }
      } else if (scancode == 0x29) {
        // Esc / Clear
        _liveExpression = '';
      } else if (scancode == 0x58 || scancode == 0x28) {
        // Enter
        _liveExpression = '';
      } else if (label.length == 1) {
        _liveExpression += label;
        if (_liveExpression.length > 30) {
          _liveExpression = _liveExpression.substring(_liveExpression.length - 30);
        }
      }
    });
  }

  void _sendDoubleZero() {
    HapticHelper.lightImpact();
    _enqueueKey(0x62);
    _enqueueKey(0x62);
    setState(() {
      _liveExpression += '00';
      if (_liveExpression.length > 30) {
        _liveExpression = _liveExpression.substring(_liveExpression.length - 30);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ConnectionService.instance.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Accounting Numpad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (_iapService.isTrialActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${(_iapService.trialSecondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_iapService.trialSecondsLeft % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.success.withAlpha(30) : Colors.redAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isConnected ? AppColors.success : Colors.redAccent),
                ),
                child: Text(
                  isConnected ? 'ONLINE' : 'DISCONNECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppColors.success : Colors.redAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Expression Preview Screen (Looks like digital calculator display)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'PC Stream',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _liveExpression.isEmpty ? '0' : _liveExpression,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: _liveExpression.isEmpty ? AppColors.textMuted : AppColors.primaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Numpad Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Row 1: Esc, Tab, /, *
                    Expanded(
                      child: Row(
                        children: [
                          _buildKey('Esc', 0x29, isAction: true),
                          const SizedBox(width: 8),
                          _buildKey('Tab', 0x2B, isAction: true),
                          const SizedBox(width: 8),
                          _buildKey('/', 0x54, isOperator: true),
                          const SizedBox(width: 8),
                          _buildKey('*', 0x55, isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 2: 7, 8, 9, -
                    Expanded(
                      child: Row(
                        children: [
                          _buildKey('7', 0x5F),
                          const SizedBox(width: 8),
                          _buildKey('8', 0x60),
                          const SizedBox(width: 8),
                          _buildKey('9', 0x61),
                          const SizedBox(width: 8),
                          _buildKey('-', 0x56, isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 3: 4, 5, 6, +
                    Expanded(
                      child: Row(
                        children: [
                          _buildKey('4', 0x5C),
                          const SizedBox(width: 8),
                          _buildKey('5', 0x5D),
                          const SizedBox(width: 8),
                          _buildKey('6', 0x5E),
                          const SizedBox(width: 8),
                          _buildKey('+', 0x57, isOperator: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 4: 1, 2, 3, ⌫
                    Expanded(
                      child: Row(
                        children: [
                          _buildKey('1', 0x59),
                          const SizedBox(width: 8),
                          _buildKey('2', 0x5A),
                          const SizedBox(width: 8),
                          _buildKey('3', 0x5B),
                          const SizedBox(width: 8),
                          _buildKey('⌫', 0x2A, isAction: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 5: 0, 00, ., Enter (Double flex for Enter)
                    Expanded(
                      child: Row(
                        children: [
                          _buildKey('0', 0x62),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _buildCustomKey(
                              label: '00',
                              onTap: _sendDoubleZero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildKey('.', 0x63),
                          const SizedBox(width: 8),
                          _buildKey('Enter', 0x58, isPrimary: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(
    String label,
    int scancode, {
    int modifier = 0,
    bool isOperator = false,
    bool isAction = false,
    bool isPrimary = false,
  }) {
    return Expanded(
      flex: 1,
      child: _buildCustomKey(
        label: label,
        isOperator: isOperator,
        isAction: isAction,
        isPrimary: isPrimary,
        onTap: () => _onKeyPress(label, scancode, modifier: modifier),
      ),
    );
  }

  Widget _buildCustomKey({
    required String label,
    required VoidCallback onTap,
    bool isOperator = false,
    bool isAction = false,
    bool isPrimary = false,
  }) {
    Color bg = AppColors.surfaceElevated;
    Color textCol = AppColors.textPrimary;
    Color borderCol = AppColors.border;

    if (isPrimary) {
      bg = AppColors.primary;
      textCol = Colors.white;
      borderCol = AppColors.primaryLight;
    } else if (isOperator) {
      bg = AppColors.primary.withAlpha(25);
      textCol = AppColors.primaryLight;
      borderCol = AppColors.primary.withAlpha(70);
    } else if (isAction) {
      bg = AppColors.surface;
      textCol = Colors.amber;
      borderCol = AppColors.border;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.length > 2 ? 15 : 22,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
