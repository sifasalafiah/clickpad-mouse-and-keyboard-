import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/input_command.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../services/iap_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/joystick_widget.dart';
import '../widgets/pro_purchase_modal.dart';

class JoystickScreen extends StatefulWidget {
  const JoystickScreen({super.key});

  @override
  State<JoystickScreen> createState() => _JoystickScreenState();
}

class _JoystickScreenState extends State<JoystickScreen> {
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final IapService _iapService = IapService.instance;

  JoystickMode _joystickMode = JoystickMode.wasd;
  bool _useAnalogStick = true;

  // Track active held keys for gamepad buttons
  final Set<int> _activeHeldKeys = {};
  List<int> _joystickKeys = [];

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);

    // Prefer landscape for comfortable gaming grip
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIapChanged);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _onIapChanged() {
    if (mounted) setState(() {});
  }

  void _updateCombinedKeys() {
    final List<int> combined = [];
    combined.addAll(_joystickKeys);
    combined.addAll(_activeHeldKeys);

    // Send multi-key report to native HID
    _bleService.sendKeyboardState(0, combined.take(6).toList());
  }

  void _onJoystickDirectionChanged(List<int> keys) {
    _joystickKeys = keys;
    _updateCombinedKeys();
  }

  void _onButtonTouchDown(int scancode) {
    HapticHelper.lightImpact();
    _activeHeldKeys.add(scancode);
    _updateCombinedKeys();
  }

  void _onButtonTouchUp(int scancode) {
    _activeHeldKeys.remove(scancode);
    _updateCombinedKeys();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _iapService.isPro;
    final isTrial = _iapService.isTrialActive;
    final trialSeconds = _iapService.trialSecondsLeft;

    final size = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    Widget joystickBody = Container(
      color: const Color(0xFF0F1115),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Edge Row: Left Shoulder Buttons | Center Gaming HUD | Right Shoulder Buttons
                  _buildTopShoulderAndHudBar(isTrial, trialSeconds),
                  const SizedBox(height: 10),

                  // Main Gamepad Body: Left Thumb Stick | Center Touchpad & Menu | Right ABXY
                  Expanded(
                    child: _buildMainGamepadBody(),
                  ),
                ],
              ),

              // Pro Locked Glass Overlay if not unlocked and trial expired
              if (!isPro) _buildProLockOverlay(),
            ],
          ),
        ),
      ),
    );

    if (isPortrait) {
      return RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: joystickBody,
        ),
      );
    }

    return joystickBody;
  }

  Widget _buildTopShoulderAndHudBar(bool isTrial, int trialSeconds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Shoulders (L1, L2)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShoulderButton(
              label: 'L1',
              subLabel: 'Shift',
              scancode: 0xE1,
            ),
            const SizedBox(width: 8),
            _buildShoulderButton(
              label: 'L2',
              subLabel: 'Ctrl',
              scancode: 0xE0,
            ),
          ],
        ),

        // Center HUD
        _buildTopCenterHud(isTrial, trialSeconds),

        // Right Shoulders (R1, R2)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShoulderButton(
              label: 'R1',
              subLabel: 'Space',
              scancode: 0x2C,
            ),
            const SizedBox(width: 8),
            _buildShoulderButton(
              label: 'R2',
              subLabel: 'Enter',
              scancode: 0x28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopCenterHud(bool isTrial, int trialSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282F3E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WASD / ARROWS Mode Toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF202633),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeChip('WASD', JoystickMode.wasd),
                _buildModeChip('ARROWS', JoystickMode.arrows),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Divider
          Container(width: 1, height: 16, color: const Color(0xFF2D3546)),
          const SizedBox(width: 8),

          // Analog Stick vs D-Pad Toggle
          InkWell(
            onTap: () {
              HapticHelper.selectionClick();
              setState(() => _useAnalogStick = !_useAnalogStick);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF202633),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _useAnalogStick
                      ? AppColors.primary.withAlpha(120)
                      : const Color(0xFF333D50),
                ),
              ),
              child: Icon(
                _useAnalogStick ? Icons.radio_button_checked : Icons.grid_4x4,
                color: _useAnalogStick ? AppColors.primary : Colors.white70,
                size: 16,
              ),
            ),
          ),

          // PRO / Trial Badge
          if (isTrial) ...[
            const SizedBox(width: 8),
            _buildTrialBadge(trialSeconds),
          ] else if (_iapService.isPro) ...[
            const SizedBox(width: 8),
            _buildProBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrialBadge(int trialSeconds) {
    final trialText =
        '${(trialSeconds ~/ 60).toString().padLeft(2, '0')}:${(trialSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.orange, size: 12),
          const SizedBox(width: 4),
          Text(
            trialText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withAlpha(40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 12),
          SizedBox(width: 4),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, JoystickMode mode) {
    final isSelected = _joystickMode == mode;
    return InkWell(
      onTap: () {
        HapticHelper.selectionClick();
        setState(() => _joystickMode = mode);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMainGamepadBody() {
    return Row(
      children: [
        // Left Thumb Zone: 360° Joystick or D-Pad
        Expanded(
          flex: 5,
          child: Center(
            child: _useAnalogStick
                ? VirtualJoystickWidget(
                    size: 170,
                    mode: _joystickMode,
                    onDirectionChanged: _onJoystickDirectionChanged,
                  )
                : _buildDPadWidget(),
          ),
        ),

        // Center Zone: System Buttons (SELECT / START / ESC) & Camera Look Touchpad
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                // System Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCenterButton('SELECT', 0x2B), // Tab
                    const SizedBox(width: 10),
                    _buildCenterButton('START', 0x28), // Enter
                    const SizedBox(width: 10),
                    _buildCenterButton('ESC', 0x29), // Escape
                  ],
                ),
                const SizedBox(height: 10),

                // Camera Look Touchpad
                Expanded(child: _buildCameraLookPad()),
              ],
            ),
          ),
        ),

        // Right Thumb Zone: ABXY Diamond Action Cluster
        Expanded(
          flex: 5,
          child: Center(
            child: _buildABXYCluster(),
          ),
        ),
      ],
    );
  }

  Widget _buildShoulderButton({
    required String label,
    required String subLabel,
    required int scancode,
  }) {
    final isPressed = _activeHeldKeys.contains(scancode);
    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isPressed ? AppColors.primary : const Color(0xFF1E222B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPressed ? Colors.white : const Color(0xFF333B49),
            width: isPressed ? 1.5 : 1,
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(120),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isPressed ? Colors.black : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isPressed
                    ? Colors.black.withAlpha(40)
                    : const Color(0xFF2A313E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isPressed ? Colors.black87 : AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(String label, int scancode) {
    final isPressed = _activeHeldKeys.contains(scancode);
    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isPressed
                  ? AppColors.primary
                  : const Color(0xFF1E222B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF333B4B)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isPressed ? Colors.black : AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildABXYCluster() {
    // ABXY Keys:
    // Y (Top): E (0x08)
    // X (Left): R (0x15)
    // A (Bottom): Space (0x2C)
    // B (Right): Esc (0x29)
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Y Button (Top / Yellow)
          Positioned(
            top: 0,
            child: _buildABXYButton('Y', 0x08, const Color(0xFFFFD700)),
          ),
          // X Button (Left / Blue)
          Positioned(
            left: 0,
            child: _buildABXYButton('X', 0x15, const Color(0xFF00E5FF)),
          ),
          // B Button (Right / Red)
          Positioned(
            right: 0,
            child: _buildABXYButton('B', 0x29, const Color(0xFFFF5252)),
          ),
          // A Button (Bottom / Green)
          Positioned(
            bottom: 0,
            child: _buildABXYButton('A', 0x2C, const Color(0xFF00E676)),
          ),
        ],
      ),
    );
  }

  Widget _buildABXYButton(String label, int scancode, Color themeColor) {
    final isPressed = _activeHeldKeys.contains(scancode);
    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors:
                isPressed
                    ? [themeColor, Colors.white]
                    : [
                      themeColor.withAlpha(50),
                      const Color(0xFF1B1F27),
                    ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isPressed ? Colors.white : themeColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isPressed
                      ? themeColor.withAlpha(150)
                      : Colors.black.withAlpha(100),
              blurRadius: isPressed ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isPressed ? Colors.black : themeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDPadWidget() {
    // D-Pad Keys
    final upKey = _joystickMode == JoystickMode.wasd ? 0x1A : 0x52;
    final leftKey = _joystickMode == JoystickMode.wasd ? 0x04 : 0x50;
    final downKey = _joystickMode == JoystickMode.wasd ? 0x16 : 0x51;
    final rightKey = _joystickMode == JoystickMode.wasd ? 0x07 : 0x4F;

    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _buildDPadButton(
              _joystickMode == JoystickMode.wasd ? 'W' : '▲',
              upKey,
            ),
          ),
          Positioned(
            left: 0,
            child: _buildDPadButton(
              _joystickMode == JoystickMode.wasd ? 'A' : '◄',
              leftKey,
            ),
          ),
          Positioned(
            right: 0,
            child: _buildDPadButton(
              _joystickMode == JoystickMode.wasd ? 'D' : '►',
              rightKey,
            ),
          ),
          Positioned(
            bottom: 0,
            child: _buildDPadButton(
              _joystickMode == JoystickMode.wasd ? 'S' : '▼',
              downKey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton(String label, int scancode) {
    final isPressed = _activeHeldKeys.contains(scancode);
    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color:
              isPressed
                  ? AppColors.primary
                  : const Color(0xFF222732),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isPressed
                    ? Colors.white
                    : const Color(0xFF3B4456),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPressed ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraLookPad() {
    return GestureDetector(
      onPanUpdate: (details) {
        // Send relative mouse movement for camera look in PC games
        ConnectionService.instance.sendCommand(
          InputCommand.move(details.delta.dx * 1.5, details.delta.dy * 1.5),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161920),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2B3240)),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: AppColors.textMuted, size: 24),
            SizedBox(height: 4),
            Text(
              'Camera Look (Touchpad)',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProLockOverlay() {
    return Container(
      color: Colors.black.withAlpha(210),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF171A21),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha(40),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2A2715),
                ),
                child: const Icon(
                  Icons.sports_esports,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'PRO Exclusive Feature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Unlock Virtual Gamepad Controller & 360° Joystick for the ultimate PC gaming experience.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  HapticHelper.mediumImpact();
                  ProPurchaseModal.show(context);
                },
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: const Text('Unlock Gamepad Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  HapticHelper.selectionClick();
                  _iapService.startFreeTrial(durationSeconds: 180);
                },
                icon: const Icon(
                  Icons.timer,
                  color: Color(0xFF00E5FF),
                  size: 16,
                ),
                label: const Text(
                  'Try 3-Minute Free Trial',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
