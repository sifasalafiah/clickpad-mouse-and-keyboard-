import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/gamepad_mapping.dart';
import '../services/gamepad_mapping_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

enum JoystickMode { wasd, arrows }

class VirtualJoystickWidget extends StatefulWidget {
  final double size;
  final JoystickMode mode;
  final ValueChanged<List<int>> onDirectionChanged;

  const VirtualJoystickWidget({
    super.key,
    this.size = 180.0,
    this.mode = JoystickMode.wasd,
    required this.onDirectionChanged,
  });

  @override
  State<VirtualJoystickWidget> createState() => _VirtualJoystickWidgetState();
}

class _VirtualJoystickWidgetState extends State<VirtualJoystickWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _centerController;
  late Animation<Offset> _centerAnimation;

  Offset _thumbPosition = Offset.zero;
  List<int> _activeKeycodes = [];

  // Scancode Mappings
  int get _keyUp => widget.mode == JoystickMode.wasd
      ? GamepadMappingService.instance.getScancode(GamepadButtonId.dpadUp)
      : 0x52;
  int get _keyLeft => widget.mode == JoystickMode.wasd
      ? GamepadMappingService.instance.getScancode(GamepadButtonId.dpadLeft)
      : 0x50;
  int get _keyDown => widget.mode == JoystickMode.wasd
      ? GamepadMappingService.instance.getScancode(GamepadButtonId.dpadDown)
      : 0x51;
  int get _keyRight => widget.mode == JoystickMode.wasd
      ? GamepadMappingService.instance.getScancode(GamepadButtonId.dpadRight)
      : 0x4F;

  @override
  void initState() {
    super.initState();
    _centerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        setState(() {
          _thumbPosition = _centerAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _centerController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _centerController.stop();
    _updateThumbPosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateThumbPosition(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _centerAnimation = Tween<Offset>(
      begin: _thumbPosition,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _centerController,
      curve: Curves.easeOutCubic,
    ));
    _centerController.forward(from: 0.0);

    _updateActiveKeycodes([]);
  }

  void _updateThumbPosition(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = localPos - center;
    final maxRadius = widget.size / 2 - 30;

    final distance = delta.distance;
    final angle = delta.direction;

    final clampedDistance = math.min(distance, maxRadius);
    final newThumbPos = Offset(
      clampedDistance * math.cos(angle),
      clampedDistance * math.sin(angle),
    );

    setState(() {
      _thumbPosition = newThumbPos;
    });

    // Calculate Directional Keycodes
    if (clampedDistance > 15.0) {
      final List<int> newKeys = [];
      final deg = angle * 180 / math.pi;

      // 8-directional layout mapping
      if (deg >= -157.5 && deg < -112.5) {
        // Up-Left
        newKeys.addAll([_keyUp, _keyLeft]);
      } else if (deg >= -112.5 && deg < -67.5) {
        // Up
        newKeys.add(_keyUp);
      } else if (deg >= -67.5 && deg < -22.5) {
        // Up-Right
        newKeys.addAll([_keyUp, _keyRight]);
      } else if (deg >= -22.5 && deg < 22.5) {
        // Right
        newKeys.add(_keyRight);
      } else if (deg >= 22.5 && deg < 67.5) {
        // Down-Right
        newKeys.addAll([_keyDown, _keyRight]);
      } else if (deg >= 67.5 && deg < 112.5) {
        // Down
        newKeys.add(_keyDown);
      } else if (deg >= 112.5 && deg < 157.5) {
        // Down-Left
        newKeys.addAll([_keyDown, _keyLeft]);
      } else {
        // Left
        newKeys.add(_keyLeft);
      }

      _updateActiveKeycodes(newKeys);
    } else {
      _updateActiveKeycodes([]);
    }
  }

  void _updateActiveKeycodes(List<int> newKeys) {
    bool changed = false;
    if (newKeys.length != _activeKeycodes.length) {
      changed = true;
    } else {
      for (int i = 0; i < newKeys.length; i++) {
        if (newKeys[i] != _activeKeycodes[i]) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      if (newKeys.isNotEmpty) {
        HapticHelper.selectionClick();
      }
      _activeKeycodes = newKeys;
      widget.onDirectionChanged(newKeys);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.palette.isLight
              ? AppColors.touchpadCanvas
              : const Color(0xFF1E293B).withAlpha(180),
          border: Border.all(
            color: _activeKeycodes.isNotEmpty
                ? AppColors.primary
                : AppColors.border,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _activeKeycodes.isNotEmpty
                  ? AppColors.primary.withAlpha(60)
                  : (AppColors.palette.isLight
                      ? Colors.black.withAlpha(15)
                      : Colors.black.withAlpha(80)),
              blurRadius: 14,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Directional Indicators (N, S, E, W marks)
            Positioned(
              top: 10,
              child: Text(
                widget.mode == JoystickMode.wasd ? 'W' : '▲',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _activeKeycodes.contains(_keyUp)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              child: Text(
                widget.mode == JoystickMode.wasd ? 'S' : '▼',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _activeKeycodes.contains(_keyDown)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
            Positioned(
              left: 10,
              child: Text(
                widget.mode == JoystickMode.wasd ? 'A' : '◄',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _activeKeycodes.contains(_keyLeft)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
            Positioned(
              right: 10,
              child: Text(
                widget.mode == JoystickMode.wasd ? 'D' : '►',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _activeKeycodes.contains(_keyRight)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),

            // Inner Thumb Knob (Matching Layout Model with Navigation Arrow)
            Transform.translate(
              offset: _thumbPosition,
              child: Container(
                width: widget.size * 0.38,
                height: widget.size * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withAlpha(_activeKeycodes.isNotEmpty ? 170 : 100),
                      blurRadius: _activeKeycodes.isNotEmpty ? 16 : 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: widget.size * 0.16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
