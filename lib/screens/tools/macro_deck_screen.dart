import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/iap_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../../utils/hid_helper.dart';

class _MacroItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Future<void> Function() onExecute;

  const _MacroItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onExecute,
  });
}

class MacroDeckScreen extends StatefulWidget {
  const MacroDeckScreen({super.key});

  @override
  State<MacroDeckScreen> createState() => _MacroDeckScreenState();
}

class _MacroDeckScreenState extends State<MacroDeckScreen> {
  static const String _prefOsKey = 'clickpad_macro_os_mode';
  final HidHelper _hid = HidHelper.instance;
  final SettingsService _settings = SettingsService.instance;
  final IapService _iapService = IapService.instance;
  int _selectedOsIndex = 0; // 0: macOS, 1: Windows

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onServiceUpdate);
    _iapService.addListener(_onServiceUpdate);
    // Default auto-detect based on host name
    _selectedOsIndex = _hid.isMacHost ? 0 : 1;
    _loadSavedOsPreference();
  }

  @override
  void dispose() {
    _settings.removeListener(_onServiceUpdate);
    _iapService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedOsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefOsKey);
    if (saved != null && mounted) {
      setState(() => _selectedOsIndex = saved);
    }
  }

  Future<void> _setOsIndex(int index) async {
    HapticHelper.selectionClick();
    setState(() => _selectedOsIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefOsKey, index);
  }

  bool get _isMac => _selectedOsIndex == 0;

  List<_MacroItem> get _systemMacros {
    if (_isMac) {
      return [
        _MacroItem(
          title: 'Lock Screen',
          subtitle: 'Ctrl + Cmd + Q',
          icon: Icons.lock_outline_rounded,
          color: Colors.redAccent,
          onExecute: () => _hid.sendShortcutChord(0x09, 0x14), // Ctrl+Cmd+Q
        ),
        _MacroItem(
          title: 'Screenshot Area',
          subtitle: 'Cmd + Shift + 4',
          icon: Icons.crop_free_rounded,
          color: Colors.purpleAccent,
          onExecute: () => _hid.sendShortcutChord(0x0A, 0x21), // Cmd+Shift+4
        ),
        _MacroItem(
          title: 'Force Quit Apps',
          subtitle: 'Cmd + Opt + Esc',
          icon: Icons.dangerous_outlined,
          color: Colors.tealAccent,
          onExecute: () => _hid.sendShortcutChord(0x0C, 0x29), // Cmd+Option+Esc
        ),
        _MacroItem(
          title: 'Mission Control',
          subtitle: 'Ctrl + ▲ Up',
          icon: Icons.dashboard_rounded,
          color: Colors.blueAccent,
          onExecute: () => _hid.sendShortcutChord(0x01, 0x52), // Ctrl+Up Arrow
        ),
        _MacroItem(
          title: 'Show Desktop',
          subtitle: 'F11 / Cmd + F3',
          icon: Icons.desktop_windows_outlined,
          color: Colors.orangeAccent,
          onExecute: () => _hid.sendShortcutChord(0x00, 0x44), // F11 macOS Show Desktop
        ),
        _MacroItem(
          title: 'Hide Active App',
          subtitle: 'Cmd + H',
          icon: Icons.visibility_off_outlined,
          color: Colors.deepOrangeAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x0B), // Cmd+H
        ),
        _MacroItem(
          title: 'Spotlight Search',
          subtitle: 'Cmd + Space',
          icon: Icons.search_rounded,
          color: Colors.indigoAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x2C), // Cmd+Space
        ),
        _MacroItem(
          title: 'Open Finder',
          subtitle: 'Cmd + Opt + Space',
          icon: Icons.folder_open_rounded,
          color: Colors.amber,
          onExecute: () => _hid.sendShortcutChord(0x0C, 0x2C), // Cmd+Opt+Space
        ),
        _MacroItem(
          title: 'Quit Application',
          subtitle: 'Cmd + Q',
          icon: Icons.power_settings_new_rounded,
          color: Colors.red,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x14), // Cmd+Q
        ),
        _MacroItem(
          title: 'Preferences',
          subtitle: 'Cmd + ,',
          icon: Icons.settings_outlined,
          color: Colors.blueGrey,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x36), // Cmd+,
        ),
        _MacroItem(
          title: 'App Switcher',
          subtitle: 'Cmd + Tab',
          icon: Icons.tab_rounded,
          color: Colors.cyan,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x2B), // Cmd+Tab
        ),
        _MacroItem(
          title: 'Launchpad',
          subtitle: 'F4 / Fn + F4',
          icon: Icons.rocket_launch_rounded,
          color: Colors.pinkAccent,
          onExecute: () => _hid.sendShortcutChord(0x00, 0x3D), // F4
        ),
      ];
    } else {
      return [
        _MacroItem(
          title: 'Lock PC',
          subtitle: 'Win + L',
          icon: Icons.lock_outline_rounded,
          color: Colors.redAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x0F), // Win+L
        ),
        _MacroItem(
          title: 'Screenshot Snipping',
          subtitle: 'Win + Shift + S',
          icon: Icons.crop_free_rounded,
          color: Colors.purpleAccent,
          onExecute: () => _hid.sendShortcutChord(0x0A, 0x16), // Win+Shift+S
        ),
        _MacroItem(
          title: 'Task Manager',
          subtitle: 'Ctrl + Shift + Esc',
          icon: Icons.monitor_heart_outlined,
          color: Colors.tealAccent,
          onExecute: () => _hid.sendShortcutChord(0x03, 0x29), // Ctrl+Shift+Esc
        ),
        _MacroItem(
          title: 'Task View',
          subtitle: 'Win + Tab',
          icon: Icons.dashboard_rounded,
          color: Colors.blueAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x2B), // Win+Tab
        ),
        _MacroItem(
          title: 'Show Desktop',
          subtitle: 'Win + D',
          icon: Icons.desktop_windows_outlined,
          color: Colors.orangeAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x07), // Win+D
        ),
        _MacroItem(
          title: 'Minimize All',
          subtitle: 'Win + M',
          icon: Icons.minimize_rounded,
          color: Colors.deepOrangeAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x10), // Win+M
        ),
        _MacroItem(
          title: 'Windows Search',
          subtitle: 'Win + S',
          icon: Icons.search_rounded,
          color: Colors.indigoAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x16), // Win+S
        ),
        _MacroItem(
          title: 'File Explorer',
          subtitle: 'Win + E',
          icon: Icons.folder_open_rounded,
          color: Colors.amber,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x08), // Win+E
        ),
        _MacroItem(
          title: 'Close Window',
          subtitle: 'Alt + F4',
          icon: Icons.power_settings_new_rounded,
          color: Colors.red,
          onExecute: () => _hid.sendShortcutChord(0x04, 0x3D), // Alt+F4
        ),
        _MacroItem(
          title: 'Windows Settings',
          subtitle: 'Win + I',
          icon: Icons.settings_outlined,
          color: Colors.blueGrey,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x0C), // Win+I
        ),
        _MacroItem(
          title: 'App Switcher',
          subtitle: 'Alt + Tab',
          icon: Icons.tab_rounded,
          color: Colors.cyan,
          onExecute: () => _hid.sendShortcutChord(0x04, 0x2B), // Alt+Tab
        ),
        _MacroItem(
          title: 'Run Dialog',
          subtitle: 'Win + R',
          icon: Icons.terminal_rounded,
          color: Colors.pinkAccent,
          onExecute: () => _hid.sendShortcutChord(0x08, 0x15), // Win+R
        ),
      ];
    }
  }

  List<_MacroItem> get _browserMacros {
    final mod = _isMac ? 0x08 : 0x01; // Cmd (0x08) vs Ctrl (0x01)
    final shiftMod = _isMac ? 0x0A : 0x03; // Cmd+Shift (0x0A) vs Ctrl+Shift (0x03)
    final prefix = _isMac ? 'Cmd' : 'Ctrl';

    return [
      _MacroItem(
        title: 'New Tab',
        subtitle: '$prefix + T',
        icon: Icons.add_circle_outline_rounded,
        color: Colors.cyan,
        onExecute: () => _hid.sendShortcutChord(mod, 0x17), // T
      ),
      _MacroItem(
        title: 'Close Tab',
        subtitle: '$prefix + W',
        icon: Icons.highlight_off_rounded,
        color: Colors.pinkAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x1A), // W
      ),
      _MacroItem(
        title: 'Reopen Tab',
        subtitle: '$prefix + Shift + T',
        icon: Icons.history_rounded,
        color: Colors.lightGreenAccent,
        onExecute: () => _hid.sendShortcutChord(shiftMod, 0x17), // Shift+T
      ),
      _MacroItem(
        title: 'Refresh Page',
        subtitle: '$prefix + R',
        icon: Icons.refresh_rounded,
        color: Colors.lightBlue,
        onExecute: () => _hid.sendShortcutChord(mod, 0x15), // R
      ),
      _MacroItem(
        title: 'Copy Text',
        subtitle: '$prefix + C',
        icon: Icons.copy_rounded,
        color: Colors.indigoAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x06), // C
      ),
      _MacroItem(
        title: 'Paste Text',
        subtitle: '$prefix + V',
        icon: Icons.paste_rounded,
        color: Colors.tealAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x19), // V
      ),
      _MacroItem(
        title: 'Select All',
        subtitle: '$prefix + A',
        icon: Icons.select_all_rounded,
        color: Colors.deepPurpleAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x04), // A
      ),
      _MacroItem(
        title: 'Find on Page',
        subtitle: '$prefix + F',
        icon: Icons.search_rounded,
        color: Colors.purpleAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x09), // F
      ),
      _MacroItem(
        title: 'Undo Action',
        subtitle: '$prefix + Z',
        icon: Icons.undo_rounded,
        color: Colors.amberAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x1D), // Z
      ),
      _MacroItem(
        title: 'Redo Action',
        subtitle: _isMac ? 'Cmd + Shift + Z' : 'Ctrl + Y',
        icon: Icons.redo_rounded,
        color: Colors.teal,
        onExecute: () => _isMac
            ? _hid.sendShortcutChord(0x0A, 0x1D) // Cmd+Shift+Z
            : _hid.sendShortcutChord(0x01, 0x1C), // Ctrl+Y
      ),
      _MacroItem(
        title: 'Save File',
        subtitle: '$prefix + S',
        icon: Icons.save_outlined,
        color: Colors.greenAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x16), // S
      ),
      _MacroItem(
        title: 'Cut Text',
        subtitle: '$prefix + X',
        icon: Icons.content_cut_rounded,
        color: Colors.redAccent,
        onExecute: () => _hid.sendShortcutChord(mod, 0x1B), // X
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Macro Shortcuts Deck',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (_iapService.isTrialActive)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${(_iapService.trialSecondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_iapService.trialSecondsLeft % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OS Platform Switcher Bar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildOsTab(0, 'macOS Mode', Icons.apple),
                    const SizedBox(width: 4),
                    _buildOsTab(1, 'Windows Mode', Icons.window_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // System Shortcuts Header
              Row(
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isMac
                        ? 'macOS System Shortcuts'
                        : 'Windows System Shortcuts',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Responsive System Grid (100% overflow safe)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _systemMacros.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      childAspectRatio: isWide ? 2.6 : 2.05,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, idx) =>
                        _buildMacroCard(_systemMacros[idx]),
                  );
                },
              ),
              const SizedBox(height: 22),

              // Browser & Productivity Header
              Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Browser & Editing Shortcuts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Responsive Browser Grid (100% overflow safe)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _browserMacros.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      childAspectRatio: isWide ? 2.6 : 2.05,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, idx) =>
                        _buildMacroCard(_browserMacros[idx]),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOsTab(int index, String label, IconData icon) {
    final isSelected = _selectedOsIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _setOsIndex(index),
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard(_MacroItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticHelper.mediumImpact();
          item.onExecute();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
