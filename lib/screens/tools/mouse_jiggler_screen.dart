import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/input_command.dart';
import '../../services/connection_service.dart';
import '../../services/iap_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';

class MouseJigglerScreen extends StatefulWidget {
  const MouseJigglerScreen({super.key});

  @override
  State<MouseJigglerScreen> createState() => _MouseJigglerScreenState();
}

class _MouseJigglerScreenState extends State<MouseJigglerScreen> with SingleTickerProviderStateMixin {
  final ConnectionService _connService = ConnectionService.instance;
  final SettingsService _settings = SettingsService.instance;
  final IapService _iapService = IapService.instance;

  bool _isActive = false;
  int _intervalSeconds = 30;
  int _countdownSeconds = 30;
  int _jigglesCount = 0;
  int _totalActiveSeconds = 0;

  Timer? _countdownTimer;
  Timer? _statsTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onServiceUpdate);
    _iapService.addListener(_onServiceUpdate);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _settings.removeListener(_onServiceUpdate);
    _iapService.removeListener(_onServiceUpdate);
    _stopJiggler();
    _pulseController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _toggleJiggler() {
    HapticHelper.mediumImpact();
    setState(() {
      if (_isActive) {
        _stopJiggler();
      } else {
        _startJiggler();
      }
    });
  }

  void _startJiggler() {
    _isActive = true;
    _countdownSeconds = _intervalSeconds;
    WakelockPlus.enable();
    _pulseController.repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds <= 0) {
          _performJiggle();
          _countdownSeconds = _intervalSeconds;
        }
      });
    });

    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _totalActiveSeconds++);
    });
  }

  void _stopJiggler() {
    _isActive = false;
    _countdownTimer?.cancel();
    _statsTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _performJiggle() {
    // Send subtle 2px move right, then 2px move left after 40ms
    _connService.sendCommand(InputCommand.move(2, 0));
    Future.delayed(const Duration(milliseconds: 40), () {
      _connService.sendCommand(InputCommand.move(-2, 0));
    });
    setState(() => _jigglesCount++);
  }

  String _formatDuration(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mouse Jiggler (Anti-Sleep)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Interval Selector Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text('Jiggle Frequency:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIntervalPill(10),
                        const SizedBox(width: 6),
                        _buildIntervalPill(30),
                        const SizedBox(width: 6),
                        _buildIntervalPill(60),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Animated Glowing Radar Button
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isActive ? _pulseAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isActive ? AppColors.success.withAlpha(25) : AppColors.surfaceElevated,
                      border: Border.all(
                        color: _isActive ? AppColors.success : AppColors.border,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isActive ? AppColors.success.withAlpha(100) : Colors.black.withAlpha(30),
                          blurRadius: _isActive ? 30 : 10,
                          spreadRadius: _isActive ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _toggleJiggler,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isActive ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                              size: 56,
                              color: _isActive ? AppColors.success : AppColors.textPrimary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isActive ? 'ACTIVE' : 'START JIGGLER',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _isActive ? AppColors.success : AppColors.textPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (_isActive) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Next in ${_countdownSeconds}s',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Stats Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('JIGGLES SENT', '$_jigglesCount', Icons.mouse_rounded),
                    Container(width: 1, height: 36, color: AppColors.border),
                    _buildStatItem('ACTIVE TIME', _formatDuration(_totalActiveSeconds), Icons.timer_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Performs unnoticeable 1-pixel micro-movements to keep PC display awake without interrupting your work.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryLight),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildIntervalPill(int seconds) {
    final isSelected = _intervalSeconds == seconds;
    return InkWell(
      onTap: () {
        HapticHelper.selectionClick();
        setState(() {
          _intervalSeconds = seconds;
          if (_isActive) _countdownSeconds = seconds;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
