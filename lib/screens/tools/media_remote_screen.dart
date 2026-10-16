import 'package:flutter/material.dart';
import '../../services/bluetooth_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';

class MediaRemoteScreen extends StatefulWidget {
  const MediaRemoteScreen({super.key});

  @override
  State<MediaRemoteScreen> createState() => _MediaRemoteScreenState();
}

class _MediaRemoteScreenState extends State<MediaRemoteScreen> {
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  bool _isPlaying = true;
  bool _isMuted = false;

  void _playPause() {
    HapticHelper.mediumImpact();
    // Consumer Play/Pause (0x08)
    _bleService.sendConsumerKey(0x08);
    setState(() => _isPlaying = !_isPlaying);
  }

  void _volumeUp() {
    HapticHelper.lightImpact();
    // Consumer Volume Up (0x20)
    _bleService.sendConsumerKey(0x20);
  }

  void _volumeDown() {
    HapticHelper.lightImpact();
    // Consumer Volume Down (0x40)
    _bleService.sendConsumerKey(0x40);
  }

  void _muteToggle() {
    HapticHelper.mediumImpact();
    // Consumer Mute (0x10)
    _bleService.sendConsumerKey(0x10);
    setState(() => _isMuted = !_isMuted);
  }

  void _prevTrack() {
    HapticHelper.lightImpact();
    // Consumer Prev Track (0x02)
    _bleService.sendConsumerKey(0x02);
  }

  void _nextTrack() {
    HapticHelper.lightImpact();
    // Consumer Next Track (0x01)
    _bleService.sendConsumerKey(0x01);
  }

  void _seekBack10() {
    HapticHelper.lightImpact();
    // Universal Media Seek Backward: Arrow Left (0x50)
    _bleService.sendKeyboardScancode(0, 0x50);
  }

  void _seekForward10() {
    HapticHelper.lightImpact();
    // Universal Media Seek Forward: Arrow Right (0x4F)
    _bleService.sendKeyboardScancode(0, 0x4F);
  }

  void _fullscreen() {
    HapticHelper.mediumImpact();
    _bleService.sendKeyboardScancode(0, 0x09); // 'F' (Fullscreen)
  }

  void _subtitles() {
    HapticHelper.selectionClick();
    _bleService.sendKeyboardScancode(0, 0x06); // 'C' (Captions)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Media Controller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Central Disc Media Hub
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top: Vol Up
                    Positioned(
                      top: 14,
                      child: IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.volume_up_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Volume Up',
                        onPressed: _volumeUp,
                      ),
                    ),

                    // Bottom: Vol Down
                    Positioned(
                      bottom: 14,
                      child: IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.volume_down_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Volume Down',
                        onPressed: _volumeDown,
                      ),
                    ),

                    // Left: Prev Track
                    Positioned(
                      left: 14,
                      child: IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Previous Track',
                        onPressed: _prevTrack,
                      ),
                    ),

                    // Right: Next Track
                    Positioned(
                      right: 14,
                      child: IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.skip_next_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Next Track',
                        onPressed: _nextTrack,
                      ),
                    ),

                    // Center: Play / Pause Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _playPause,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(120),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Seek -10s / +10s Row
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.replay_10_rounded,
                      label: '-10s Seek',
                      onTap: _seekBack10,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_mute_rounded,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      color: _isMuted ? Colors.amber : null,
                      onTap: _muteToggle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.forward_10_rounded,
                      label: '+10s Seek',
                      onTap: _seekForward10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Additional Player Controls (Fullscreen, Captions, Up/Down arrow)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.fullscreen_rounded,
                      label: 'Fullscreen (F)',
                      onTap: _fullscreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.subtitles_rounded,
                      label: 'Captions (C)',
                      onTap: _subtitles,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color != null ? color.withAlpha(120) : AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color ?? AppColors.primaryLight),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
