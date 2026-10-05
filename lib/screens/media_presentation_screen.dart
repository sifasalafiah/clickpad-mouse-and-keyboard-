import 'dart:async';
import 'package:flutter/material.dart';
import '../models/input_command.dart';
import '../services/connection_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';

class MediaPresentationScreen extends StatefulWidget {
  const MediaPresentationScreen({super.key});

  @override
  State<MediaPresentationScreen> createState() => _MediaPresentationScreenState();
}

class _MediaPresentationScreenState extends State<MediaPresentationScreen> {
  final ConnectionService _connService = ConnectionService.instance;
  int _activeTab = 0; // 0: Media, 1: Presentation

  // Presentation Timer State
  Timer? _presentationTimer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;

  void _toggleTimer() {
    HapticHelper.selectionClick();
    if (_isTimerRunning) {
      _presentationTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _presentationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _secondsElapsed++);
      });
    }
  }

  void _resetTimer() {
    HapticHelper.selectionClick();
    _presentationTimer?.cancel();
    setState(() {
      _secondsElapsed = 0;
      _isTimerRunning = false;
    });
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _presentationTimer?.cancel();
    super.dispose();
  }

  void _sendMediaAction(String action) {
    HapticHelper.mediumImpact();
    _connService.sendCommand(InputCommand.media(action));
  }

  void _sendKey(String key) {
    HapticHelper.mediumImpact();
    _connService.sendCommand(InputCommand.keyPress(key));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mode Switcher Header
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticHelper.selectionClick();
                      setState(() => _activeTab = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note, size: 18, color: _activeTab == 0 ? Colors.white : AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Media Control',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _activeTab == 0 ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticHelper.selectionClick();
                      setState(() => _activeTab = 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.slideshow, size: 18, color: _activeTab == 1 ? Colors.white : AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Presentation',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _activeTab == 1 ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Tab Body
          Expanded(
            child: _activeTab == 0 ? _buildMediaTab() : _buildPresentationTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Album Art Placeholder Graphic
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(100),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.music_note, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 32),

        // Play / Pause / Next / Prev Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircularMediaButton(Icons.skip_previous, () => _sendMediaAction('prev'), size: 56),
            _buildCircularMediaButton(Icons.play_arrow, () => _sendMediaAction('play_pause'), size: 76, isPrimary: true),
            _buildCircularMediaButton(Icons.skip_next, () => _sendMediaAction('next'), size: 56),
          ],
        ),
        const SizedBox(height: 32),

        // Volume Controls Bar
        Card(
          color: AppColors.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () => _sendMediaAction('vol_down'),
                  icon: const Icon(Icons.volume_down, color: AppColors.textPrimary, size: 28),
                ),
                IconButton(
                  onPressed: () => _sendMediaAction('mute'),
                  icon: const Icon(Icons.volume_off, color: AppColors.warning, size: 28),
                ),
                IconButton(
                  onPressed: () => _sendMediaAction('vol_up'),
                  icon: const Icon(Icons.volume_up, color: AppColors.textPrimary, size: 28),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresentationTab() {
    return Column(
      children: [
        // Timer Box
        Card(
          color: AppColors.surfaceElevated,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _formattedTime,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleTimer,
                      icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, color: AppColors.success),
                    ),
                    IconButton(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Slide Navigation Buttons
        Expanded(
          child: Column(
            children: [
              // Next Slide (Big Top Button)
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _sendKey('Right'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_ios, size: 48),
                        SizedBox(height: 8),
                        Text('NEXT SLIDE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Previous Slide (Big Bottom Button)
              Expanded(
                flex: 2,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _sendKey('Left'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios, size: 28),
                        SizedBox(width: 12),
                        Text('PREVIOUS SLIDE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Presentation Actions Bar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _sendKey('F5'),
                icon: const Icon(Icons.play_circle_fill, size: 18),
                label: const Text('Start (F5)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _sendKey('b'),
                icon: const Icon(Icons.crop_portrait, size: 18),
                label: const Text('Blank (B)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _sendKey('Esc'),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Exit (Esc)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withAlpha(40),
                  foregroundColor: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularMediaButton(IconData icon, VoidCallback onTap, {double size = 56, bool isPrimary = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary ? AppColors.primary : AppColors.surfaceElevated,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(120),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
