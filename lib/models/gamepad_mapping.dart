import 'dart:convert';

/// Unique identifiers for every physical button on the virtual gamepad
enum GamepadButtonId {
  l1,
  l2,
  r1,
  r2,
  buttonY,
  buttonX,
  buttonB,
  buttonA,
  select,
  start,
  esc,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
}

extension GamepadButtonIdExt on GamepadButtonId {
  String get displayName {
    switch (this) {
      case GamepadButtonId.l1:
        return 'L1 (Shoulder Left)';
      case GamepadButtonId.l2:
        return 'L2 (Trigger Left)';
      case GamepadButtonId.r1:
        return 'R1 (Shoulder Right)';
      case GamepadButtonId.r2:
        return 'R2 (Trigger Right)';
      case GamepadButtonId.buttonY:
        return 'Y Button (Top)';
      case GamepadButtonId.buttonX:
        return 'X Button (Left)';
      case GamepadButtonId.buttonB:
        return 'B Button (Right)';
      case GamepadButtonId.buttonA:
        return 'A Button (Bottom)';
      case GamepadButtonId.select:
        return 'SELECT Button';
      case GamepadButtonId.start:
        return 'START Button';
      case GamepadButtonId.esc:
        return 'ESC Button';
      case GamepadButtonId.dpadUp:
        return 'D-Pad Up';
      case GamepadButtonId.dpadDown:
        return 'D-Pad Down';
      case GamepadButtonId.dpadLeft:
        return 'D-Pad Left';
      case GamepadButtonId.dpadRight:
        return 'D-Pad Right';
    }
  }

  String get shortName {
    switch (this) {
      case GamepadButtonId.l1:
        return 'L1';
      case GamepadButtonId.l2:
        return 'L2';
      case GamepadButtonId.r1:
        return 'R1';
      case GamepadButtonId.r2:
        return 'R2';
      case GamepadButtonId.buttonY:
        return 'Y';
      case GamepadButtonId.buttonX:
        return 'X';
      case GamepadButtonId.buttonB:
        return 'B';
      case GamepadButtonId.buttonA:
        return 'A';
      case GamepadButtonId.select:
        return 'SELECT';
      case GamepadButtonId.start:
        return 'START';
      case GamepadButtonId.esc:
        return 'ESC';
      case GamepadButtonId.dpadUp:
        return 'UP';
      case GamepadButtonId.dpadDown:
        return 'DOWN';
      case GamepadButtonId.dpadLeft:
        return 'LEFT';
      case GamepadButtonId.dpadRight:
        return 'RIGHT';
    }
  }
}

/// A standard USB HID key definition with code, display name, and category
class HidKeyDefinition {
  final int scancode;
  final String name;
  final String shortLabel;
  final String category;

  const HidKeyDefinition({
    required this.scancode,
    required this.name,
    required this.shortLabel,
    required this.category,
  });

  static const List<HidKeyDefinition> allKeys = [
    // Gaming Essentials
    HidKeyDefinition(scancode: 0x2C, name: 'Spacebar (Jump)', shortLabel: 'Space', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0xE1, name: 'Left Shift (Sprint / Run)', shortLabel: 'Shift', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0xE0, name: 'Left Ctrl (Crouch / Sneak)', shortLabel: 'Ctrl', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0xE2, name: 'Left Alt (Walk / Dodge)', shortLabel: 'Alt', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x28, name: 'Enter (Confirm / Chat)', shortLabel: 'Enter', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x29, name: 'Escape (Menu / Cancel)', shortLabel: 'Esc', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x2B, name: 'Tab (Scoreboard / Inventory)', shortLabel: 'Tab', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x08, name: 'E (Interact / Use)', shortLabel: 'E', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x15, name: 'R (Reload / Reset)', shortLabel: 'R', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x09, name: 'F (Flashlight / Use)', shortLabel: 'F', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x14, name: 'Q (Ability / Quick Swap)', shortLabel: 'Q', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x06, name: 'C (Crouch / Prone)', shortLabel: 'C', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x19, name: 'V (Melee / Ping)', shortLabel: 'V', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x1D, name: 'Z (Prone / Ability)', shortLabel: 'Z', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x1B, name: 'X (Secondary Action)', shortLabel: 'X', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x0A, name: 'G (Grenade / Throw)', shortLabel: 'G', category: 'Gaming Keys'),
    HidKeyDefinition(scancode: 0x10, name: 'M (Map)', shortLabel: 'M', category: 'Gaming Keys'),

    // Movement (WASD)
    HidKeyDefinition(scancode: 0x1A, name: 'W (Move Forward)', shortLabel: 'W', category: 'Movement'),
    HidKeyDefinition(scancode: 0x04, name: 'A (Move Left)', shortLabel: 'A', category: 'Movement'),
    HidKeyDefinition(scancode: 0x16, name: 'S (Move Backward)', shortLabel: 'S', category: 'Movement'),
    HidKeyDefinition(scancode: 0x07, name: 'D (Move Right)', shortLabel: 'D', category: 'Movement'),

    // Arrow Keys
    HidKeyDefinition(scancode: 0x52, name: 'Arrow Up', shortLabel: '▲', category: 'Arrows & Nav'),
    HidKeyDefinition(scancode: 0x51, name: 'Arrow Down', shortLabel: '▼', category: 'Arrows & Nav'),
    HidKeyDefinition(scancode: 0x50, name: 'Arrow Left', shortLabel: '◄', category: 'Arrows & Nav'),
    HidKeyDefinition(scancode: 0x4F, name: 'Arrow Right', shortLabel: '►', category: 'Arrows & Nav'),

    // Alphabet A - Z
    HidKeyDefinition(scancode: 0x04, name: 'Letter A', shortLabel: 'A', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x05, name: 'Letter B', shortLabel: 'B', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x06, name: 'Letter C', shortLabel: 'C', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x07, name: 'Letter D', shortLabel: 'D', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x08, name: 'Letter E', shortLabel: 'E', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x09, name: 'Letter F', shortLabel: 'F', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x0A, name: 'Letter G', shortLabel: 'G', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x0B, name: 'Letter H', shortLabel: 'H', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x0C, name: 'Letter I', shortLabel: 'I', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x0D, name: 'Letter J', shortLabel: 'J', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x0E, name: 'Letter K', shortLabel: 'K', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x0F, name: 'Letter L', shortLabel: 'L', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x10, name: 'Letter M', shortLabel: 'M', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x11, name: 'Letter N', shortLabel: 'N', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x12, name: 'Letter O', shortLabel: 'O', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x13, name: 'Letter P', shortLabel: 'P', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x14, name: 'Letter Q', shortLabel: 'Q', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x15, name: 'Letter R', shortLabel: 'R', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x16, name: 'Letter S', shortLabel: 'S', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x17, name: 'Letter T', shortLabel: 'T', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x18, name: 'Letter U', shortLabel: 'U', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x19, name: 'Letter V', shortLabel: 'V', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x1A, name: 'Letter W', shortLabel: 'W', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x1B, name: 'Letter X', shortLabel: 'X', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x1C, name: 'Letter Y', shortLabel: 'Y', category: 'Alphabet'),
    HidKeyDefinition(scancode: 0x1D, name: 'Letter Z', shortLabel: 'Z', category: 'Alphabet'),

    // Numbers (1 - 0)
    HidKeyDefinition(scancode: 0x1E, name: 'Number 1', shortLabel: '1', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x1F, name: 'Number 2', shortLabel: '2', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x20, name: 'Number 3', shortLabel: '3', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x21, name: 'Number 4', shortLabel: '4', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x22, name: 'Number 5', shortLabel: '5', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x23, name: 'Number 6', shortLabel: '6', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x24, name: 'Number 7', shortLabel: '7', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x25, name: 'Number 8', shortLabel: '8', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x26, name: 'Number 9', shortLabel: '9', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x27, name: 'Number 0', shortLabel: '0', category: 'Numbers & Fn'),

    // Function Keys
    HidKeyDefinition(scancode: 0x3A, name: 'F1', shortLabel: 'F1', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x3B, name: 'F2', shortLabel: 'F2', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x3C, name: 'F3', shortLabel: 'F3', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x3D, name: 'F4', shortLabel: 'F4', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x3E, name: 'F5 (Quick Save)', shortLabel: 'F5', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x42, name: 'F9 (Quick Load)', shortLabel: 'F9', category: 'Numbers & Fn'),
    HidKeyDefinition(scancode: 0x45, name: 'F12 (Screenshot)', shortLabel: 'F12', category: 'Numbers & Fn'),
  ];

  static HidKeyDefinition findByScancode(int scancode) {
    return allKeys.firstWhere(
      (k) => k.scancode == scancode,
      orElse: () => HidKeyDefinition(
        scancode: scancode,
        name: 'Key 0x${scancode.toRadixString(16).toUpperCase()}',
        shortLabel: '0x${scancode.toRadixString(16).toUpperCase()}',
        category: 'Other',
      ),
    );
  }
}

/// Profile preset for gamepad layout mappings
class GamepadProfilePreset {
  final String id;
  final String name;
  final String description;
  final Map<GamepadButtonId, int> mappings;

  const GamepadProfilePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.mappings,
  });

  /// 1. Standard FPS & Action (Default)
  static const GamepadProfilePreset standardFps = GamepadProfilePreset(
    id: 'fps_action',
    name: 'FPS & Action RPG',
    description: 'WASD movement, Space jump, Shift sprint, Ctrl crouch, E interact, R reload',
    mappings: {
      GamepadButtonId.l1: 0xE1, // Left Shift
      GamepadButtonId.l2: 0xE0, // Left Ctrl
      GamepadButtonId.r1: 0x2C, // Space
      GamepadButtonId.r2: 0x28, // Enter
      GamepadButtonId.buttonY: 0x08, // E
      GamepadButtonId.buttonX: 0x15, // R
      GamepadButtonId.buttonB: 0x06, // C
      GamepadButtonId.buttonA: 0x2C, // Space
      GamepadButtonId.select: 0x2B, // Tab
      GamepadButtonId.start: 0x28, // Enter
      GamepadButtonId.esc: 0x29, // Esc
      GamepadButtonId.dpadUp: 0x1A, // W
      GamepadButtonId.dpadDown: 0x16, // S
      GamepadButtonId.dpadLeft: 0x04, // A
      GamepadButtonId.dpadRight: 0x07, // D
    },
  );

  /// 2. Retro & Platformer
  static const GamepadProfilePreset retroPlatformer = GamepadProfilePreset(
    id: 'retro_platformer',
    name: 'Retro Platformer',
    description: 'Arrow keys, Z jump/action, X attack, C dash, Shift run, Esc pause',
    mappings: {
      GamepadButtonId.l1: 0x14, // Q
      GamepadButtonId.l2: 0x08, // E
      GamepadButtonId.r1: 0x1D, // Z
      GamepadButtonId.r2: 0x1B, // X
      GamepadButtonId.buttonY: 0x06, // C
      GamepadButtonId.buttonX: 0x1B, // X
      GamepadButtonId.buttonB: 0x29, // Esc
      GamepadButtonId.buttonA: 0x1D, // Z
      GamepadButtonId.select: 0xE1, // Shift
      GamepadButtonId.start: 0x28, // Enter
      GamepadButtonId.esc: 0x29, // Esc
      GamepadButtonId.dpadUp: 0x52, // Up Arrow
      GamepadButtonId.dpadDown: 0x51, // Down Arrow
      GamepadButtonId.dpadLeft: 0x50, // Left Arrow
      GamepadButtonId.dpadRight: 0x4F, // Right Arrow
    },
  );

  /// 3. Racing & Driving
  static const GamepadProfilePreset racing = GamepadProfilePreset(
    id: 'racing',
    name: 'Racing & Driving',
    description: 'W/R2 gas, S/L2 brake, Space handbrake, Shift boost/nitro, C camera',
    mappings: {
      GamepadButtonId.l1: 0xE0, // Ctrl
      GamepadButtonId.l2: 0x16, // S (Brake)
      GamepadButtonId.r1: 0xE1, // Shift (Nitro)
      GamepadButtonId.r2: 0x1A, // W (Throttle)
      GamepadButtonId.buttonY: 0x06, // C (Camera)
      GamepadButtonId.buttonX: 0x15, // R (Reset Car)
      GamepadButtonId.buttonB: 0x2C, // Space (Handbrake)
      GamepadButtonId.buttonA: 0x28, // Enter (Horn)
      GamepadButtonId.select: 0x2B, // Tab (Map)
      GamepadButtonId.start: 0x29, // Esc (Pause)
      GamepadButtonId.esc: 0x29, // Esc
      GamepadButtonId.dpadUp: 0x1A, // W
      GamepadButtonId.dpadDown: 0x16, // S
      GamepadButtonId.dpadLeft: 0x04, // A
      GamepadButtonId.dpadRight: 0x07, // D
    },
  );

  static const List<GamepadProfilePreset> allPresets = [
    standardFps,
    retroPlatformer,
    racing,
  ];

  static Map<GamepadButtonId, int> clone(Map<GamepadButtonId, int> source) {
    return Map<GamepadButtonId, int>.from(source);
  }

  static String serialize(Map<GamepadButtonId, int> map) {
    final Map<String, int> stringMap = {};
    map.forEach((key, value) {
      stringMap[key.name] = value;
    });
    return jsonEncode(stringMap);
  }

  static Map<GamepadButtonId, int> deserialize(String jsonStr) {
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      final Map<GamepadButtonId, int> result = {};
      raw.forEach((key, value) {
        final buttonId = GamepadButtonId.values.firstWhere(
          (e) => e.name == key,
          orElse: () => GamepadButtonId.buttonA,
        );
        if (value is int) {
          result[buttonId] = value;
        }
      });
      return result;
    } catch (_) {
      return clone(standardFps.mappings);
    }
  }
}
