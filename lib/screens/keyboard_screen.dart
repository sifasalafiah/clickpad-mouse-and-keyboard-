import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/banner_ad_widget.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final ConnectionService _connService = ConnectionService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;

  bool _isShiftActive = false;
  bool _isCapsLocked = false;
  bool _isCtrlActive = false;
  bool _isAltActive = false;
  bool _isCmdActive = false;
  bool _isFnActive = false;

  @override
  void initState() {
    super.initState();
    // Allow landscape orientation for maximum width
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  int get _modifierMask {
    int mask = 0;
    if (_isCtrlActive) mask |= 0x01;
    if (_isShiftActive || _isCapsLocked) mask |= 0x02;
    if (_isAltActive) mask |= 0x04;
    if (_isCmdActive) mask |= 0x08;
    return mask;
  }

  void _onKeyPress(String keyLabel, int keycode) {
    HapticHelper.lightImpact();

    // Send native HID Scancode
    _bleService.sendKeyboardScancode(_modifierMask, keycode);

    // Immediately reset modifier keys like a real physical keyboard (no sticky latches)
    if (_isShiftActive || _isCtrlActive || _isAltActive || _isCmdActive) {
      setState(() {
        _isShiftActive = false;
        _isCtrlActive = false;
        _isAltActive = false;
        _isCmdActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUppercase = _isShiftActive || _isCapsLocked;
    final size = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    Widget keyboardBody = Container(
      color: const Color(0xFF14171A), // Sleek Pebble Dark Matte Finish
      padding: const EdgeInsets.all(8),
      child: SafeArea(
        child: Column(
          children: [
            // Collapsible Banner Ad at Top of Keyboard
            const CollapsibleBannerAdWidget(collapsiblePosition: 'top'),

            // ClickPad Keyboard Header Branding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.keyboard, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'ClickPad Keyboard',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildIndicatorDot('1', true),
                      const SizedBox(width: 6),
                      _buildIndicatorDot('2', false),
                      const SizedBox(width: 6),
                      _buildIndicatorDot('3', false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Pebble Keyboard Body Frame
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2328),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2D3239), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Row 0: Function Keys Bar
                    Expanded(
                      child: _buildRow([
                        _PebbleKey('esc', 0x29, flex: 1, isAction: true),
                        _PebbleKey(
                          'F1',
                          0x3A,
                          flex: 1,
                          isEasySwitch: true,
                          switchNum: '1',
                        ),
                        _PebbleKey(
                          'F2',
                          0x3B,
                          flex: 1,
                          isEasySwitch: true,
                          switchNum: '2',
                        ),
                        _PebbleKey(
                          'F3',
                          0x3C,
                          flex: 1,
                          isEasySwitch: true,
                          switchNum: '3',
                        ),
                        _PebbleKey('F4', 0x3D, flex: 1, icon: Icons.volume_off),
                        _PebbleKey(
                          'F5',
                          0x3E,
                          flex: 1,
                          icon: Icons.volume_down,
                        ),
                        _PebbleKey('F6', 0x3F, flex: 1, icon: Icons.volume_up),
                        _PebbleKey(
                          'F7',
                          0x40,
                          flex: 1,
                          icon: Icons.skip_previous,
                        ),
                        _PebbleKey('F8', 0x41, flex: 1, icon: Icons.play_arrow),
                        _PebbleKey('F9', 0x42, flex: 1, icon: Icons.skip_next),
                        _PebbleKey('F10', 0x43, flex: 1, icon: Icons.search),
                        _PebbleKey('F11', 0x44, flex: 1, icon: Icons.mic),
                        _PebbleKey('F12', 0x45, flex: 1, icon: Icons.lock),
                        _PebbleKey('del', 0x4C, flex: 1, isAction: true),
                      ]),
                    ),
                    const SizedBox(height: 4),

                    // Row 1: Number Row
                    Expanded(
                      child: _buildRow([
                        _PebbleKey(isUppercase ? '~' : '`', 0x35, flex: 1),
                        _PebbleKey(isUppercase ? '!' : '1', 0x1E, flex: 1),
                        _PebbleKey(isUppercase ? '@' : '2', 0x1F, flex: 1),
                        _PebbleKey(isUppercase ? '#' : '3', 0x20, flex: 1),
                        _PebbleKey(isUppercase ? '\$' : '4', 0x21, flex: 1),
                        _PebbleKey(isUppercase ? '%' : '5', 0x22, flex: 1),
                        _PebbleKey(isUppercase ? '^' : '6', 0x23, flex: 1),
                        _PebbleKey(isUppercase ? '&' : '7', 0x24, flex: 1),
                        _PebbleKey(isUppercase ? '*' : '8', 0x25, flex: 1),
                        _PebbleKey(isUppercase ? '(' : '9', 0x26, flex: 1),
                        _PebbleKey(isUppercase ? ')' : '0', 0x27, flex: 1),
                        _PebbleKey(isUppercase ? '_' : '-', 0x2D, flex: 1),
                        _PebbleKey(isUppercase ? '+' : '=', 0x2E, flex: 1),
                        _PebbleKey('⌫', 0x2A, flex: 2, isAction: true),
                      ]),
                    ),
                    const SizedBox(height: 4),

                    // Row 2: QWERTY Row
                    Expanded(
                      child: _buildRow([
                        _PebbleKey('tab', 0x2B, flex: 2, isAction: true),
                        _PebbleKey(isUppercase ? 'Q' : 'q', 0x14, flex: 1),
                        _PebbleKey(isUppercase ? 'W' : 'w', 0x1A, flex: 1),
                        _PebbleKey(isUppercase ? 'E' : 'e', 0x08, flex: 1),
                        _PebbleKey(isUppercase ? 'R' : 'r', 0x15, flex: 1),
                        _PebbleKey(isUppercase ? 'T' : 't', 0x17, flex: 1),
                        _PebbleKey(isUppercase ? 'Y' : 'y', 0x1C, flex: 1),
                        _PebbleKey(isUppercase ? 'U' : 'u', 0x18, flex: 1),
                        _PebbleKey(isUppercase ? 'I' : 'i', 0x0C, flex: 1),
                        _PebbleKey(isUppercase ? 'O' : 'o', 0x12, flex: 1),
                        _PebbleKey(isUppercase ? 'P' : 'p', 0x13, flex: 1),
                        _PebbleKey(isUppercase ? '{' : '[', 0x2F, flex: 1),
                        _PebbleKey(isUppercase ? '}' : ']', 0x30, flex: 1),
                        _PebbleKey(isUppercase ? '|' : '\\', 0x31, flex: 1),
                      ]),
                    ),
                    const SizedBox(height: 4),

                    // Row 3: Home Row
                    Expanded(
                      child: _buildRow([
                        _PebbleKey(
                          'caps',
                          0x39,
                          flex: 2,
                          isActive: _isCapsLocked,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isCapsLocked = !_isCapsLocked);
                          },
                        ),
                        _PebbleKey(isUppercase ? 'A' : 'a', 0x04, flex: 1),
                        _PebbleKey(isUppercase ? 'S' : 's', 0x16, flex: 1),
                        _PebbleKey(isUppercase ? 'D' : 'd', 0x07, flex: 1),
                        _PebbleKey(isUppercase ? 'F' : 'f', 0x09, flex: 1),
                        _PebbleKey(isUppercase ? 'G' : 'g', 0x0A, flex: 1),
                        _PebbleKey(isUppercase ? 'H' : 'h', 0x0B, flex: 1),
                        _PebbleKey(isUppercase ? 'J' : 'j', 0x0D, flex: 1),
                        _PebbleKey(isUppercase ? 'K' : 'k', 0x0E, flex: 1),
                        _PebbleKey(isUppercase ? 'L' : 'l', 0x0F, flex: 1),
                        _PebbleKey(isUppercase ? ':' : ';', 0x33, flex: 1),
                        _PebbleKey(isUppercase ? '"' : '\'', 0x34, flex: 1),
                        _PebbleKey('return', 0x28, flex: 2, isPrimary: true),
                      ]),
                    ),
                    const SizedBox(height: 4),

                    // Row 4: Bottom Alpha Row
                    Expanded(
                      child: _buildRow([
                        _PebbleKey(
                          'shift',
                          0x00,
                          flex: 3,
                          isActive: _isShiftActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isShiftActive = !_isShiftActive);
                          },
                        ),
                        _PebbleKey(isUppercase ? 'Z' : 'z', 0x1D, flex: 1),
                        _PebbleKey(isUppercase ? 'X' : 'x', 0x1B, flex: 1),
                        _PebbleKey(isUppercase ? 'C' : 'c', 0x06, flex: 1),
                        _PebbleKey(isUppercase ? 'V' : 'v', 0x19, flex: 1),
                        _PebbleKey(isUppercase ? 'B' : 'b', 0x05, flex: 1),
                        _PebbleKey(isUppercase ? 'N' : 'n', 0x11, flex: 1),
                        _PebbleKey(isUppercase ? 'M' : 'm', 0x10, flex: 1),
                        _PebbleKey(isUppercase ? '<' : ',', 0x36, flex: 1),
                        _PebbleKey(isUppercase ? '>' : '.', 0x37, flex: 1),
                        _PebbleKey(isUppercase ? '?' : '/', 0x38, flex: 1),
                        _PebbleKey(
                          'shift',
                          0x00,
                          flex: 3,
                          isActive: _isShiftActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isShiftActive = !_isShiftActive);
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),

                    // Row 5: Modifier & Spacebar Row
                    Expanded(
                      child: _buildRow([
                        _PebbleKey(
                          'ctrl',
                          0x00,
                          flex: 1,
                          isActive: _isCtrlActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isCtrlActive = !_isCtrlActive);
                          },
                        ),
                        _PebbleKey(
                          'fn',
                          0x00,
                          flex: 1,
                          isActive: _isFnActive,
                          onTapOverride: () {
                            HapticHelper.selectionClick();
                            setState(() => _isFnActive = !_isFnActive);
                          },
                        ),
                        _PebbleKey(
                          'cmd',
                          0x00,
                          flex: 1,
                          isActive: _isCmdActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isCmdActive = !_isCmdActive);
                          },
                        ),
                        _PebbleKey(
                          'opt',
                          0x00,
                          flex: 1,
                          isActive: _isAltActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isAltActive = !_isAltActive);
                          },
                        ),
                        _PebbleKey('space', 0x2C, flex: 6),
                        _PebbleKey(
                          'opt',
                          0x00,
                          flex: 1,
                          isActive: _isAltActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isAltActive = !_isAltActive);
                          },
                        ),
                        _PebbleKey(
                          'cmd',
                          0x00,
                          flex: 1,
                          isActive: _isCmdActive,
                          onTapOverride: () {
                            HapticHelper.mediumImpact();
                            setState(() => _isCmdActive = !_isCmdActive);
                          },
                        ),
                        _PebbleKey('◄', 0x50, flex: 1),
                        _PebbleKey('▲', 0x52, flex: 1),
                        _PebbleKey('▼', 0x51, flex: 1),
                        _PebbleKey('►', 0x4F, flex: 1),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isPortrait) {
      return RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: keyboardBody,
        ),
      );
    }

    return keyboardBody;
  }

  Widget _buildIndicatorDot(String label, bool isConnected) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? const Color(0xFF00E5FF) : Colors.white24,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isConnected ? const Color(0xFF00E5FF) : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<_PebbleKey> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          flex: key.flex,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (key.onTapOverride != null) {
                    key.onTapOverride!();
                  } else {
                    _onKeyPress(key.label, key.scancode);
                  }
                },
                borderRadius: BorderRadius.circular(
                  14,
                ), // Signature Pebble rounded keycaps
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: key.isActive
                        ? const Color(0xFF00E5FF)
                        : key.isPrimary
                        ? AppColors.primary
                        : key.isEasySwitch
                        ? const Color(0xFF2A2E35)
                        : key.isAction
                        ? const Color(0xFF272C33)
                        : const Color(0xFF323842),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: key.isActive
                          ? const Color(0xFF80F4FF)
                          : key.isEasySwitch
                          ? const Color(0xFF00E5FF).withAlpha(100)
                          : const Color(0xFF3F4652),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (key.icon != null)
                        Icon(
                          key.icon,
                          size: 13,
                          color: key.isActive ? Colors.black : Colors.white70,
                        )
                      else
                        Text(
                          key.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: key.isActive ? Colors.black : Colors.white,
                          ),
                        ),
                      if (key.isEasySwitch) ...[
                        const SizedBox(height: 1),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PebbleKey {
  final String label;
  final int scancode;
  final int flex;
  final bool isAction;
  final bool isPrimary;
  final bool isEasySwitch;
  final String? switchNum;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTapOverride;

  _PebbleKey(
    this.label,
    this.scancode, {
    this.flex = 1,
    this.isAction = false,
    this.isPrimary = false,
    this.isEasySwitch = false,
    this.switchNum,
    this.icon,
    this.isActive = false,
    this.onTapOverride,
  });
}
