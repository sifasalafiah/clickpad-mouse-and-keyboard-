import 'package:flutter/material.dart';
import '../services/ad_service.dart';
import '../services/connection_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/pro_purchase_modal.dart';
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
  final bool isPro;

  const _ToolHubItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.screen,
    this.badge,
    this.isPro = false,
  });
}

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ConnectionService _connService = ConnectionService.instance;
  final SettingsService _settings = SettingsService.instance;
  final IapService _iapService = IapService.instance;

  final List<_ToolHubItem> _tools = const [
    _ToolHubItem(
      title: 'Barcode & QR Scanner',
      description:
          'Scan barcodes & QR codes directly into PC input fields as keystrokes',
      icon: Icons.qr_code_scanner_rounded,
      accentColor: Color(0xFF4F46E5),
      badge: 'POPULAR',
      screen: ScannerScreen(),
      isPro: false,
    ),
    _ToolHubItem(
      title: 'Presentation Clicker',
      description:
          'Remote slide presenter with timer, F5 start, and black screen toggle',
      icon: Icons.slideshow_rounded,
      accentColor: Color(0xFFF59E0B),
      badge: 'SLIDES',
      screen: PresentationScreen(),
      isPro: false,
    ),
    _ToolHubItem(
      title: 'Quick Text Snippets',
      description:
          'Send pre-saved text templates, email signatures, or commands in 1-tap',
      icon: Icons.text_snippet_rounded,
      accentColor: Color(0xFF6366F1),
      screen: SnippetsScreen(),
      isPro: false,
    ),
    _ToolHubItem(
      title: 'Macro Shortcuts Deck',
      description:
          '1-tap stream deck for Lock PC, Screenshot, Task Manager, and browser tabs',
      icon: Icons.grid_view_rounded,
      accentColor: Color(0xFF8B5CF6),
      badge: 'PRO',
      screen: MacroDeckScreen(),
      isPro: true,
    ),
    _ToolHubItem(
      title: 'Mouse Jiggler',
      description:
          'Keep PC awake and prevent screen lock during long downloads or renders',
      icon: Icons.mouse_rounded,
      accentColor: Color(0xFF0284C7),
      badge: 'PRO',
      screen: MouseJigglerScreen(),
      isPro: true,
    ),
    _ToolHubItem(
      title: 'Media Controller',
      description:
          'Couch remote for YouTube, Netflix, Spotify with big volume & seek controls',
      icon: Icons.play_circle_fill_rounded,
      accentColor: Color(0xFFE11D48),
      badge: 'PRO',
      screen: MediaRemoteScreen(),
      isPro: true,
    ),
    _ToolHubItem(
      title: 'Accounting Numpad',
      description:
          'Dedicated 10-key numeric keypad for Excel, spreadsheets, and data entry',
      icon: Icons.calculate_rounded,
      accentColor: Color(0xFF10B981),
      badge: 'PRO',
      screen: NumpadScreen(),
      isPro: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onServiceUpdate);
    _iapService.addListener(_onServiceUpdate);
    _connService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _settings.removeListener(_onServiceUpdate);
    _iapService.removeListener(_onServiceUpdate);
    _connService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  bool get _isProUnlocked => _iapService.isPro || _iapService.isTrialActive;

  @override
  Widget build(BuildContext context) {
    final isTrial = _iapService.isTrialActive;
    final trialSeconds = _iapService.trialSecondsLeft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            return CustomScrollView(
              slivers: [
                // Free Trial Active Countdown Notice
                if (isTrial)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: InkWell(
                        onTap: () {
                          HapticHelper.mediumImpact();
                          AdService.instance.showRewardedTrialFlow(
                            context,
                            onSuccess: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '🎉 +3 Minutes added to your Free Trial!',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Free Trial Active: ${(trialSeconds ~/ 60).toString().padLeft(2, '0')}:${(trialSeconds % 60).toString().padLeft(2, '0')} remaining (All Tools Unlocked)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '+3m',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Responsive Tools Grid / List
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, isTrial ? 4 : 16, 16, 16),
                  sliver: isWide
                      ? SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildToolCard(_tools[index]),
                            childCount: _tools.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildToolCard(_tools[index]),
                            );
                          }, childCount: _tools.length),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolCard(_ToolHubItem tool) {
    final isLocked = tool.isPro && !_isProUnlocked;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticHelper.mediumImpact();
          if (isLocked) {
            _showProLockModal(tool);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => tool.screen),
            );
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFFFFD700).withAlpha(120)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: isLocked
                    ? const Color(0xFFFFD700).withAlpha(18)
                    : (AppColors.palette.isLight
                          ? Colors.black.withAlpha(8)
                          : Colors.black.withAlpha(20)),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isLocked
                      ? const Color(0xFFFFD700).withAlpha(25)
                      : tool.accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLocked
                        ? const Color(0xFFFFD700).withAlpha(90)
                        : tool.accentColor.withAlpha(80),
                  ),
                ),
                child: Icon(
                  tool.icon,
                  color: isLocked ? const Color(0xFFFFD700) : tool.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Text details with zero-overflow Wrap
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          tool.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withAlpha(140),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 10,
                                  color: Color(0xFFFFD700),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFD700),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (tool.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tool.accentColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tool.accentColor.withAlpha(90),
                              ),
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
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.description,
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
              const SizedBox(width: 8),

              // Chevron or Lock arrow
              Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                color: isLocked ? const Color(0xFFFFD700) : AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProLockModal(_ToolHubItem tool) {
    HapticHelper.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with Gold circular background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFFFFD700,
                  ).withAlpha(AppColors.palette.isLight ? 45 : 30),
                ),
                child: Icon(
                  tool.icon,
                  color: const Color(0xFFFFD700),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'PRO Exclusive Feature',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Unlock "${tool.title}" and full desktop remote productivity tools with ClickPad PRO.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),

              // Button 1: Unlock PRO Lifetime
              ElevatedButton.icon(
                onPressed: () {
                  HapticHelper.mediumImpact();
                  Navigator.pop(ctx);
                  ProPurchaseModal.show(context);
                },
                icon: const Icon(Icons.workspace_premium, size: 20),
                label: const Text('Unlock with PRO Lifetime'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Button 2: Watch Video for 3-Min Free Trial
              if (_iapService.canStartTrial)
                TextButton.icon(
                  onPressed: () {
                    HapticHelper.selectionClick();
                    Navigator.pop(ctx);
                    AdService.instance.showRewardedTrialFlow(
                      context,
                      onSuccess: () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🎉 3-Minute Free Trial activated! ${tool.title} unlocked.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => tool.screen),
                          );
                        }
                      },
                    );
                  },
                  icon: Icon(
                    Icons.ondemand_video_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  label: Text(
                    _iapService.isTrialActive
                        ? 'Extend Free Trial (+3 Mins)'
                        : 'Watch Video for 3-Min Free Trial',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
