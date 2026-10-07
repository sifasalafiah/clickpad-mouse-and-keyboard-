import 'dart:async';
import 'package:flutter/material.dart';
import '../models/input_command.dart';
import '../services/connection_service.dart';
import '../services/iap_service.dart';
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
  final IapService _iapService = IapService.instance;

  // Multi-pointer tracking for smooth tracking & multi-touch ripples
  final Map<int, Offset> _pointerPositions = {};
  final Map<int, Offset> _lastPointerPositions = {};
  bool _precisionMode = false;

  // High-frequency 80Hz Input Frame Accumulator for Zero Latency
  double _accumulatedDx = 0.0;
  double _accumulatedDy = 0.0;
  double _accumulatedScrollY = 0.0;
  Timer? _flushTimer;

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);
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

  void _onIapChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIapChanged);
    _flushTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _pointerPositions[event.pointer] = event.localPosition;
      _lastPointerPositions[event.pointer] = event.localPosition;
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _pointerPositions.remove(event.pointer);
      _lastPointerPositions.remove(event.pointer);
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _pointerPositions.clear();
      _lastPointerPositions.clear();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final prev = _lastPointerPositions[event.pointer] ?? event.localPosition;
    final delta = event.localPosition - prev;
    _lastPointerPositions[event.pointer] = event.localPosition;

    setState(() {
      _pointerPositions[event.pointer] = event.localPosition;
    });

    final activeCount = _pointerPositions.length;
    final sensitivity = _precisionMode ? 0.6 : _settings.mouseSensitivity;

    if (activeCount == 1) {
      // Single finger: Accumulate mouse move
      _accumulatedDx += delta.dx * sensitivity;
      _accumulatedDy += delta.dy * sensitivity;
    } else if (activeCount >= 2) {
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
        // Collapsible AdMob Banner Ad at Top of Touchpad Screen (Hidden for PRO users)
        if (!_iapService.isPro)
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

                      // Multi-Touch Ripple Visual Indicators (renders a circle for each finger)
                      for (final pos in _pointerPositions.values)
                        Positioned(
                          left: pos.dx - 24,
                          top: pos.dy - 24,
                          child: IgnorePointer(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.touchRipple,
                                border: Border.all(color: AppColors.primaryLight, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(70),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Left Click', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      shape: RoundedRectangleBorder(
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
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Right Click', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
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
