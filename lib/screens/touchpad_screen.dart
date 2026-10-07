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
  final Map<int, DateTime> _pointerDownTimes = {};
  final Map<int, Offset> _pointerDownPositions = {};
  final Map<int, bool> _pointerMovedFlags = {};
  bool _precisionMode = false;

  // Drag & Block Text State
  bool _isDragging = false;
  int? _activeDragPointer;
  DateTime? _lastTapUpTime;
  Offset? _lastTapUpPosition;
  Timer? _longPressDragTimer;

  // Bottom Physical Buttons Hold State
  bool _isLeftButtonHeld = false;
  bool _isMiddleButtonHeld = false;
  bool _isRightButtonHeld = false;

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
    _longPressDragTimer?.cancel();
    // Safety release: ensure no mouse button remains stuck on host
    if (_isDragging || _isLeftButtonHeld) {
      _connService.sendCommand(InputCommand.mouseUp('left'));
    }
    if (_isRightButtonHeld) {
      _connService.sendCommand(InputCommand.mouseUp('right'));
    }
    if (_isMiddleButtonHeld) {
      _connService.sendCommand(InputCommand.mouseUp('middle'));
    }
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;
    _lastPointerPositions[event.pointer] = event.localPosition;
    _pointerDownTimes[event.pointer] = DateTime.now();
    _pointerDownPositions[event.pointer] = event.localPosition;
    _pointerMovedFlags[event.pointer] = false;

    // Check for Double-Tap & Drag (tap once, then tap down within 350ms and drag)
    if (_pointerPositions.length == 1) {
      final now = DateTime.now();
      if (_lastTapUpTime != null && _lastTapUpPosition != null) {
        final elapsed = now.difference(_lastTapUpTime!).inMilliseconds;
        final dist = (event.localPosition - _lastTapUpPosition!).distance;
        if (elapsed < 350 && dist < 45.0) {
          // Double-tap drag sequence activated!
          _isDragging = true;
          _activeDragPointer = event.pointer;
          _connService.sendCommand(InputCommand.mouseDown('left'));
          HapticHelper.mediumImpact();
          _lastTapUpTime = null;
          _lastTapUpPosition = null;
          setState(() {});
          return;
        }
      }

      // Tap-and-hold to drag timer (380ms)
      _longPressDragTimer?.cancel();
      _longPressDragTimer = Timer(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        if (_pointerPositions.length == 1 &&
            _pointerPositions.containsKey(event.pointer) &&
            !(_pointerMovedFlags[event.pointer] ?? false) &&
            !_isDragging) {
          _isDragging = true;
          _activeDragPointer = event.pointer;
          _connService.sendCommand(InputCommand.mouseDown('left'));
          HapticHelper.heavyImpact();
          setState(() {});
        }
      });
    } else {
      // 2 or more fingers cancels single finger long press
      _longPressDragTimer?.cancel();
    }

    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    final prev = _lastPointerPositions[event.pointer] ?? event.localPosition;
    final delta = event.localPosition - prev;
    _lastPointerPositions[event.pointer] = event.localPosition;
    _pointerPositions[event.pointer] = event.localPosition;

    final downPos = _pointerDownPositions[event.pointer] ?? event.localPosition;
    if ((event.localPosition - downPos).distance > 8.0) {
      _pointerMovedFlags[event.pointer] = true;
      _longPressDragTimer?.cancel();
    }

    setState(() {});

    final activeCount = _pointerPositions.length;
    final sensitivity = _precisionMode ? 0.6 : _settings.mouseSensitivity;

    if (activeCount == 1) {
      // Single finger: Accumulate mouse move (left button is held if dragging or left button held)
      _accumulatedDx += delta.dx * sensitivity;
      _accumulatedDy += delta.dy * sensitivity;
    } else if (activeCount >= 2) {
      // Two fingers: Smooth scroll
      if (_isDragging) {
        _isDragging = false;
        _activeDragPointer = null;
        _connService.sendCommand(InputCommand.mouseUp('left'));
      }
      final scrollFactor = 0.08 * _settings.scrollSensitivity;
      _accumulatedScrollY += delta.dy * scrollFactor;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _longPressDragTimer?.cancel();

    final downTime = _pointerDownTimes[event.pointer];
    final downPos = _pointerDownPositions[event.pointer];
    final hasMoved = _pointerMovedFlags[event.pointer] ?? false;
    final durationMs = downTime != null ? DateTime.now().difference(downTime).inMilliseconds : 999;
    final totalDist = downPos != null ? (event.localPosition - downPos).distance : 999.0;
    final activeCountAtUp = _pointerPositions.length;

    // Clean up tracking maps
    _pointerPositions.remove(event.pointer);
    _lastPointerPositions.remove(event.pointer);
    _pointerDownTimes.remove(event.pointer);
    _pointerDownPositions.remove(event.pointer);
    _pointerMovedFlags.remove(event.pointer);

    // If this pointer was in drag mode, release mouse button
    if (_isDragging && _activeDragPointer == event.pointer) {
      _isDragging = false;
      _activeDragPointer = null;
      _connService.sendCommand(InputCommand.mouseUp('left'));
      HapticHelper.lightImpact();
      _lastTapUpTime = null;
      _lastTapUpPosition = null;
      setState(() {});
      return;
    }

    // Check for stationary tap (<14px movement, <320ms duration)
    if (!hasMoved && totalDist < 14.0 && durationMs < 320) {
      if (activeCountAtUp == 2) {
        // Two-finger tap -> Right Click (Laptop trackpad standard)
        HapticHelper.mediumImpact();
        _connService.sendCommand(InputCommand.click('right'));
        _lastTapUpTime = null;
        _lastTapUpPosition = null;
      } else if (activeCountAtUp == 1) {
        // Single finger tap -> Left Click
        HapticHelper.lightImpact();
        _connService.sendCommand(InputCommand.click('left'));
        _lastTapUpTime = DateTime.now();
        _lastTapUpPosition = event.localPosition;
      }
    }

    setState(() {});
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _longPressDragTimer?.cancel();
    if (_isDragging) {
      _isDragging = false;
      _activeDragPointer = null;
      _connService.sendCommand(InputCommand.mouseUp('left'));
    }
    _pointerPositions.clear();
    _lastPointerPositions.clear();
    _pointerDownTimes.clear();
    _pointerDownPositions.clear();
    _pointerMovedFlags.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDragActive = _isDragging || _isLeftButtonHeld;

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
              border: Border.all(
                color: isDragActive ? AppColors.primary : AppColors.border,
                width: isDragActive ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDragActive ? AppColors.primary.withAlpha(60) : Colors.black.withAlpha(80),
                  blurRadius: isDragActive ? 16 : 12,
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
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    // Subdued Grid pattern lines
                    CustomPaint(
                      size: Size.infinite,
                      painter: GridPainter(),
                    ),

                    // Multi-Touch Ripple Visual Indicators (renders a circle for each finger)
                    for (final entry in _pointerPositions.entries)
                      Positioned(
                        left: entry.value.dx - 26,
                        top: entry.value.dy - 26,
                        child: IgnorePointer(
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_isDragging && entry.key == _activeDragPointer)
                                  ? AppColors.primary.withAlpha(120)
                                  : AppColors.touchRipple,
                              border: Border.all(
                                color: (_isDragging && entry.key == _activeDragPointer)
                                    ? Colors.white
                                    : AppColors.primaryLight,
                                width: (_isDragging && entry.key == _activeDragPointer) ? 2.5 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(
                                    (_isDragging && entry.key == _activeDragPointer) ? 140 : 70,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: (_isDragging && entry.key == _activeDragPointer)
                                ? const Center(
                                    child: Icon(Icons.drag_indicator, size: 20, color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                      ),

                    // Center gesture guide text
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDragActive ? Icons.select_all : Icons.mouse,
                            size: 32,
                            color: isDragActive ? AppColors.primary : AppColors.textMuted.withAlpha(50),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1 Finger: Move  •  2 Fingers: Scroll\nDouble-Tap & Slide or Hold Left Click: Select / Block Text\n2-Finger Tap: Right Click',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textMuted.withAlpha(130),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floating Drag & Block Indicator Badge
                    if (isDragActive)
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(140),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.select_all, size: 15, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'BLOCK / DRAG MODE ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
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
              // Left Click Button (Supports Hold-to-Drag for Blocking Text)
              Expanded(
                flex: 4,
                child: Listener(
                  onPointerDown: (_) {
                    HapticHelper.mediumImpact();
                    setState(() => _isLeftButtonHeld = true);
                    _connService.sendCommand(InputCommand.mouseDown('left'));
                  },
                  onPointerUp: (_) {
                    HapticHelper.lightImpact();
                    setState(() => _isLeftButtonHeld = false);
                    _connService.sendCommand(InputCommand.mouseUp('left'));
                  },
                  onPointerCancel: (_) {
                    setState(() => _isLeftButtonHeld = false);
                    _connService.sendCommand(InputCommand.mouseUp('left'));
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isLeftButtonHeld ? AppColors.primary : AppColors.surfaceElevated,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      border: Border.all(
                        color: _isLeftButtonHeld ? AppColors.primaryLight : AppColors.border,
                        width: _isLeftButtonHeld ? 2 : 1,
                      ),
                      boxShadow: _isLeftButtonHeld
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(90),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 18,
                          color: _isLeftButtonHeld ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Left Click',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isLeftButtonHeld ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Middle / Scroll Lock Button
              Expanded(
                flex: 2,
                child: Listener(
                  onPointerDown: (_) {
                    HapticHelper.mediumImpact();
                    setState(() => _isMiddleButtonHeld = true);
                    _connService.sendCommand(InputCommand.mouseDown('middle'));
                  },
                  onPointerUp: (_) {
                    HapticHelper.lightImpact();
                    setState(() => _isMiddleButtonHeld = false);
                    _connService.sendCommand(InputCommand.mouseUp('middle'));
                  },
                  onPointerCancel: (_) {
                    setState(() => _isMiddleButtonHeld = false);
                    _connService.sendCommand(InputCommand.mouseUp('middle'));
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isMiddleButtonHeld ? AppColors.surfaceElevated.withAlpha(200) : AppColors.surfaceElevated,
                      border: Border.all(
                        color: _isMiddleButtonHeld ? AppColors.textSecondary : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.unfold_more,
                      size: 20,
                      color: _isMiddleButtonHeld ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Right Click Button
              Expanded(
                flex: 4,
                child: Listener(
                  onPointerDown: (_) {
                    HapticHelper.heavyImpact();
                    setState(() => _isRightButtonHeld = true);
                    _connService.sendCommand(InputCommand.mouseDown('right'));
                  },
                  onPointerUp: (_) {
                    HapticHelper.lightImpact();
                    setState(() => _isRightButtonHeld = false);
                    _connService.sendCommand(InputCommand.mouseUp('right'));
                  },
                  onPointerCancel: (_) {
                    setState(() => _isRightButtonHeld = false);
                    _connService.sendCommand(InputCommand.mouseUp('right'));
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isRightButtonHeld ? AppColors.accent : AppColors.surfaceElevated,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                      border: Border.all(
                        color: _isRightButtonHeld ? AppColors.accent : AppColors.border,
                        width: _isRightButtonHeld ? 2 : 1,
                      ),
                      boxShadow: _isRightButtonHeld
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withAlpha(90),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Right Click',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isRightButtonHeld ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.mouse,
                          size: 18,
                          color: _isRightButtonHeld ? Colors.white : AppColors.accent,
                        ),
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
