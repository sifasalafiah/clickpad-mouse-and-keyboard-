import 'dart:async';
import 'package:flutter/material.dart';
import '../models/input_command.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

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

  // Shortcut & Native Keyboard State
  bool? _manualMacMode;
  final TextEditingController _nativeTextController = TextEditingController();
  final FocusNode _nativeKeyboardFocusNode = FocusNode();
  bool _isNativeKeyboardOpen = false;
  String _prevText = '';
  final List<_KeyStroke> _keyQueue = [];
  bool _isSendingKeys = false;

  bool get _isMacMode {
    if (_manualMacMode != null) return _manualMacMode!;
    final name =
        (ConnectionService.instance.connectedDevice?.name ??
                SettingsService.instance.lastDeviceName)
            .toLowerCase();
    return name.contains('mac') ||
        name.contains('apple') ||
        name.contains('darwin');
  }

  // High-frequency 80Hz Input Frame Accumulator for Zero Latency
  double _accumulatedDx = 0.0;
  double _accumulatedDy = 0.0;
  double _accumulatedScrollY = 0.0;
  Timer? _flushTimer;

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);
    _settings.addListener(_onSettingsChanged);
    _nativeKeyboardFocusNode.addListener(_onKeyboardFocusChange);
    // Flush input deltas every 12ms (~83Hz smooth input frame rate)
    _flushTimer = Timer.periodic(const Duration(milliseconds: 12), (_) {
      if (_accumulatedDx != 0.0 || _accumulatedDy != 0.0) {
        _connService.sendCommand(
          InputCommand.move(_accumulatedDx, _accumulatedDy),
        );
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

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIapChanged);
    _settings.removeListener(_onSettingsChanged);
    _nativeKeyboardFocusNode.removeListener(_onKeyboardFocusChange);
    _nativeKeyboardFocusNode.dispose();
    _nativeTextController.dispose();
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
    final durationMs = downTime != null
        ? DateTime.now().difference(downTime).inMilliseconds
        : 999;
    final totalDist = downPos != null
        ? (event.localPosition - downPos).distance
        : 999.0;
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
    final buttonHeight = _isNativeKeyboardOpen ? 40.0 : 54.0;

    return Column(
      children: [
        // Top Info & Quick Bar
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: _isNativeKeyboardOpen ? 2 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Info & Mode Indicator
              Row(
                children: [
                  Icon(
                    _precisionMode ? Icons.track_changes : Icons.touch_app,
                    size: 16,
                    color: _precisionMode ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _precisionMode ? 'Precision Mode (Low Sens)' : 'Touchpad Canvas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _precisionMode ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Right: Action Buttons (Precision Mode + Fullscreen Toggle)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Precision Mode Toggle (Distinct target crosshair icon & visual feedback)
                  InkWell(
                    onTap: () {
                      HapticHelper.selectionClick();
                      setState(() => _precisionMode = !_precisionMode);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _precisionMode
                            ? AppColors.primary.withAlpha(AppColors.palette.isLight ? 40 : 30)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _precisionMode ? AppColors.primary : AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.track_changes,
                            size: 15,
                            color: _precisionMode ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Precision',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _precisionMode ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Fullscreen Toggle Button
                  InkWell(
                    onTap: () {
                      HapticHelper.mediumImpact();
                      _settings.toggleFullScreen();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _settings.isFullScreen
                            ? AppColors.primary.withAlpha(AppColors.palette.isLight ? 40 : 30)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _settings.isFullScreen ? AppColors.primary : AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        _settings.isFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        size: 18,
                        color: _settings.isFullScreen ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
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
                  color: isDragActive
                      ? AppColors.primary.withAlpha(60)
                      : Colors.black.withAlpha(80),
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
                child: LayoutBuilder(
                  builder: (context, canvasConstraints) {
                    return Stack(
                      children: [
                        // Subdued Grid pattern lines
                        CustomPaint(
                          size: Size.infinite,
                          painter: GridPainter(gridColor: AppColors.borderSubtle),
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
                              color:
                                  (_isDragging &&
                                      entry.key == _activeDragPointer)
                                  ? AppColors.primary.withAlpha(120)
                                  : AppColors.touchRipple,
                              border: Border.all(
                                color:
                                    (_isDragging &&
                                        entry.key == _activeDragPointer)
                                    ? Colors.white
                                    : AppColors.primaryLight,
                                width:
                                    (_isDragging &&
                                        entry.key == _activeDragPointer)
                                    ? 2.5
                                    : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(
                                    (_isDragging &&
                                            entry.key == _activeDragPointer)
                                        ? 140
                                        : 70,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child:
                                (_isDragging && entry.key == _activeDragPointer)
                                ? const Center(
                                    child: Icon(
                                      Icons.drag_indicator,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                    // Center gesture guide text (Hidden when keyboard is open or canvas is constrained)
                    if (!_isNativeKeyboardOpen && canvasConstraints.maxHeight >= 100)
                      Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDragActive ? Icons.select_all : Icons.mouse,
                                size: 32,
                                color: isDragActive
                                    ? AppColors.primary
                                    : AppColors.textMuted.withAlpha(50),
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
                      ),

                    // Floating Drag & Block Indicator Badge
                    if (isDragActive)
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
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
                                Icon(
                                  Icons.select_all,
                                  size: 15,
                                  color: Colors.white,
                                ),
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
                );
              },
            ),
          ),
        ),
      ),
    ),
    SizedBox(height: _isNativeKeyboardOpen ? 6 : 12),

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
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _isLeftButtonHeld
                          ? AppColors.primary
                          : AppColors.surfaceElevated,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: _isLeftButtonHeld
                            ? AppColors.primaryLight
                            : AppColors.border,
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
                          color: _isLeftButtonHeld
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Left Click',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isLeftButtonHeld
                                ? Colors.white
                                : AppColors.textPrimary,
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
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _isMiddleButtonHeld
                          ? AppColors.surfaceElevated.withAlpha(200)
                          : AppColors.surfaceElevated,
                      border: Border.all(
                        color: _isMiddleButtonHeld
                            ? AppColors.textSecondary
                            : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.unfold_more,
                      size: 20,
                      color: _isMiddleButtonHeld
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _isRightButtonHeld
                          ? AppColors.accent
                          : AppColors.surfaceElevated,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: _isRightButtonHeld
                            ? AppColors.accent
                            : AppColors.border,
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
                            color: _isRightButtonHeld
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.mouse,
                          size: 18,
                          color: _isRightButtonHeld
                              ? Colors.white
                              : AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _isNativeKeyboardOpen ? 4 : 8),

        // Native Keyboard Input Bar (Visible when Keyboard mode is active)
        if (_isNativeKeyboardOpen)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.keyboard_alt, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _nativeTextController,
                      focusNode: _nativeKeyboardFocusNode,
                      autofocus: true,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type on native keyboard to send to PC...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withAlpha(150),
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onNativeKeyboardInput,
                      onSubmitted: (_) => _onNativeKeyboardEnter(),
                    ),
                  ),
                  if (_nativeTextController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticHelper.selectionClick();
                        _nativeTextController.clear();
                        _prevText = '';
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  // Quick Backspace button
                  GestureDetector(
                    onTap: _sendBackspace,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  // Quick Enter button
                  GestureDetector(
                    onTap: _onNativeKeyboardEnter,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.keyboard_return,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _closeNativeKeyboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Shortcut Action Bar: Copy, Paste, Keyboard Icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Copy Button (Ctrl+C / Cmd+C)
              Expanded(
                child: _buildShortcutButton(
                  label: _isMacMode ? 'Cmd + C' : 'Ctrl + C',
                  icon: Icons.copy_rounded,
                  onTap: _sendCopy,
                ),
              ),
              const SizedBox(width: 8),

              // Paste Button (Ctrl+V / Cmd+V)
              Expanded(
                child: _buildShortcutButton(
                  label: _isMacMode ? 'Cmd + V' : 'Ctrl + V',
                  icon: Icons.paste_rounded,
                  onTap: _sendPaste,
                ),
              ),
              const SizedBox(width: 8),

              // Native Keyboard Trigger Button
              Expanded(
                child: _buildShortcutButton(
                  label: 'Keyboard',
                  icon: Icons.keyboard_rounded,
                  isActive: _isNativeKeyboardOpen,
                  onTap: _toggleNativeKeyboard,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _isNativeKeyboardOpen ? 4 : 12),
      ],
    );
  }

  void _onKeyboardFocusChange() {
    if (!_nativeKeyboardFocusNode.hasFocus && _isNativeKeyboardOpen) {
      if (mounted) {
        setState(() {
          _isNativeKeyboardOpen = false;
          _nativeTextController.clear();
          _prevText = '';
        });
      }
    }
  }

  void _closeNativeKeyboard() {
    HapticHelper.selectionClick();
    _nativeKeyboardFocusNode.unfocus();
    setState(() {
      _isNativeKeyboardOpen = false;
      _nativeTextController.clear();
      _prevText = '';
    });
  }

  Future<void> _sendShortcut(int keycode) async {
    HapticHelper.mediumImpact();
    // 0x08 = Left GUI / Command (macOS), 0x01 = Left Ctrl (Windows / Linux)
    final modifier = _isMacMode ? 0x08 : 0x01;

    // 1. Modifier down
    BluetoothBleService.instance.sendKeyboardState(modifier, []);
    await Future.delayed(const Duration(milliseconds: 25));

    // 2. Key down with modifier held (hold 65ms for OS chord registration)
    BluetoothBleService.instance.sendKeyboardState(modifier, [keycode]);
    await Future.delayed(const Duration(milliseconds: 65));

    // 3. Key up, modifier still held
    BluetoothBleService.instance.sendKeyboardState(modifier, []);
    await Future.delayed(const Duration(milliseconds: 25));

    // 4. Release all
    BluetoothBleService.instance.sendKeyboardState(0, []);
  }

  void _sendCopy() {
    _sendShortcut(0x06); // 'c'
  }

  void _sendPaste() {
    _sendShortcut(0x19); // 'v'
  }

  void _toggleNativeKeyboard() {
    HapticHelper.selectionClick();
    if (_isNativeKeyboardOpen) {
      _closeNativeKeyboard();
    } else {
      setState(() {
        _isNativeKeyboardOpen = true;
        _nativeTextController.clear();
        _prevText = '';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nativeKeyboardFocusNode.requestFocus();
      });
    }
  }

  void _onNativeKeyboardInput(String newText) {
    if (newText == _prevText) return;

    // Find common prefix length
    int prefixLen = 0;
    while (prefixLen < _prevText.length &&
        prefixLen < newText.length &&
        _prevText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // Number of characters deleted from _prevText
    final numDeleted = _prevText.length - prefixLen;
    for (int i = 0; i < numDeleted; i++) {
      _sendKey(0x00, 0x2A); // Backspace HID keycode
    }

    // Characters added in newText
    final addedChars = newText.substring(prefixLen);
    for (int i = 0; i < addedChars.length; i++) {
      _sendCharToHost(addedChars[i]);
    }

    _prevText = newText;
  }

  void _onNativeKeyboardEnter() {
    HapticHelper.lightImpact();
    _sendKey(0x00, 0x28); // Enter HID keycode
    _nativeTextController.clear();
    _prevText = '';
    setState(() {});
  }

  void _sendBackspace() {
    HapticHelper.lightImpact();
    _sendKey(0x00, 0x2A);
    if (_nativeTextController.text.isNotEmpty) {
      final t = _nativeTextController.text;
      _nativeTextController.text = t.substring(0, t.length - 1);
      _prevText = _nativeTextController.text;
      setState(() {});
    }
  }

  void _sendCharToHost(String char) {
    final stroke = _charToKeyStroke(char);
    if (stroke != null) {
      _sendKey(stroke.modifier, stroke.keycode);
    }
  }

  void _sendKey(int modifier, int keycode) {
    _keyQueue.add(_KeyStroke(modifier, keycode));
    _processKeyQueue();
  }

  void _processKeyQueue() async {
    if (_isSendingKeys || _keyQueue.isEmpty) return;
    _isSendingKeys = true;
    while (_keyQueue.isNotEmpty) {
      final stroke = _keyQueue.removeAt(0);
      BluetoothBleService.instance.sendKeyboardScancode(
        stroke.modifier,
        stroke.keycode,
      );
      await Future.delayed(const Duration(milliseconds: 25));
    }
    _isSendingKeys = false;
  }

  Widget _buildShortcutButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withAlpha(40)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primary : AppColors.primaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyStroke {
  final int modifier;
  final int keycode;
  const _KeyStroke(this.modifier, this.keycode);
}

_KeyStroke? _charToKeyStroke(String char) {
  if (char.isEmpty) return null;
  final codeUnit = char.codeUnitAt(0);

  // Lowercase a-z (0x61 - 0x7A) -> HID 0x04 - 0x1D
  if (codeUnit >= 0x61 && codeUnit <= 0x7A) {
    return _KeyStroke(0x00, 0x04 + (codeUnit - 0x61));
  }

  // Uppercase A-Z (0x41 - 0x5A) -> HID 0x04 - 0x1D with Shift (0x02)
  if (codeUnit >= 0x41 && codeUnit <= 0x5A) {
    return _KeyStroke(0x02, 0x04 + (codeUnit - 0x41));
  }

  // Digits 1-9 -> HID 0x1E - 0x26, 0 -> 0x27
  if (codeUnit >= 0x31 && codeUnit <= 0x39) {
    return _KeyStroke(0x00, 0x1E + (codeUnit - 0x31));
  }
  if (char == '0') return const _KeyStroke(0x00, 0x27);

  // Whitespace
  if (char == ' ') return const _KeyStroke(0x00, 0x2C);
  if (char == '\n' || char == '\r') return const _KeyStroke(0x00, 0x28);
  if (char == '\t') return const _KeyStroke(0x00, 0x2B);

  // Symbols
  switch (char) {
    case '!':
      return const _KeyStroke(0x02, 0x1E);
    case '@':
      return const _KeyStroke(0x02, 0x1F);
    case '#':
      return const _KeyStroke(0x02, 0x20);
    case '\$':
      return const _KeyStroke(0x02, 0x21);
    case '%':
      return const _KeyStroke(0x02, 0x22);
    case '^':
      return const _KeyStroke(0x02, 0x23);
    case '&':
      return const _KeyStroke(0x02, 0x24);
    case '*':
      return const _KeyStroke(0x02, 0x25);
    case '(':
      return const _KeyStroke(0x02, 0x26);
    case ')':
      return const _KeyStroke(0x02, 0x27);
    case '-':
      return const _KeyStroke(0x00, 0x2D);
    case '_':
      return const _KeyStroke(0x02, 0x2D);
    case '=':
      return const _KeyStroke(0x00, 0x2E);
    case '+':
      return const _KeyStroke(0x02, 0x2E);
    case '[':
      return const _KeyStroke(0x00, 0x2F);
    case '{':
      return const _KeyStroke(0x02, 0x2F);
    case ']':
      return const _KeyStroke(0x00, 0x30);
    case '}':
      return const _KeyStroke(0x02, 0x30);
    case '\\':
      return const _KeyStroke(0x00, 0x31);
    case '|':
      return const _KeyStroke(0x02, 0x31);
    case ';':
      return const _KeyStroke(0x00, 0x33);
    case ':':
      return const _KeyStroke(0x02, 0x33);
    case '\'':
      return const _KeyStroke(0x00, 0x34);
    case '"':
      return const _KeyStroke(0x02, 0x34);
    case '`':
      return const _KeyStroke(0x00, 0x35);
    case '~':
      return const _KeyStroke(0x02, 0x35);
    case ',':
      return const _KeyStroke(0x00, 0x36);
    case '<':
      return const _KeyStroke(0x02, 0x36);
    case '.':
      return const _KeyStroke(0x00, 0x37);
    case '>':
      return const _KeyStroke(0x02, 0x37);
    case '/':
      return const _KeyStroke(0x00, 0x38);
    case '?':
      return const _KeyStroke(0x02, 0x38);
    default:
      return null;
  }
}

class GridPainter extends CustomPainter {
  final Color gridColor;

  const GridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
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
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}
