import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gamepad_layout.dart';

class GamepadLayoutService extends ChangeNotifier {
  static final GamepadLayoutService instance = GamepadLayoutService._internal();
  GamepadLayoutService._internal();

  static const String _prefKeyLayout = 'clickpad_gamepad_hud_layout_v5';

  GamepadHudLayout _activeLayout = GamepadHudLayout.defaultLayout;
  bool _initialized = false;

  GamepadHudLayout get activeLayout => _activeLayout;
  GamepadHudLayout get layout => _activeLayout;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKeyLayout);
      if (savedJson != null && savedJson.isNotEmpty) {
        _activeLayout = GamepadHudLayout.deserialize(savedJson);
      } else {
        _activeLayout = GamepadHudLayout.defaultLayout;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('GamepadLayoutService init error: $e');
    }
  }

  GamepadElementConfig getConfig(GamepadHudElement element) {
    return _activeLayout.getConfig(element);
  }

  void updateElement(GamepadHudElement element, GamepadElementConfig config) {
    _activeLayout = _activeLayout.updateElement(element, config);
    notifyListeners();
  }

  Future<void> saveLayout(GamepadHudLayout newLayout) async {
    _activeLayout = newLayout;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLayout, _activeLayout.serialize());
    } catch (e) {
      debugPrint('GamepadLayoutService saveLayout error: $e');
    }
  }

  Future<void> resetToDefaults() async {
    _activeLayout = GamepadHudLayout.defaultLayout;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyLayout);
    } catch (e) {
      debugPrint('GamepadLayoutService resetToDefaults error: $e');
    }
  }
}
