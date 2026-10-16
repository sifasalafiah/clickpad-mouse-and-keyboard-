import 'package:flutter/material.dart';
import '../services/connection_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import 'tools/macro_deck_screen.dart';
import 'tools/media_remote_screen.dart';
import 'tools/mouse_jiggler_screen.dart';
import 'tools/numpad_screen.dart';
import 'tools/presentation_screen.dart';
import 'tools/scanner_screen.dart';
import 'tools/snippets_screen.dart';

class _ToolHubItem {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? badge;
  final Widget screen;

  const _ToolHubItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.screen,
    this.badge,
  });
}

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ConnectionService _connService = ConnectionService.instance;

  final List<_ToolHubItem> _tools = const [
    _ToolHubItem(
      title: 'Barcode & QR Scanner',
      description: 'Scan barcodes & QR codes directly into PC input fields as keystrokes',
      icon: Icons.qr_code_scanner_rounded,
      accentColor: Color(0xFF00E5FF),
      badge: 'POPULAR',
      screen: ScannerScreen(),
    ),
    _ToolHubItem(
      title: 'Accounting Numpad',
      description: 'Dedicated 10-key numeric keypad for Excel, spreadsheets, and data entry',
      icon: Icons.calculate_rounded,
      accentColor: Color(0xFF10B981),
      badge: 'EXCEL',
      screen: NumpadScreen(),
    ),
    _ToolHubItem(
      title: 'Presentation Clicker',
      description: 'Remote slide presenter with timer, F5 start, and black screen toggle',
      icon: Icons.slideshow_rounded,
      accentColor: Color(0xFFF59E0B),
      badge: 'SLIDES',
      screen: PresentationScreen(),
    ),
    _ToolHubItem(
      title: 'Media Controller',
      description: 'Couch remote for YouTube, Netflix, Spotify with big volume & seek controls',
      icon: Icons.play_circle_fill_rounded,
      accentColor: Color(0xFFEC4899),
      screen: MediaRemoteScreen(),
    ),
    _ToolHubItem(
      title: 'Macro Shortcuts Deck',
      description: '1-tap stream deck for Lock PC, Screenshot, Task Manager, and browser tabs',
      icon: Icons.grid_view_rounded,
      accentColor: Color(0xFF8B5CF6),
      screen: MacroDeckScreen(),
    ),
    _ToolHubItem(
      title: 'Mouse Jiggler',
      description: 'Keep PC awake and prevent screen lock during long downloads or renders',
      icon: Icons.mouse_rounded,
      accentColor: Color(0xFF06B6D4),
      badge: 'UTILITY',
      screen: MouseJigglerScreen(),
    ),
    _ToolHubItem(
      title: 'Quick Text Snippets',
      description: 'Send pre-saved text templates, email signatures, or commands in 1-tap',
      icon: Icons.text_snippet_rounded,
      accentColor: Color(0xFF6366F1),
      screen: SnippetsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isConnected = _connService.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(200),
                      AppColors.accent.withAlpha(160),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ClickPad Tools Hub',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConnected
                                ? 'Connected to ${_connService.connectedDevice?.name ?? "Host"} (HID Active)'
                                : 'Connect via Bluetooth to start using tools',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tools Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = _tools[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticHelper.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => tool.screen),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon container
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: tool.accentColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: tool.accentColor.withAlpha(80)),
                                ),
                                child: Icon(tool.icon, color: tool.accentColor, size: 26),
                              ),
                              const SizedBox(width: 14),

                              // Text details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            tool.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (tool.badge != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tool.accentColor.withAlpha(30),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: tool.accentColor.withAlpha(90)),
                                            ),
                                            child: Text(
                                              tool.badge!,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: tool.accentColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tool.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Chevron arrow
                              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _tools.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
