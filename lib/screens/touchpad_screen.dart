import 'dart:async';
import 'package:flutter/material.dart';
import '../models/input_command.dart';
import '../services/connection_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/banner_ad_widget.dart';

class TouchpadScreen extends StatefulWidget {
  const TouchpadScreen({super.key});

  @override
  State<TouchpadScreen> createState() => _TouchpadScreenState();
}

class _TouchpadScreenState extends State<TouchpadScreen> {
  final ConnectionService _connService = ConnectionService.instance;
  final SettingsService _settings = SettingsService.instance;

  Offset? _lastPanPosition;
  Offset? _touchRipplePosition;
  bool _showTouchRipple = false;
  int _activePointers = 0;
  bool _precisionMode = false;

  // High-frequency 80Hz Input Frame Accumulator for Zero Latency
  double _accumulatedDx = 0.0;
  double _accumulatedDy = 0.0;
  double _accumulatedScrollY = 0.0;
  Timer? _flushTimer;

  @override
  void initState() {
    super.initState();
    // Flush input deltas every 12ms (~83Hz smooth input frame rate)
    _flushTimer = Timer.periodic(const Duration(milliseconds: 12), (_) {
      if (_accumulatedDx != 0.0 || _accumulatedDy != 0.0) {
        _connService.sendCommand(InputCommand.move(_accumulatedDx, _accumulatedDy));
        _accumulatedDx = 0.0;
        _accumulatedDy = 0.0;
      }
      if (_accumulatedScrollY.abs() >= 0.8) {
        final ticks = _accumulatedScrollY.truncateToDouble();
        if (ticks != 0.0) {
          _connService.sendCommand(InputCommand.scroll(0, ticks));
          _accumulatedScrollY -= ticks;
        }
      }
    });
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _activePointers++;
      _lastPanPosition = event.localPosition;
      _touchRipplePosition = event.localPosition;
      _showTouchRipple = true;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _activePointers = (_activePointers - 1).clamp(0, 10);
      if (_activePointers == 0) {
        _showTouchRipple = false;
        _touchRipplePosition = null;
      }
    });
    _lastPanPosition = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _activePointers = 0;
      _showTouchRipple = false;
      _touchRipplePosition = null;
    });
    _lastPanPosition = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      _touchRipplePosition = event.localPosition;
    });

    if (_lastPanPosition == null) {
      _lastPanPosition = event.localPosition;
      return;
    }

    final delta = event.localPosition - _lastPanPosition!;
    _lastPanPosition = event.localPosition;

    final sensitivity = _precisionMode ? 0.6 : _settings.mouseSensitivity;

    if (_activePointers == 1) {
      // Single finger: Accumulate mouse move
      _accumulatedDx += delta.dx * sensitivity;
      _accumulatedDy += delta.dy * sensitivity;
    } else if (_activePointers >= 2) {
      // Two fingers: Smooth scroll with proper pixel-to-notch scaling & settings tuning
      final scrollFactor = 0.08 * _settings.scrollSensitivity;
      _accumulatedScrollY += delta.dy * scrollFactor;
    }
  }

  void _onTap() {
    HapticHelper.lightImpact();
    _connService.sendCommand(InputCommand.click('left'));
  }

  void _onDoubleTap() {
    HapticHelper.mediumImpact();
    _connService.sendCommand(InputCommand.click('left'));
    _connService.sendCommand(InputCommand.click('left'));
  }

  void _onLongPress() {
    HapticHelper.heavyImpact();
    _connService.sendCommand(InputCommand.click('right'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Collapsible AdMob Banner Ad at Top of Touchpad Screen
        const CollapsibleBannerAdWidget(collapsiblePosition: 'top'),

        // Top Info & Quick Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _precisionMode ? Icons.filter_center_focus : Icons.touch_app,
                    size: 16,
                    color: _precisionMode ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _precisionMode ? 'Precision Mode (Low Sens)' : 'Touchpad Canvas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _precisionMode ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  HapticHelper.selectionClick();
                  setState(() => _precisionMode = !_precisionMode);
                },
                tooltip: 'Toggle Precision Mode',
                icon: Icon(
                  _precisionMode ? Icons.center_focus_strong : Icons.center_focus_weak,
                  color: _precisionMode ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Main Touchpad Surface Canvas
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.touchpadCanvas,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: GestureDetector(
                  onTap: _onTap,
                  onDoubleTap: _onDoubleTap,
                  onLongPress: _onLongPress,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    children: [
                      // Subdued Grid pattern lines
                      CustomPaint(
                        size: Size.infinite,
                        painter: GridPainter(),
                      ),

                      // Touch Ripple Visual Indicator
                      if (_showTouchRipple && _touchRipplePosition != null)
                        Positioned(
                          left: _touchRipplePosition!.dx - 24,
                          top: _touchRipplePosition!.dy - 24,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.touchRipple,
                              border: Border.all(color: AppColors.primaryLight, width: 2),
                            ),
                          ),
                        ),

                      // Center gesture guide text
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mouse,
                              size: 32,
                              color: AppColors.textMuted.withAlpha(50),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1 Finger: Move Cursor  •  2 Fingers: Scroll\nTap: Left Click  •  Long Press: Right Click',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bottom Physical Mouse Click Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Left Click Button
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticHelper.mediumImpact();
                      _connService.sendCommand(InputCommand.click('left'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.textPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Left Click', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Middle / Scroll Lock Button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticHelper.mediumImpact();
                      _connService.sendCommand(InputCommand.click('middle'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.textSecondary,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Icon(Icons.unfold_more, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Right Click Button
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticHelper.heavyImpact();
                      _connService.sendCommand(InputCommand.click('right'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.textPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Right Click', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.mouse, size: 18, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
