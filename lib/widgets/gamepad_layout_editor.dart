import 'package:flutter/material.dart';
import '../models/gamepad_layout.dart';
import '../services/gamepad_layout_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

/// Full-screen PUBG Mobile style HUD Layout Editor for virtual gamepad
class GamepadLayoutEditorScreen extends StatefulWidget {
  const GamepadLayoutEditorScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticHelper.mediumImpact();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim, _) => const GamepadLayoutEditorScreen(),
        transitionsBuilder: (context, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  State<GamepadLayoutEditorScreen> createState() =>
      _GamepadLayoutEditorScreenState();
}

class _GamepadLayoutEditorScreenState extends State<GamepadLayoutEditorScreen> {
  final GamepadLayoutService _layoutService = GamepadLayoutService.instance;

  late GamepadHudLayout _draftLayout;
  GamepadHudElement _selectedElement = GamepadHudElement.leftStick;

  @override
  void initState() {
    super.initState();
    _draftLayout = _layoutService.activeLayout;
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _onElementSelected(GamepadHudElement element) {
    HapticHelper.selectionClick();
    setState(() => _selectedElement = element);
  }

  void _onElementDrag(GamepadHudElement element, Offset delta, Size canvasSize) {
    final current = _draftLayout.getConfig(element);
    final deltaRelX = delta.dx / canvasSize.width;
    final deltaRelY = delta.dy / canvasSize.height;

    final newRelX = (current.relX + deltaRelX).clamp(0.06, 0.94);
    final newRelY = (current.relY + deltaRelY).clamp(0.06, 0.94);

    setState(() {
      _draftLayout = _draftLayout.updateElement(
        element,
        current.copyWith(relX: newRelX, relY: newRelY),
      );
    });
  }

  void _stepScale(GamepadHudElement element, double delta) {
    HapticHelper.selectionClick();
    final current = _draftLayout.getConfig(element);
    final newScale = (current.scale + delta).clamp(0.70, 1.60);
    setState(() {
      _draftLayout = _draftLayout.updateElement(
        element,
        current.copyWith(scale: double.parse(newScale.toStringAsFixed(2))),
      );
    });
  }

  void _onCornerResizeDrag(
    GamepadHudElement element,
    Offset delta,
    Size baseSize,
  ) {
    final current = _draftLayout.getConfig(element);
    final avgDelta = (delta.dx + delta.dy) / 2.0;
    final scaleDelta = avgDelta / baseSize.width;
    final newScale = (current.scale + scaleDelta).clamp(0.70, 1.60);
    setState(() {
      _draftLayout = _draftLayout.updateElement(
        element,
        current.copyWith(scale: double.parse(newScale.toStringAsFixed(2))),
      );
    });
  }

  Future<void> _saveAndExit() async {
    HapticHelper.mediumImpact();
    await _layoutService.saveLayout(_draftLayout);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Custom HUD Layout Saved!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _resetToDefault() {
    HapticHelper.mediumImpact();
    setState(() {
      _draftLayout = GamepadHudLayout.defaultLayout;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to default HUD arrangement.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    final availableWidth = isPortrait ? size.height : size.width;
    final availableHeight = isPortrait ? size.width : size.height;

    Widget editorContent = Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 1. Interactive Draggable HUD Canvas (Full symmetric canvas)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    children: [
                      _buildDraggableItem(
                        GamepadHudElement.leftStick,
                        canvasSize,
                        childBuilder: (baseSize) =>
                            _buildPreviewStick(baseSize),
                      ),
                      _buildDraggableItem(
                        GamepadHudElement.abxyCluster,
                        canvasSize,
                        childBuilder: (baseSize) =>
                            _buildPreviewABXY(baseSize),
                      ),
                      _buildDraggableItem(
                        GamepadHudElement.cameraTouchpad,
                        canvasSize,
                        childBuilder: (baseSize) =>
                            _buildPreviewTouchpad(baseSize),
                      ),
                      _buildDraggableItem(
                        GamepadHudElement.leftShoulders,
                        canvasSize,
                        childBuilder: (baseSize) =>
                            _buildPreviewShoulders('L1', 'L2', baseSize),
                      ),
                      _buildDraggableItem(
                        GamepadHudElement.rightShoulders,
                        canvasSize,
                        childBuilder: (baseSize) =>
                            _buildPreviewShoulders('R1', 'R2', baseSize),
                      ),
                      _buildDraggableItem(
                        GamepadHudElement.systemButtons,
                        canvasSize,
                        childBuilder: (baseSize) =>
                            _buildPreviewSystemButtons(baseSize),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 2. Standalone Action Buttons in top bezel margin: Reset, Save, Close (X)
            Positioned(
              top: 6,
              right: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResetButton(),
                  const SizedBox(width: 8),
                  _buildSaveButton(),
                  const SizedBox(width: 8),
                  _buildCloseButton(),
                ],
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
          width: availableWidth,
          height: availableHeight,
          child: editorContent,
        ),
      );
    }

    return editorContent;
  }

  Widget _buildCloseButton() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.palette.isLight
                  ? Colors.black.withAlpha(20)
                  : Colors.black.withAlpha(140),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.close, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildResetButton() {
    return InkWell(
      onTap: _resetToDefault,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.palette.isLight
                  ? Colors.black.withAlpha(20)
                  : Colors.black.withAlpha(140),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 14, color: AppColors.textPrimary),
            const SizedBox(width: 4),
            Text(
              'Reset',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: _saveAndExit,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(140),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 15, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Save',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableItem(
    GamepadHudElement element,
    Size canvasSize, {
    required Widget Function(Size baseSize) childBuilder,
  }) {
    final config = _draftLayout.getConfig(element);
    final isSelected = _selectedElement == element;

    final baseSize = GamepadLayoutDimensions.getBaseSize(element, canvasSize);
    final scaledWidth = baseSize.width * config.scale;
    final scaledHeight = baseSize.height * config.scale;

    final left = (config.relX * canvasSize.width - scaledWidth / 2)
        .clamp(4.0, canvasSize.width - scaledWidth - 4.0);
    final top = (config.relY * canvasSize.height - scaledHeight / 2)
        .clamp(4.0, canvasSize.height - scaledHeight - 4.0);

    final showBadgeBelow = top < 36;

    return Positioned(
      left: left,
      top: top,
      width: scaledWidth,
      height: scaledHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onElementSelected(element),
        onPanStart: (_) => _onElementSelected(element),
        onPanUpdate: (details) =>
            _onElementDrag(element, details.delta, canvasSize),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The Button Box with glow when selected
            Container(
              width: scaledWidth,
              height: scaledHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(140),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: childBuilder(baseSize),
              ),
            ),

            // Direct On-Button Resize Controls (PUBG Mobile style)
            if (isSelected) ...[
              // 1. Direct [-] [ 100% ] [+] floating badge attached to the button
              Positioned(
                top: showBadgeBelow ? null : -30,
                bottom: showBadgeBelow ? -30 : null,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primaryLight, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.palette.isLight
                              ? Colors.black.withAlpha(25)
                              : Colors.black.withAlpha(160),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Minus / Shrink
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _stepScale(element, -0.10),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.remove,
                                size: 14, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(config.scale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Plus / Enlarge
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _stepScale(element, 0.10),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(70),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.add,
                                size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Corner Drag Resize Handle (bottom-right)
              Positioned(
                bottom: -8,
                right: -8,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) =>
                      _onCornerResizeDrag(element, details.delta, baseSize),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(120),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.open_in_full,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- PREVIEW WIDGETS ---

  Widget _buildPreviewStick(Size baseSize) {
    return Container(
      width: baseSize.width,
      height: baseSize.height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.palette.isLight
            ? AppColors.touchpadCanvas
            : const Color(0xFF1E293B).withAlpha(180),
        border: Border.all(color: AppColors.border, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.palette.isLight
                ? Colors.black.withAlpha(15)
                : Colors.black.withAlpha(80),
            blurRadius: 14,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            child: Text(
              'W',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text(
              'S',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Positioned(
            left: 10,
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Positioned(
            right: 10,
            child: Text(
              'D',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Container(
            width: baseSize.width * 0.38,
            height: baseSize.height * 0.38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.navigation,
              color: Colors.white,
              size: baseSize.width * 0.16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewABXY(Size baseSize) {
    final btnSize = (baseSize.width * 0.32).clamp(36.0, 52.0);
    return SizedBox(
      width: baseSize.width,
      height: baseSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _buildMiniActionBtn('Y', const Color(0xFFFFD700), btnSize),
          ),
          Positioned(
            left: 0,
            child: _buildMiniActionBtn('X', const Color(0xFF00E5FF), btnSize),
          ),
          Positioned(
            right: 0,
            child: _buildMiniActionBtn('B', const Color(0xFFFF5252), btnSize),
          ),
          Positioned(
            bottom: 0,
            child: _buildMiniActionBtn('A', const Color(0xFF00E676), btnSize),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionBtn(String label, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(AppColors.palette.isLight ? 55 : 35),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 5,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPreviewTouchpad(Size baseSize) {
    return Container(
      width: baseSize.width,
      height: baseSize.height,
      decoration: BoxDecoration(
        color: AppColors.touchpadCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
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
    );
  }

  Widget _buildPreviewShoulders(String btn1, String btn2, Size baseSize) {
    final itemW = (baseSize.width - 8) / 2.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniShoulder(btn1, itemW, baseSize.height),
        const SizedBox(width: 8),
        _buildMiniShoulder(btn2, itemW, baseSize.height),
      ],
    );
  }

  Widget _buildMiniShoulder(String label, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: (h * 0.32).clamp(10.0, 14.0),
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPreviewSystemButtons(Size baseSize) {
    final itemW = (baseSize.width - 12) / 3.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniCenterBtn('SELECT', itemW, baseSize.height),
        const SizedBox(width: 6),
        _buildMiniCenterBtn('START', itemW, baseSize.height),
        const SizedBox(width: 6),
        _buildMiniCenterBtn('ESC', itemW, baseSize.height),
      ],
    );
  }

  Widget _buildMiniCenterBtn(String label, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: (h * 0.28).clamp(8.0, 11.0),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
