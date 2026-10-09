import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isRevisit;

  const OnboardingScreen({
    super.key,
    this.isRevisit = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      badge: 'MOUSE',
      badgeIcon: Icons.touch_app_rounded,
      title: 'Use Phone as a Mouse',
      subtitle: 'Easy and smooth pointer control',
      description:
          'Move your computer cursor with a swipe of your finger. Tap anywhere to click, or drag two fingers to scroll up and down.',
      tags: [
        'Tap to click',
        'Two-finger scroll',
        'Touch feedback',
      ],
      type: _VisualType.touchpad,
    ),
    _OnboardingItem(
      badge: 'KEYBOARD & GAMES',
      badgeIcon: Icons.sports_esports_rounded,
      title: 'Type and Play Games',
      subtitle: 'Full keyboard and joystick',
      description:
          'Type text on your computer, use quick keys like Enter and Escape, or use the joystick controller for casual games.',
      tags: [
        'Computer keyboard',
        'Game joystick',
        'Quick shortcuts',
      ],
      type: _VisualType.keyboardAndJoystick,
    ),
    _OnboardingItem(
      badge: 'WIRELESS',
      badgeIcon: Icons.bluetooth_searching_rounded,
      title: 'Fast & Easy Connection',
      subtitle: 'Connects right away with Bluetooth',
      description:
          'Pair your phone with your PC or Mac just like wireless headphones. No extra apps or complicated setup needed on your computer.',
      tags: [
        'Bluetooth ready',
        'Windows & Mac',
        'Simple setup',
      ],
      type: _VisualType.connection,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    HapticHelper.mediumImpact();
    if (!widget.isRevisit) {
      await SettingsService.instance.completeOnboarding();
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    HapticHelper.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Label
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ClickPad',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Skip or Close Button
                  if (!isLastPage || widget.isRevisit)
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: AppColors.surfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        widget.isRevisit ? 'Close' : 'Skip',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                ],
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  HapticHelper.selectionClick();
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _buildSlideContent(item);
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator Dots
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive ? AppColors.primary : AppColors.border,
                        ),
                      );
                    }),
                  ),

                  // Action Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(_OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Preview Card
          _buildVisualCard(item.type)
              .animate()
              .fade(duration: 300.ms),

          const SizedBox(height: 20),

          // Small Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withAlpha(60),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.badgeIcon, size: 13, color: AppColors.primaryLight),
                const SizedBox(width: 5),
                Text(
                  item.badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryLight,
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Feature Tags (Uniform Width, No Emojis)
          LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = ((constraints.maxWidth - 12) / 2).clamp(140.0, 160.0);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: item.tags.map((tag) {
                  return Container(
                    width: chipWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tag,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisualCard(_VisualType type) {
    switch (type) {
      case _VisualType.touchpad:
        return _buildTouchpadVisual();
      case _VisualType.keyboardAndJoystick:
        return _buildKeyboardAndJoystickVisual();
      case _VisualType.connection:
        return _buildConnectionVisual();
    }
  }

  // Visual 1: Clean Touchpad Mockup
  Widget _buildTouchpadVisual() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Touch surface area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withAlpha(30),
                    ),
                    child: const Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Touchpad Area',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Left & Right Buttons
          Container(
            height: 38,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Left Click',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.border),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Right Click',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Visual 2: Keyboard & Joystick Mockup
  Widget _buildKeyboardAndJoystickVisual() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Left: Joystick preview
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.primary.withAlpha(100), width: 1.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Joystick',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 100, color: AppColors.border),
          // Right: Key preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSimpleKey('Esc', isPrimary: true),
                      const SizedBox(width: 6),
                      _buildSimpleKey('Tab'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSimpleKey('Ctrl'),
                      const SizedBox(width: 6),
                      _buildSimpleKey('Enter', isPrimary: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleKey(String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary.withAlpha(30) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPrimary ? AppColors.primaryLight : AppColors.textPrimary,
        ),
      ),
    );
  }

  // Visual 3: Direct Connection Mockup
  Widget _buildConnectionVisual() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Phone
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.smartphone_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Phone',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),

          // Bluetooth link
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(25),
                ),
                child: Icon(
                  Icons.bluetooth_connected_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          // Computer
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.laptop_mac_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Computer',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _VisualType {
  touchpad,
  keyboardAndJoystick,
  connection,
}

class _OnboardingItem {
  final String badge;
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> tags;
  final _VisualType type;

  const _OnboardingItem({
    required this.badge,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tags,
    required this.type,
  });
}
