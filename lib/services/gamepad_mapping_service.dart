import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gamepad_mapping.dart';

class GamepadMappingService extends ChangeNotifier {
  static final GamepadMappingService instance = GamepadMappingService._internal();
  GamepadMappingService._internal();

  static const String _prefKeyMappings = 'gamepad_active_mappings';
  static const String _prefKeyPresetId = 'gamepad_active_preset_id';

  Map<GamepadButtonId, int> _activeMappings = GamepadProfilePreset.clone(
    GamepadProfilePreset.standardFps.mappings,
  );
  String _activePresetId = GamepadProfilePreset.standardFps.id;

  Map<GamepadButtonId, int> get activeMappings => Map.unmodifiable(_activeMappings);
  String get activePresetId => _activePresetId;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activePresetId = prefs.getString(_prefKeyPresetId) ?? GamepadProfilePreset.standardFps.id;
      final savedJson = prefs.getString(_prefKeyMappings);
      if (savedJson != null) {
        _activeMappings = GamepadProfilePreset.deserialize(savedJson);
      } else {
        _activeMappings = GamepadProfilePreset.clone(GamepadProfilePreset.standardFps.mappings);
      }
    } catch (e) {
      debugPrint('GamepadMappingService init error: $e');
      _activeMappings = GamepadProfilePreset.clone(GamepadProfilePreset.standardFps.mappings);
    }
    notifyListeners();
  }

  /// Get the USB HID scancode for a given gamepad button
  int getScancode(GamepadButtonId id) {
    return _activeMappings[id] ?? GamepadProfilePreset.standardFps.mappings[id] ?? 0x2C;
  }

  /// Get a compact label for UI badges (e.g. "Space", "Shift", "E", "W")
  String getShortLabel(GamepadButtonId id) {
    final code = getScancode(id);
    return HidKeyDefinition.findByScancode(code).shortLabel;
  }

  /// Get the full descriptive key name (e.g. "Spacebar (Jump)")
  String getKeyName(GamepadButtonId id) {
    final code = getScancode(id);
    return HidKeyDefinition.findByScancode(code).name;
  }

  /// Remap a specific button to a new USB HID scancode
  Future<void> setMapping(GamepadButtonId buttonId, int scancode) async {
    _activeMappings[buttonId] = scancode;
    _activePresetId = 'custom';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyMappings, GamepadProfilePreset.serialize(_activeMappings));
      await prefs.setString(_prefKeyPresetId, _activePresetId);
    } catch (e) {
      debugPrint('Error saving gamepad mapping: $e');
    }
  }

  /// Apply one of the pre-configured gaming presets
  Future<void> applyPreset(String presetId) async {
    final preset = GamepadProfilePreset.allPresets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => GamepadProfilePreset.standardFps,
    );

    _activePresetId = preset.id;
    _activeMappings = GamepadProfilePreset.clone(preset.mappings);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyMappings, GamepadProfilePreset.serialize(_activeMappings));
      await prefs.setString(_prefKeyPresetId, _activePresetId);
    } catch (e) {
      debugPrint('Error saving preset: $e');
    }
  }

  /// Reset all button mappings back to standard factory default
  Future<void> resetToDefaults() async {
    await applyPreset(GamepadProfilePreset.standardFps.id);
  }
}
