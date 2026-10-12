import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gamepad_mapping.dart';
import '../models/input_command.dart';
import '../services/ad_service.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../services/gamepad_mapping_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/gamepad_remapping_modal.dart';
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
  final SettingsService _settings = SettingsService.instance;
  final GamepadMappingService _mappingService = GamepadMappingService.instance;

  JoystickMode _joystickMode = JoystickMode.wasd;
  bool _useAnalogStick = true;

  // Track active held keys for gamepad buttons
  final Set<int> _activeHeldKeys = {};
  List<int> _joystickKeys = [];

  @override
  void initState() {
    super.initState();
    _iapService.addListener(_onIapChanged);
    _settings.addListener(_onIapChanged);
    _mappingService.addListener(_onIapChanged);

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
    _settings.removeListener(_onIapChanged);
    _mappingService.removeListener(_onIapChanged);
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

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            isPortrait ? constraints.maxHeight : constraints.maxWidth;
        final availableHeight =
            isPortrait ? constraints.maxWidth : constraints.maxHeight;

        Widget gamepadContent = Container(
          width: availableWidth,
          height: availableHeight,
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // Top Edge Row: Left Shoulder Buttons | Center Gaming HUD | Right Shoulder Buttons
                _buildTopShoulderAndHudBar(isTrial, trialSeconds),
                const SizedBox(height: 6),

                // Main Gamepad Body: Left Thumb Stick | Center Touchpad & Menu | Right ABXY
                Expanded(
                  child: _buildMainGamepadBody(),
                ),
              ],
            ),
          ),
        );

        Widget gamepadView = isPortrait
            ? RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: constraints.maxHeight,
                  height: constraints.maxWidth,
                  child: gamepadContent,
                ),
              )
            : gamepadContent;

        return Stack(
          children: [
            gamepadView,

            // Pro Locked Glass Overlay in natural screen orientation (Portrait when phone is held vertically)
            if (!isPro) Positioned.fill(child: _buildProLockOverlay()),
          ],
        );
      },
    );
  }

  Widget _buildTopShoulderAndHudBar(bool isTrial, int trialSeconds) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left Shoulders (L1, L2)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShoulderButton(
                label: 'L1',
                subLabel: _mappingService.getShortLabel(GamepadButtonId.l1),
                scancode: _mappingService.getScancode(GamepadButtonId.l1),
              ),
              const SizedBox(width: 6),
              _buildShoulderButton(
                label: 'L2',
                subLabel: _mappingService.getShortLabel(GamepadButtonId.l2),
                scancode: _mappingService.getScancode(GamepadButtonId.l2),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Center HUD
          _buildTopCenterHud(isTrial, trialSeconds),
          const SizedBox(width: 12),

          // Right Shoulders (R1, R2)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShoulderButton(
                label: 'R1',
                subLabel: _mappingService.getShortLabel(GamepadButtonId.r1),
                scancode: _mappingService.getScancode(GamepadButtonId.r1),
              ),
              const SizedBox(width: 6),
              _buildShoulderButton(
                label: 'R2',
                subLabel: _mappingService.getShortLabel(GamepadButtonId.r2),
                scancode: _mappingService.getScancode(GamepadButtonId.r2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCenterHud(bool isTrial, int trialSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.palette.isLight
                ? Colors.black.withAlpha(15)
                : Colors.black.withAlpha(80),
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
              color: AppColors.surfaceElevated,
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
          Container(width: 1, height: 16, color: AppColors.border),
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
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _useAnalogStick
                      ? AppColors.primary.withAlpha(120)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                _useAnalogStick ? Icons.radio_button_checked : Icons.grid_4x4,
                color: _useAnalogStick ? AppColors.primary : AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Gamepad Key Remapper Button
          InkWell(
            onTap: () {
              GamepadRemappingModal.show(context);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Remap',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PRO / Trial Badge
          if (isTrial) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                AdService.instance.showRewardedTrialFlow(
                  context,
                  onSuccess: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 +3 Minutes added to your Free Trial!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: _buildTrialBadge(trialSeconds),
            ),
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
          const SizedBox(width: 4),
          const Icon(Icons.add_circle_outline, color: Colors.orange, size: 11),
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
            color: isSelected ? Colors.white : AppColors.textMuted,
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
                    size: 155,
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                // System Buttons Row
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCenterButton('SELECT', _mappingService.getScancode(GamepadButtonId.select)),
                      const SizedBox(width: 8),
                      _buildCenterButton('START', _mappingService.getScancode(GamepadButtonId.start)),
                      const SizedBox(width: 8),
                      _buildCenterButton('ESC', _mappingService.getScancode(GamepadButtonId.esc)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPressed ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPressed ? AppColors.primaryLight : AppColors.border,
            width: isPressed ? 1.5 : 1,
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(120),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.palette.isLight
                        ? Colors.black.withAlpha(15)
                        : Colors.black.withAlpha(60),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isPressed ? Colors.white : AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isPressed
                    ? AppColors.primaryLight.withAlpha(60)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                subLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isPressed ? Colors.white : AppColors.textMuted,
                  letterSpacing: 0.2,
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
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPressed ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPressed ? AppColors.primaryLight : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isPressed ? Colors.white : AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildABXYCluster() {
    return SizedBox(
      width: 155,
      height: 155,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Y Button (Top / Yellow)
          Positioned(
            top: 0,
            child: _buildABXYButton('Y', GamepadButtonId.buttonY, const Color(0xFFFFD700)),
          ),
          // X Button (Left / Blue)
          Positioned(
            left: 0,
            child: _buildABXYButton('X', GamepadButtonId.buttonX, const Color(0xFF00E5FF)),
          ),
          // B Button (Right / Red)
          Positioned(
            right: 0,
            child: _buildABXYButton('B', GamepadButtonId.buttonB, const Color(0xFFFF5252)),
          ),
          // A Button (Bottom / Green)
          Positioned(
            bottom: 0,
            child: _buildABXYButton('A', GamepadButtonId.buttonA, const Color(0xFF00E676)),
          ),
        ],
      ),
    );
  }

  Widget _buildABXYButton(String label, GamepadButtonId buttonId, Color themeColor) {
    final scancode = _mappingService.getScancode(buttonId);
    final shortLabel = _mappingService.getShortLabel(buttonId);
    final isPressed = _activeHeldKeys.contains(scancode);

    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors:
                isPressed
                    ? [themeColor, Colors.white]
                    : [
                      themeColor.withAlpha(AppColors.palette.isLight ? 75 : 40),
                      AppColors.surfaceElevated,
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
                      : (AppColors.palette.isLight
                          ? Colors.black.withAlpha(25)
                          : Colors.black.withAlpha(100)),
              blurRadius: isPressed ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isPressed ? (themeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white) : themeColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              shortLabel,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: isPressed ? Colors.white : AppColors.textMuted,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPadWidget() {
    // D-Pad Keys
    final upKey = _joystickMode == JoystickMode.wasd
        ? _mappingService.getScancode(GamepadButtonId.dpadUp)
        : 0x52;
    final leftKey = _joystickMode == JoystickMode.wasd
        ? _mappingService.getScancode(GamepadButtonId.dpadLeft)
        : 0x50;
    final downKey = _joystickMode == JoystickMode.wasd
        ? _mappingService.getScancode(GamepadButtonId.dpadDown)
        : 0x51;
    final rightKey = _joystickMode == JoystickMode.wasd
        ? _mappingService.getScancode(GamepadButtonId.dpadRight)
        : 0x4F;

    final upLabel = _joystickMode == JoystickMode.wasd
        ? _mappingService.getShortLabel(GamepadButtonId.dpadUp)
        : '▲';
    final leftLabel = _joystickMode == JoystickMode.wasd
        ? _mappingService.getShortLabel(GamepadButtonId.dpadLeft)
        : '◄';
    final downLabel = _joystickMode == JoystickMode.wasd
        ? _mappingService.getShortLabel(GamepadButtonId.dpadDown)
        : '▼';
    final rightLabel = _joystickMode == JoystickMode.wasd
        ? _mappingService.getShortLabel(GamepadButtonId.dpadRight)
        : '►';

    return SizedBox(
      width: 155,
      height: 155,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _buildDPadButton(
              upLabel,
              upKey,
            ),
          ),
          Positioned(
            left: 0,
            child: _buildDPadButton(
              leftLabel,
              leftKey,
            ),
          ),
          Positioned(
            right: 0,
            child: _buildDPadButton(
              rightLabel,
              rightKey,
            ),
          ),
          Positioned(
            bottom: 0,
            child: _buildDPadButton(
              downLabel,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              isPressed
                  ? AppColors.primary
                  : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isPressed
                    ? AppColors.primaryLight
                    : AppColors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPressed ? Colors.white : AppColors.textPrimary,
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
          color: AppColors.touchpadCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
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
      color: AppColors.palette.isLight
          ? Colors.black.withAlpha(140)
          : Colors.black.withAlpha(215),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha(40),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD700).withAlpha(
                      AppColors.palette.isLight ? 45 : 30),
                ),
                child: const Icon(
                  Icons.sports_esports,
                  color: Color(0xFFFFD700),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PRO Exclusive Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock Virtual Gamepad Controller & 360° Joystick for the ultimate PC gaming experience.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  HapticHelper.mediumImpact();
                  ProPurchaseModal.show(context);
                },
                icon: const Icon(Icons.workspace_premium, size: 20),
                label: const Text('Unlock Gamepad Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              if (_iapService.canStartTrial)
                TextButton.icon(
                  onPressed: () {
                    AdService.instance.showRewardedTrialFlow(
                      context,
                      onSuccess: () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 3-Minute Free Trial activated! Gamepad unlocked.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.ondemand_video_rounded,
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                  label: const Text(
                    'Watch Video for 3-Min Free Trial',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 13,
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
