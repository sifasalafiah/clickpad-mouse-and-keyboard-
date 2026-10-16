import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final SettingsService _settings = SettingsService.instance;

  // Stopwatch / Timer
  Timer? _stopwatchTimer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  int _slideClickCount = 1;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsUpdate);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsUpdate);
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  void _onSettingsUpdate() {
    if (mounted) setState(() {});
  }

  void _toggleTimer() {
    HapticHelper.mediumImpact();
    setState(() {
      if (_isTimerRunning) {
        _stopwatchTimer?.cancel();
        _isTimerRunning = false;
      } else {
        _isTimerRunning = true;
        _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() => _secondsElapsed++);
          }
        });
      }
    });
  }

  void _resetTimer() {
    HapticHelper.lightImpact();
    _stopwatchTimer?.cancel();
    setState(() {
      _secondsElapsed = 0;
      _isTimerRunning = false;
      _slideClickCount = 1;
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _nextSlide() {
    HapticHelper.mediumImpact();
    // Send Right Arrow (0x4F) or Space (0x2C)
    _bleService.sendKeyboardScancode(0, 0x4F);
    setState(() => _slideClickCount++);
  }

  void _prevSlide() {
    HapticHelper.mediumImpact();
    // Send Left Arrow (0x50)
    _bleService.sendKeyboardScancode(0, 0x50);
    setState(() {
      if (_slideClickCount > 1) _slideClickCount--;
    });
  }

  void _startPresentation() {
    HapticHelper.heavyImpact();
    _bleService.sendKeyboardScancode(0, 0x3E); // F5
    if (!_isTimerRunning) _toggleTimer();
  }

  void _startFromCurrent() {
    HapticHelper.heavyImpact();
    _bleService.sendKeyboardScancode(0x02, 0x3E); // Shift + F5
    if (!_isTimerRunning) _toggleTimer();
  }

  void _blackScreen() {
    HapticHelper.lightImpact();
    _bleService.sendKeyboardScancode(0, 0x05); // 'B'
  }

  void _whiteScreen() {
    HapticHelper.lightImpact();
    _bleService.sendKeyboardScancode(0, 0x1A); // 'W'
  }

  void _exitPresentation() {
    HapticHelper.mediumImpact();
    _bleService.sendKeyboardScancode(0, 0x29); // Esc
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Presentation Clicker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Timer & Slide Counter',
            onPressed: _resetTimer,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Presentation HUD (Timer & Slide Counter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer Display
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleTimer,
                          icon: Icon(
                            _isTimerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: _isTimerRunning ? Colors.amber : AppColors.primaryLight,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_secondsElapsed),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text('Elapsed Time', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),

                    // Slide Counter Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withAlpha(80)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SLIDE',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                          Text(
                            '#$_slideClickCount',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Quick Action Controls (F5, Shift+F5, Black, White, Esc)
              Row(
                children: [
                  _buildSubButton(label: 'Start (F5)', icon: Icons.slideshow_rounded, onTap: _startPresentation),
                  const SizedBox(width: 8),
                  _buildSubButton(label: 'From Cur', icon: Icons.play_arrow_rounded, onTap: _startFromCurrent),
                  const SizedBox(width: 8),
                  _buildSubButton(label: 'Black (B)', icon: Icons.contrast_rounded, onTap: _blackScreen),
                  const SizedBox(width: 8),
                  _buildSubButton(label: 'White (W)', icon: Icons.light_mode_outlined, onTap: _whiteScreen),
                  const SizedBox(width: 8),
                  _buildSubButton(label: 'Exit', icon: Icons.close_fullscreen_rounded, onTap: _exitPresentation, isDestructive: true),
                ],
              ),
              const SizedBox(height: 12),

              // Giant Clicker Buttons (Prev & Next)
              Expanded(
                flex: 3,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _nextSlide,
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(90),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 64, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'NEXT SLIDE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Right Arrow / Space',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                flex: 2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _prevSlide,
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 36, color: AppColors.textPrimary),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREVIOUS SLIDE',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text('Left Arrow', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.redAccent.withAlpha(20) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDestructive ? Colors.redAccent.withAlpha(70) : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isDestructive ? Colors.redAccent : AppColors.textPrimary),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? Colors.redAccent : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
