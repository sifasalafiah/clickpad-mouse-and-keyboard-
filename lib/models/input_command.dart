import 'dart:convert';

enum CommandType {
  move,
  click,
  scroll,
  keyPress,
  keyDown,
  keyUp,
  shortcut,
  media,
}

class InputCommand {
  final CommandType type;
  final double dx;
  final double dy;
  final String? button; // 'left', 'right', 'middle'
  final String? key;
  final List<String>? modifiers; // ['ctrl', 'shift', 'alt', 'cmd']
  final String? action; // 'play_pause', 'vol_up', 'vol_down', 'next', 'prev'

  InputCommand({
    required this.type,
    this.dx = 0.0,
    this.dy = 0.0,
    this.button,
    this.key,
    this.modifiers,
    this.action,
  });

  factory InputCommand.move(double dx, double dy) {
    return InputCommand(type: CommandType.move, dx: dx, dy: dy);
  }

  factory InputCommand.click(String button) {
    return InputCommand(type: CommandType.click, button: button);
  }

  factory InputCommand.scroll(double dx, double dy) {
    return InputCommand(type: CommandType.scroll, dx: dx, dy: dy);
  }

  factory InputCommand.keyPress(String key, {List<String>? modifiers}) {
    return InputCommand(type: CommandType.keyPress, key: key, modifiers: modifiers);
  }

  factory InputCommand.shortcut(String action) {
    return InputCommand(type: CommandType.shortcut, action: action);
  }

  factory InputCommand.media(String action) {
    return InputCommand(type: CommandType.media, action: action);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      't': type.name,
    };
    if (dx != 0.0) map['dx'] = double.parse(dx.toStringAsFixed(2));
    if (dy != 0.0) map['dy'] = double.parse(dy.toStringAsFixed(2));
    if (button != null) map['b'] = button;
    if (key != null) map['k'] = key;
    if (modifiers != null && modifiers!.isNotEmpty) map['m'] = modifiers;
    if (action != null) map['a'] = action;
    return map;
  }

  String toJsonString() => jsonEncode(toJson());

  factory InputCommand.fromJson(Map<String, dynamic> json) {
    final typeName = json['t'] as String? ?? 'move';
    final type = CommandType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CommandType.move,
    );
    return InputCommand(
      type: type,
      dx: (json['dx'] as num?)?.toDouble() ?? 0.0,
      dy: (json['dy'] as num?)?.toDouble() ?? 0.0,
      button: json['b'] as String?,
      key: json['k'] as String?,
      modifiers: (json['m'] as List?)?.cast<String>(),
      action: json['a'] as String?,
    );
  }
}
