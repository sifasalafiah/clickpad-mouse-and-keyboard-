import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gamepad_layout.dart';
import '../models/gamepad_mapping.dart';
import '../models/input_command.dart';
import '../services/ad_service.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../services/gamepad_layout_service.dart';
import '../services/gamepad_mapping_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/gamepad_layout_editor.dart';
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
  final GamepadLayoutService _layoutService = GamepadLayoutService.instance;

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
    _layoutService.addListener(_onIapChanged);

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
    _layoutService.removeListener(_onIapChanged);
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

    int modifierMask = 0;
    final List<int> regularKeycodes = [];

    for (final key in combined) {
      switch (key) {
        case 0xE0: // Left Ctrl
          modifierMask |= 0x01;
          break;
        case 0xE1: // Left Shift
          modifierMask |= 0x02;
          break;
        case 0xE2: // Left Alt
          modifierMask |= 0x04;
          break;
        case 0xE3: // Left GUI / Cmd / Win
          modifierMask |= 0x08;
          break;
        case 0xE4: // Right Ctrl
          modifierMask |= 0x10;
          break;
        case 0xE5: // Right Shift
          modifierMask |= 0x20;
          break;
        case 0xE6: // Right Alt
          modifierMask |= 0x40;
          break;
        case 0xE7: // Right GUI
          modifierMask |= 0x80;
          break;
        default:
          if (key > 0 && !regularKeycodes.contains(key)) {
            regularKeycodes.add(key);
          }
          break;
      }
    }

    // Send multi-key report to native HID with modifier byte
    _bleService.sendKeyboardState(modifierMask, regularKeycodes.take(6).toList());
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
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                // Main Gamepad Body with custom positioned & scaled HUD elements
                Positioned.fill(
                  child: _buildMainGamepadBody(),
                ),

                // Floating Top Center HUD (WASD mode, analog toggle, Remap, HUD Layout, Pro/Trial)
                Positioned(
                  top: 6,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: _buildTopCenterHud(isTrial, trialSeconds),
                  ),
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

  Widget _buildTopCenterHud(bool isTrial, int trialSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
          const SizedBox(width: 6),

            // HUD Layout Customizer Button
            InkWell(
              onTap: () {
                GamepadLayoutEditorScreen.open(context);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(150)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_customize, color: AppColors.primary, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      'Layout',
                      style: TextStyle(
                        fontSize: 9.5,
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
              const SizedBox(width: 6),
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
                borderRadius: BorderRadius.circular(8),
                child: _buildTrialBadge(trialSeconds),
              ),
            ] else if (_iapService.isPro) ...[
              const SizedBox(width: 6),
              _buildProBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrialBadge(int trialSeconds) {
    final trialText =
        '${(trialSeconds ~/ 60).toString().padLeft(2, '0')}:${(trialSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.orange, size: 11),
          const SizedBox(width: 3),
          Text(
            trialText,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.add_circle_outline, color: Colors.orange, size: 10),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 11),
          SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: 9.5,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMainGamepadBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final stickBase = GamepadLayoutDimensions.getBaseSize(
          GamepadHudElement.leftStick,
          canvasSize,
        );
        final abxyBase = GamepadLayoutDimensions.getBaseSize(
          GamepadHudElement.abxyCluster,
          canvasSize,
        );
        final leftShoulderBase = GamepadLayoutDimensions.getBaseSize(
          GamepadHudElement.leftShoulders,
          canvasSize,
        );
        final rightShoulderBase = GamepadLayoutDimensions.getBaseSize(
          GamepadHudElement.rightShoulders,
          canvasSize,
        );
        final systemBase = GamepadLayoutDimensions.getBaseSize(
          GamepadHudElement.systemButtons,
          canvasSize,
        );
        final cameraBase = GamepadLayoutDimensions.getBaseSize(
          GamepadHudElement.cameraTouchpad,
          canvasSize,
        );

        return Stack(
          children: [
            // 1. Left Stick or D-Pad
            _buildPositionedHudItem(
              GamepadHudElement.leftStick,
              canvasSize,
              child: _useAnalogStick
                  ? VirtualJoystickWidget(
                      size: stickBase.width,
                      mode: _joystickMode,
                      onDirectionChanged: _onJoystickDirectionChanged,
                    )
                  : _buildDPadWidget(),
            ),

            // 2. Action Buttons (ABXY Cluster)
            _buildPositionedHudItem(
              GamepadHudElement.abxyCluster,
              canvasSize,
              child: _buildABXYCluster(abxyBase),
            ),

            // 3. Camera Look Touchpad
            _buildPositionedHudItem(
              GamepadHudElement.cameraTouchpad,
              canvasSize,
              child: _buildCameraLookPad(cameraBase),
            ),

            // 4. Left Shoulders (L1 & L2)
            _buildPositionedHudItem(
              GamepadHudElement.leftShoulders,
              canvasSize,
              child: _buildLeftShoulders(leftShoulderBase),
            ),

            // 5. Right Shoulders (R1 & R2)
            _buildPositionedHudItem(
              GamepadHudElement.rightShoulders,
              canvasSize,
              child: _buildRightShoulders(rightShoulderBase),
            ),

            // 6. System Buttons (Select, Start, Esc)
            _buildPositionedHudItem(
              GamepadHudElement.systemButtons,
              canvasSize,
              child: _buildSystemButtons(systemBase),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPositionedHudItem(
    GamepadHudElement element,
    Size canvasSize, {
    required Widget child,
  }) {
    final config = _layoutService.layout.getConfig(element);
    final baseSize = GamepadLayoutDimensions.getBaseSize(element, canvasSize);

    final scaledWidth = baseSize.width * config.scale;
    final scaledHeight = baseSize.height * config.scale;

    final left = (config.relX * canvasSize.width - scaledWidth / 2)
        .clamp(2.0, canvasSize.width - scaledWidth - 2.0);
    final top = (config.relY * canvasSize.height - scaledHeight / 2)
        .clamp(2.0, canvasSize.height - scaledHeight - 2.0);

    return Positioned(
      left: left,
      top: top,
      width: scaledWidth,
      height: scaledHeight,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: baseSize.width,
          height: baseSize.height,
          child: child,
        ),
      ),
    );
  }

  Widget _buildLeftShoulders(Size baseSize) {
    final itemW = (baseSize.width - 8) / 2.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShoulderButton(
          label: 'L1',
          scancode: _mappingService.getScancode(GamepadButtonId.l1),
          width: itemW,
          height: baseSize.height,
        ),
        const SizedBox(width: 8),
        _buildShoulderButton(
          label: 'L2',
          scancode: _mappingService.getScancode(GamepadButtonId.l2),
          width: itemW,
          height: baseSize.height,
        ),
      ],
    );
  }

  Widget _buildRightShoulders(Size baseSize) {
    final itemW = (baseSize.width - 8) / 2.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShoulderButton(
          label: 'R1',
          scancode: _mappingService.getScancode(GamepadButtonId.r1),
          width: itemW,
          height: baseSize.height,
        ),
        const SizedBox(width: 8),
        _buildShoulderButton(
          label: 'R2',
          scancode: _mappingService.getScancode(GamepadButtonId.r2),
          width: itemW,
          height: baseSize.height,
        ),
      ],
    );
  }

  Widget _buildSystemButtons(Size baseSize) {
    final itemW = (baseSize.width - 12) / 3.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCenterButton(
          'SELECT',
          _mappingService.getScancode(GamepadButtonId.select),
          itemW,
          baseSize.height,
        ),
        const SizedBox(width: 6),
        _buildCenterButton(
          'START',
          _mappingService.getScancode(GamepadButtonId.start),
          itemW,
          baseSize.height,
        ),
        const SizedBox(width: 6),
        _buildCenterButton(
          'ESC',
          _mappingService.getScancode(GamepadButtonId.esc),
          itemW,
          baseSize.height,
        ),
      ],
    );
  }

  Widget _buildShoulderButton({
    required String label,
    required int scancode,
    required double width,
    required double height,
  }) {
    final isPressed = _activeHeldKeys.contains(scancode);
    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isPressed ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPressed ? AppColors.primaryLight : AppColors.border,
            width: isPressed ? 1.5 : 1.0,
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(120),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: (height * 0.32).clamp(10.0, 14.0),
            fontWeight: FontWeight.w900,
            color: isPressed ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(
    String label,
    int scancode,
    double width,
    double height,
  ) {
    final isPressed = _activeHeldKeys.contains(scancode);
    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPressed ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPressed ? AppColors.primaryLight : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (height * 0.28).clamp(8.0, 11.0),
            fontWeight: FontWeight.bold,
            color: isPressed ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildABXYCluster(Size baseSize) {
    final btnSize = (baseSize.width * 0.32).clamp(36.0, 52.0);
    return SizedBox(
      width: baseSize.width,
      height: baseSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Y Button (Top / Yellow)
          Positioned(
            top: 0,
            child: _buildABXYButton('Y', GamepadButtonId.buttonY, const Color(0xFFFFD700), btnSize),
          ),
          // X Button (Left / Blue)
          Positioned(
            left: 0,
            child: _buildABXYButton('X', GamepadButtonId.buttonX, const Color(0xFF00E5FF), btnSize),
          ),
          // B Button (Right / Red)
          Positioned(
            right: 0,
            child: _buildABXYButton('B', GamepadButtonId.buttonB, const Color(0xFFFF5252), btnSize),
          ),
          // A Button (Bottom / Green)
          Positioned(
            bottom: 0,
            child: _buildABXYButton('A', GamepadButtonId.buttonA, const Color(0xFF00E676), btnSize),
          ),
        ],
      ),
    );
  }

  Widget _buildABXYButton(String label, GamepadButtonId buttonId, Color themeColor, double size) {
    final scancode = _mappingService.getScancode(buttonId);
    final isPressed = _activeHeldKeys.contains(scancode);

    return Listener(
      onPointerDown: (_) => _onButtonTouchDown(scancode),
      onPointerUp: (_) => _onButtonTouchUp(scancode),
      onPointerCancel: (_) => _onButtonTouchUp(scancode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed
              ? themeColor
              : themeColor.withAlpha(AppColors.palette.isLight ? 55 : 35),
          border: Border.all(
            color: isPressed ? Colors.white : themeColor,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isPressed
                  ? themeColor.withAlpha(160)
                  : themeColor.withAlpha(50),
              blurRadius: isPressed ? 12 : 5,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            color: isPressed
                ? (themeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                : themeColor,
          ),
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

  Widget _buildCameraLookPad(Size baseSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        // Send relative mouse movement for camera look in PC games
        ConnectionService.instance.sendCommand(
          InputCommand.move(details.delta.dx * 1.5, details.delta.dy * 1.5),
        );
      },
      child: Container(
        width: baseSize.width,
        height: baseSize.height,
        decoration: BoxDecoration(
          color: AppColors.touchpadCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, color: AppColors.textMuted, size: 16),
            const SizedBox(height: 2),
            Text(
              'Camera Look',
              style: TextStyle(
                fontSize: 8.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
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
