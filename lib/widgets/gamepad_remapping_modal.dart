import 'package:flutter/material.dart';
import '../models/gamepad_mapping.dart';
import '../services/gamepad_mapping_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class GamepadRemappingModal extends StatefulWidget {
  const GamepadRemappingModal({super.key});

  static void show(BuildContext context) {
    HapticHelper.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        reverseDuration: const Duration(milliseconds: 250),
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (ctx) => const GamepadRemappingModal(),
    );
  }

  @override
  State<GamepadRemappingModal> createState() => _GamepadRemappingModalState();
}

class _GamepadRemappingModalState extends State<GamepadRemappingModal> {
  final GamepadMappingService _mappingService = GamepadMappingService.instance;

  @override
  void initState() {
    super.initState();
    _mappingService.addListener(_onMappingChanged);
  }

  @override
  void dispose() {
    _mappingService.removeListener(_onMappingChanged);
    super.dispose();
  }

  void _onMappingChanged() {
    if (mounted) setState(() {});
  }

  void _showKeyPicker(GamepadButtonId buttonId) {
    HapticHelper.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KeyPickerSheet(
        buttonId: buttonId,
        currentScancode: _mappingService.getScancode(buttonId),
        onKeySelected: (scancode) {
          _mappingService.setMapping(buttonId, scancode);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gamepad Key Remapper',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Universal Bluetooth HID bindings for all devices',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Platform Compatibility Chips Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlatformBadge('Windows', Icons.desktop_windows),
                    _buildPlatformBadge('macOS', Icons.laptop_mac),
                    _buildPlatformBadge('Linux', Icons.terminal),
                    _buildPlatformBadge('iPad / Tablet', Icons.tablet_mac),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Presets Selector Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GAMEPLAY PRESETS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticHelper.mediumImpact();
                            _mappingService.resetToDefaults();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mappings reset to standard default.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            'Reset to Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...GamepadProfilePreset.allPresets.map((preset) {
                            final isSelected = _mappingService.activePresetId == preset.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(preset.name),
                                selected: isSelected,
                                onSelected: (_) {
                                  HapticHelper.selectionClick();
                                  _mappingService.applyPreset(preset.id);
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }),
                          if (_mappingService.activePresetId == 'custom')
                            ChoiceChip(
                              label: const Text('Custom Layout'),
                              selected: true,
                              onSelected: (_) {},
                              selectedColor: AppColors.primary,
                              labelStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _mappingService.activePresetId == 'custom'
                          ? 'Personalized layout: Custom keyboard key bindings'
                          : GamepadProfilePreset.allPresets
                              .firstWhere(
                                (p) => p.id == _mappingService.activePresetId,
                                orElse: () => GamepadProfilePreset.standardFps,
                              )
                              .description,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Scrollable List of Gamepad Zones
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  // 1. Shoulders & Triggers
                  _buildSectionHeader('SHOULDERS & TRIGGERS', Icons.touch_app),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.l1,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.l2,
                          accentColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.r1,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.r2,
                          accentColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. Action Buttons (ABXY)
                  _buildSectionHeader('ACTION BUTTONS (ABXY)', Icons.grid_view_rounded),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.buttonY,
                          accentColor: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.buttonX,
                          accentColor: const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.buttonB,
                          accentColor: const Color(0xFFFF5252),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.buttonA,
                          accentColor: const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. System & Menu Buttons
                  _buildSectionHeader('SYSTEM & MENU BUTTONS', Icons.menu_rounded),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.select,
                          accentColor: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.start,
                          accentColor: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.esc,
                          accentColor: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4. Directional D-Pad
                  _buildSectionHeader('DIRECTIONAL D-PAD', Icons.control_camera_rounded),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.dpadUp,
                          accentColor: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.dpadDown,
                          accentColor: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.dpadLeft,
                          accentColor: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRemapTile(
                          GamepadButtonId.dpadRight,
                          accentColor: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformBadge(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonBadge(GamepadButtonId buttonId, Color accentColor) {
    IconData? icon;
    switch (buttonId) {
      case GamepadButtonId.dpadUp:
        icon = Icons.arrow_upward;
        break;
      case GamepadButtonId.dpadDown:
        icon = Icons.arrow_downward;
        break;
      case GamepadButtonId.dpadLeft:
        icon = Icons.arrow_back;
        break;
      case GamepadButtonId.dpadRight:
        icon = Icons.arrow_forward;
        break;
      case GamepadButtonId.select:
        icon = Icons.tune;
        break;
      case GamepadButtonId.start:
        icon = Icons.play_arrow;
        break;
      case GamepadButtonId.esc:
        icon = Icons.close;
        break;
      default:
        icon = null;
        break;
    }

    final isRound = buttonId == GamepadButtonId.buttonA ||
        buttonId == GamepadButtonId.buttonB ||
        buttonId == GamepadButtonId.buttonX ||
        buttonId == GamepadButtonId.buttonY;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: isRound ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRound ? null : BorderRadius.circular(8),
        color: accentColor.withAlpha(25),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 16, color: accentColor)
          : Text(
              buttonId.shortName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
    );
  }

  Widget _buildRemapTile(
    GamepadButtonId buttonId, {
    required Color accentColor,
  }) {
    final keyName = _mappingService.getKeyName(buttonId);

    return InkWell(
      onTap: () => _showKeyPicker(buttonId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildButtonBadge(buttonId, accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonId.cleanLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_right,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          keyName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Sheet allowing the user to search and select a PC keyboard key
class _KeyPickerSheet extends StatefulWidget {
  final GamepadButtonId buttonId;
  final int currentScancode;
  final ValueChanged<int> onKeySelected;

  const _KeyPickerSheet({
    required this.buttonId,
    required this.currentScancode,
    required this.onKeySelected,
  });

  @override
  State<_KeyPickerSheet> createState() => _KeyPickerSheetState();
}

class _KeyPickerSheetState extends State<_KeyPickerSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Gaming Keys',
    'Movement',
    'Alphabet',
    'Numbers & Fn',
    'Arrows & Nav',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final filteredKeys = HidKeyDefinition.allKeys.where((key) {
      final matchesQuery = _searchQuery.isEmpty ||
          key.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          key.shortLabel.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || key.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return Container(
      height: size.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Key to ${widget.buttonId.displayName}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Select any computer keyboard key to trigger',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search key (e.g., Space, Shift, E, Enter)...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Keys Grid
            Expanded(
              child: filteredKeys.isEmpty
                  ? Center(
                      child: Text(
                        'No matching keys found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: filteredKeys.length,
                      itemBuilder: (context, index) {
                        final keyDef = filteredKeys[index];
                        final isSelected = keyDef.scancode == widget.currentScancode;

                        return InkWell(
                          onTap: () {
                            HapticHelper.selectionClick();
                            widget.onKeySelected(keyDef.scancode);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withAlpha(40)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  keyDef.shortLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  keyDef.name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
