import 'dart:convert';
import 'dart:ui';

/// Identifiers for customizable HUD elements on the virtual gamepad
enum GamepadHudElement {
  leftStick, // Left 360° Joystick or D-Pad
  abxyCluster, // Action Buttons (Y, X, B, A Diamond)
  cameraTouchpad, // Center Camera Look Trackpad
  leftShoulders, // L1 & L2 Shoulder triggers
  rightShoulders, // R1 & R2 Shoulder triggers
  systemButtons, // SELECT, START, ESC buttons
}

extension GamepadHudElementExt on GamepadHudElement {
  String get displayName {
    switch (this) {
      case GamepadHudElement.leftStick:
        return 'Movement Stick / D-Pad';
      case GamepadHudElement.abxyCluster:
        return 'Action Buttons (ABXY)';
      case GamepadHudElement.cameraTouchpad:
        return 'Camera Look Pad';
      case GamepadHudElement.leftShoulders:
        return 'Left Shoulders (L1/L2)';
      case GamepadHudElement.rightShoulders:
        return 'Right Shoulders (R1/R2)';
      case GamepadHudElement.systemButtons:
        return 'System (Select/Start/Esc)';
    }
  }

  String get shortName {
    switch (this) {
      case GamepadHudElement.leftStick:
        return 'Stick';
      case GamepadHudElement.abxyCluster:
        return 'ABXY';
      case GamepadHudElement.cameraTouchpad:
        return 'Camera';
      case GamepadHudElement.leftShoulders:
        return 'L1/L2';
      case GamepadHudElement.rightShoulders:
        return 'R1/R2';
      case GamepadHudElement.systemButtons:
        return 'Menu';
    }
  }
}

/// Configuration for an individual HUD element (Position, Scale, Opacity)
class GamepadElementConfig {
  final double relX; // 0.0 to 1.0 (Center X relative to available width)
  final double relY; // 0.0 to 1.0 (Center Y relative to available height)
  final double scale; // 0.7 to 1.6 (Default 1.0)
  final double opacity; // 0.3 to 1.0 (Default 1.0)

  const GamepadElementConfig({
    required this.relX,
    required this.relY,
    this.scale = 1.0,
    this.opacity = 1.0,
  });

  GamepadElementConfig copyWith({
    double? relX,
    double? relY,
    double? scale,
    double? opacity,
  }) {
    return GamepadElementConfig(
      relX: relX ?? this.relX,
      relY: relY ?? this.relY,
      scale: (scale ?? this.scale).clamp(0.65, 1.65),
      opacity: (opacity ?? this.opacity).clamp(0.25, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'relX': relX,
        'relY': relY,
        'scale': scale,
        'opacity': opacity,
      };

  factory GamepadElementConfig.fromJson(Map<String, dynamic> json) =>
      GamepadElementConfig(
        relX: (json['relX'] as num?)?.toDouble() ?? 0.5,
        relY: (json['relY'] as num?)?.toDouble() ?? 0.5,
        scale: ((json['scale'] as num?)?.toDouble() ?? 1.0).clamp(0.65, 1.65),
        opacity:
            ((json['opacity'] as num?)?.toDouble() ?? 1.0).clamp(0.25, 1.0),
      );
}

/// Complete Gamepad HUD Layout configuration for all modules
class GamepadHudLayout {
  final Map<GamepadHudElement, GamepadElementConfig> elements;

  const GamepadHudLayout({required this.elements});

  /// Default PUBG-style balanced layout positions
  static GamepadHudLayout get defaultLayout => GamepadHudLayout(
        elements: {
          GamepadHudElement.leftShoulders: const GamepadElementConfig(
            relX: 0.16,
            relY: 0.22,
            scale: 1.0,
            opacity: 1.0,
          ),
          GamepadHudElement.systemButtons: const GamepadElementConfig(
            relX: 0.50,
            relY: 0.28,
            scale: 1.0,
            opacity: 1.0,
          ),
          GamepadHudElement.rightShoulders: const GamepadElementConfig(
            relX: 0.84,
            relY: 0.22,
            scale: 1.0,
            opacity: 1.0,
          ),
          GamepadHudElement.leftStick: const GamepadElementConfig(
            relX: 0.16,
            relY: 0.72,
            scale: 1.0,
            opacity: 1.0,
          ),
          GamepadHudElement.cameraTouchpad: const GamepadElementConfig(
            relX: 0.50,
            relY: 0.72,
            scale: 1.0,
            opacity: 1.0,
          ),
          GamepadHudElement.abxyCluster: const GamepadElementConfig(
            relX: 0.84,
            relY: 0.72,
            scale: 1.0,
            opacity: 1.0,
          ),
        },
      );

  GamepadElementConfig getConfig(GamepadHudElement element) {
    return elements[element] ??
        defaultLayout.elements[element] ??
        const GamepadElementConfig(relX: 0.5, relY: 0.5);
  }

  GamepadHudLayout updateElement(
    GamepadHudElement element,
    GamepadElementConfig config,
  ) {
    final updated = Map<GamepadHudElement, GamepadElementConfig>.from(elements);
    updated[element] = config;
    return GamepadHudLayout(elements: updated);
  }

  String serialize() {
    final Map<String, dynamic> raw = {};
    elements.forEach((key, value) {
      raw[key.name] = value.toJson();
    });
    return jsonEncode(raw);
  }

  static GamepadHudLayout deserialize(String jsonStr) {
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      final Map<GamepadHudElement, GamepadElementConfig> result = {};

      for (var element in GamepadHudElement.values) {
        if (raw.containsKey(element.name) && raw[element.name] is Map) {
          result[element] = GamepadElementConfig.fromJson(
            Map<String, dynamic>.from(raw[element.name]),
          );
        } else {
          result[element] = defaultLayout.getConfig(element);
        }
      }
      return GamepadHudLayout(elements: result);
    } catch (_) {
      return defaultLayout;
    }
  }
}

/// Helper to compute responsive base dimensions for HUD elements
class GamepadLayoutDimensions {
  static Size getBaseSize(GamepadHudElement element, Size canvasSize) {
    final h = canvasSize.height;
    final w = canvasSize.width;

    // Reference landscape full-screen aspect ratio is ~2.15 (typical modern phone).
    // In non-fullscreen mode (with topbar, banner ad, and navbar active), width is narrower.
    // To preserve exact visual proportions and prevent elements from overlapping,
    // element dimensions scale responsively with aspectFactor.
    final aspectFactor = (w / (h * 2.15)).clamp(0.65, 1.0);

    switch (element) {
      case GamepadHudElement.leftStick:
        // Movement Stick: scales proportionally with height and aspectFactor
        final d = (h * 0.42 * aspectFactor).clamp(105.0, 195.0);
        return Size(d, d);

      case GamepadHudElement.abxyCluster:
        // Action Buttons: matches stick proportions
        final d = (h * 0.42 * aspectFactor).clamp(105.0, 195.0);
        return Size(d, d);

      case GamepadHudElement.cameraTouchpad:
        // Center Touchpad: scales with width and height
        final pw = (w * 0.24).clamp(120.0, 260.0);
        final ph = (h * 0.26 * aspectFactor).clamp(65.0, 135.0);
        return Size(pw, ph);

      case GamepadHudElement.leftShoulders:
      case GamepadHudElement.rightShoulders:
        // Shoulder Triggers (L1/L2 or R1/R2)
        final sw = (w * 0.17).clamp(95.0, 180.0);
        final sh = (h * 0.11 * aspectFactor).clamp(28.0, 50.0);
        return Size(sw, sh);

      case GamepadHudElement.systemButtons:
        // Menu System (SELECT, START, ESC)
        final mw = (w * 0.25).clamp(135.0, 230.0);
        final mh = (h * 0.09 * aspectFactor).clamp(24.0, 42.0);
        return Size(mw, mh);
    }
  }
}
