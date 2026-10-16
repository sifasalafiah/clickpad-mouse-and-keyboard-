import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';

class KeyStroke {
  final int modifier;
  final int keycode;
  const KeyStroke(this.modifier, this.keycode);
}

class HidHelper {
  static final HidHelper instance = HidHelper._internal();
  HidHelper._internal();

  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final ConnectionService _connService = ConnectionService.instance;

  bool get isConnected => _connService.isConnected;

  /// Check if connected host is macOS
  bool get isMacHost {
    final name = (_connService.connectedDevice?.name ?? '').toLowerCase();
    return name.contains('mac') || name.contains('apple') || name.contains('darwin');
  }

  /// Send a single HID key press and release
  void sendKey(int modifier, int keycode) {
    _bleService.sendKeyboardScancode(modifier, keycode);
  }

  /// Send key with held modifiers (e.g. Ctrl+Shift+Esc, Cmd+Opt+Esc, Win+L)
  Future<void> sendShortcutChord(int modifier, int keycode, {int holdMs = 80}) async {
    _bleService.sendKeyboardState(modifier, []);
    await Future.delayed(const Duration(milliseconds: 25));
    _bleService.sendKeyboardState(modifier, [keycode]);
    await Future.delayed(Duration(milliseconds: holdMs));
    _bleService.sendKeyboardState(modifier, []);
    await Future.delayed(const Duration(milliseconds: 25));
    _bleService.sendKeyboardState(0, []);
  }

  /// Send full text string as a sequence of keystrokes with delay
  Future<void> sendText(
    String text, {
    bool sendEnter = false,
    bool sendTab = false,
    int charDelayMs = 18,
    VoidCallback? onProgress,
  }) async {
    for (int i = 0; i < text.length; i++) {
      final stroke = charToKeyStroke(text[i]);
      if (stroke != null) {
        _bleService.sendKeyboardScancode(stroke.modifier, stroke.keycode);
        onProgress?.call();
        await Future.delayed(Duration(milliseconds: charDelayMs));
      }
    }

    if (sendTab) {
      await Future.delayed(const Duration(milliseconds: 30));
      _bleService.sendKeyboardScancode(0x00, 0x2B); // Tab
    }

    if (sendEnter) {
      await Future.delayed(const Duration(milliseconds: 30));
      _bleService.sendKeyboardScancode(0x00, 0x28); // Enter
    }
  }

  /// Convert standard characters to USB HID Scancode & modifier
  static KeyStroke? charToKeyStroke(String char) {
    if (char.isEmpty) return null;
    final codeUnit = char.codeUnitAt(0);

    // Lowercase a-z (0x61 - 0x7A) -> HID 0x04 - 0x1D
    if (codeUnit >= 0x61 && codeUnit <= 0x7A) {
      return KeyStroke(0x00, 0x04 + (codeUnit - 0x61));
    }

    // Uppercase A-Z (0x41 - 0x5A) -> HID 0x04 - 0x1D with Shift (0x02)
    if (codeUnit >= 0x41 && codeUnit <= 0x5A) {
      return KeyStroke(0x02, 0x04 + (codeUnit - 0x41));
    }

    // Digits 1-9 -> HID 0x1E - 0x26, 0 -> 0x27
    if (codeUnit >= 0x31 && codeUnit <= 0x39) {
      return KeyStroke(0x00, 0x1E + (codeUnit - 0x31));
    }
    if (char == '0') return const KeyStroke(0x00, 0x27);

    // Whitespace
    if (char == ' ') return const KeyStroke(0x00, 0x2C);
    if (char == '\n' || char == '\r') return const KeyStroke(0x00, 0x28);
    if (char == '\t') return const KeyStroke(0x00, 0x2B);

    // Symbols
    switch (char) {
      case '!':
        return const KeyStroke(0x02, 0x1E);
      case '@':
        return const KeyStroke(0x02, 0x1F);
      case '#':
        return const KeyStroke(0x02, 0x20);
      case '\$':
        return const KeyStroke(0x02, 0x21);
      case '%':
        return const KeyStroke(0x02, 0x22);
      case '^':
        return const KeyStroke(0x02, 0x23);
      case '&':
        return const KeyStroke(0x02, 0x24);
      case '*':
        return const KeyStroke(0x02, 0x25);
      case '(':
        return const KeyStroke(0x02, 0x26);
      case ')':
        return const KeyStroke(0x02, 0x27);
      case '-':
        return const KeyStroke(0x00, 0x2D);
      case '_':
        return const KeyStroke(0x02, 0x2D);
      case '=':
        return const KeyStroke(0x00, 0x2E);
      case '+':
        return const KeyStroke(0x02, 0x2E);
      case '[':
        return const KeyStroke(0x00, 0x2F);
      case '{':
        return const KeyStroke(0x02, 0x2F);
      case ']':
        return const KeyStroke(0x00, 0x30);
      case '}':
        return const KeyStroke(0x02, 0x30);
      case '\\':
        return const KeyStroke(0x00, 0x31);
      case '|':
        return const KeyStroke(0x02, 0x31);
      case ';':
        return const KeyStroke(0x00, 0x33);
      case ':':
        return const KeyStroke(0x02, 0x33);
      case '\'':
        return const KeyStroke(0x00, 0x34);
      case '"':
        return const KeyStroke(0x02, 0x34);
      case '`':
        return const KeyStroke(0x00, 0x35);
      case '~':
        return const KeyStroke(0x02, 0x35);
      case ',':
        return const KeyStroke(0x00, 0x36);
      case '<':
        return const KeyStroke(0x02, 0x36);
      case '.':
        return const KeyStroke(0x00, 0x37);
      case '>':
        return const KeyStroke(0x02, 0x37);
      case '/':
        return const KeyStroke(0x00, 0x38);
      case '?':
        return const KeyStroke(0x02, 0x38);
      default:
        return null;
    }
  }
}
