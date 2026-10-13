import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/connection_type.dart';
import '../models/device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/connection_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../utils/haptic_helper.dart';
import '../widgets/pro_purchase_modal.dart';

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({super.key});

  @override
  State<BluetoothPairingScreen> createState() => _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen>
    with SingleTickerProviderStateMixin {
  final ConnectionService _connService = ConnectionService.instance;
  final BluetoothBleService _bleService = BluetoothBleService.instance;
  final SettingsService _settings = SettingsService.instance;
  final IapService _iapService = IapService.instance;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 2-Way Connection Mode:
  // 0: "Auto-Scan PC" (ClickPad finds PC)
  // 1: "Broadcast Mode" (PC finds ClickPad)
  int _connectionModeIndex = 0;

  // Discovered and Paired Devices
  final Map<String, DiscoveredDevice> _pairedDevices = {};
  final Map<String, DiscoveredDevice> _discoveredDevices = {};

  bool _isAutoScanning = false;
  String? _connectingDeviceId;
  String _bluetoothDeviceName = 'ClickPad';
  bool _isDiscoverabilityDenied = false;
  bool _isRequestingDiscoverability = false;
  int _selectedPlatformTab =
      0; // 0: macOS, 1: Windows, 2: Linux, 3: iPad/Tablet
  Timer? _pruneTimer;

  @override
  void initState() {
    super.initState();

    _connService.addListener(_onConnectionChanged);
    _iapService.addListener(_onConnectionChanged);

    // Radar pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Periodically remove stale/expired nearby devices (Filter 3: Auto-Expire)
    _pruneTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pruneExpiredDevices();
    });

    // Hook real-time device discovery listener
    _bleService.onDeviceDiscovered = _handleDeviceDiscovered;

    // Load initial device name and bonded devices, then start auto-scan
    _initTwoWayPairing();
  }

  void _pruneExpiredDevices() {
    if (!mounted || _discoveredDevices.isEmpty) return;
    final now = DateTime.now();
    bool changed = false;

    // Remove devices not seen in the last 15 seconds
    _discoveredDevices.removeWhere((id, dev) {
      if (id == _connectingDeviceId) return false;
      final ageSeconds = now.difference(dev.lastSeen).inSeconds;
      if (ageSeconds > 15) {
        changed = true;
        return true;
      }
      return false;
    });

    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _initTwoWayPairing() async {
    await _loadBtDeviceName();
    await _loadBondedDevices();
    _requestDiscoverability();
    _startAutoScan();
  }

  void _handleDeviceDiscovered(DiscoveredDevice device) {
    if (!mounted) return;
    if (device.name.trim().isEmpty) return;

    // Filter 1: Ignore very weak / distant signals (< -80 dBm)
    if (device.rssi != 0 && device.rssi < -80) return;

    // Check if this device is already in paired list
    if (_pairedDevices.containsKey(device.id)) {
      _pairedDevices[device.id] = device;
    } else {
      _discoveredDevices[device.id] = device;
    }
    setState(() {});
  }

  Future<void> _loadBtDeviceName() async {
    final name = await _bleService.getBluetoothDeviceName();
    if (mounted && name.isNotEmpty) {
      setState(() => _bluetoothDeviceName = name);
    }
  }

  Future<void> _loadBondedDevices() async {
    final bonded = await _connService.getBondedDevices();
    if (!mounted) return;
    for (var d in bonded) {
      if (d.name.trim().isNotEmpty) {
        _pairedDevices[d.id] = d;
      }
    }
    setState(() {});
  }

  Future<void> _startAutoScan() async {
    if (_isAutoScanning) return;
    setState(() => _isAutoScanning = true);

    try {
      await _connService.startDiscovery();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isAutoScanning = false);
      }
    }
  }

  Future<void> _requestDiscoverability() async {
    if (_isRequestingDiscoverability) return;
    if (mounted) setState(() => _isRequestingDiscoverability = true);

    final granted = await _bleService.makeDiscoverable();
    await _loadBtDeviceName();

    if (mounted) {
      setState(() {
        _isDiscoverabilityDenied = !granted;
        _isRequestingDiscoverability = false;
      });
    }
  }

  Future<void> _connectTo(DiscoveredDevice device) async {
    HapticHelper.mediumImpact();
    setState(() => _connectingDeviceId = device.id);

    try {
      await _connService.connect(device);
    } catch (_) {}

    // Auto timeout release if still on this screen
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _connectingDeviceId == device.id) {
        setState(() => _connectingDeviceId = null);
      }
    });
  }

  @override
  void dispose() {
    _pruneTimer?.cancel();
    _bleService.onDeviceDiscovered = null;
    _connService.removeListener(_onConnectionChanged);
    _iapService.removeListener(_onConnectionChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onConnectionChanged() {
    if (mounted) {
      if (_connService.isConnected) {
        _connectingDeviceId = null;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _connService.status;
    final isConnecting =
        status == ConnectionStateStatus.connecting ||
        status == ConnectionStateStatus.pairing ||
        _connectingDeviceId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Sleek Header Bar
            _buildHeader(context),

            // 2. Mode Selector (Segmented Tab: Auto-Scan PC vs Broadcast Mode)
            _buildModeSwitcher(),

            // 3. Main Interactive 2-Way View
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _connectionModeIndex == 0
                    ? _buildAutoScanView(isConnecting)
                    : _buildBroadcastView(isConnecting),
              ),
            ),

            // 4. Floating Connecting Status Bottom Bar (if connecting)
            if (isConnecting) _buildConnectingFloatingBanner(),
          ],
        ),
      ),
    );
  }

  // --- HEADER BAR ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withAlpha(50), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ClickPad',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'PC Mouse, Keyboard & Joystick',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pro Crown Button
              if (!_iapService.isPro)
                IconButton(
                  onPressed: () {
                    HapticHelper.mediumImpact();
                    ProPurchaseModal.show(context);
                  },
                  icon: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700),
                    size: 22,
                  ),
                  tooltip: 'Unlock PRO',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),

              // Open System Bluetooth Settings Shortcut
              OutlinedButton.icon(
                onPressed: () {
                  HapticHelper.selectionClick();
                  _bleService.openSystemBluetoothSettings();
                },
                icon: const Icon(Icons.settings_bluetooth_rounded, size: 15),
                label: const Text(
                  'BT Settings',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border, width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2-WAY MODE SELECTOR TABS ---
  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              index: 0,
              title: 'Auto-Scan PC',
              subtitle: 'ClickPad finds PC',
              icon: Icons.radar_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTab(
              index: 1,
              title: 'Broadcast Mode',
              subtitle: 'PC finds ClickPad',
              icon: Icons.cell_tower_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _connectionModeIndex == index;
    return InkWell(
      onTap: () {
        HapticHelper.selectionClick();
        setState(() {
          _connectionModeIndex = index;
          if (index == 0 && !_isAutoScanning) {
            _startAutoScan();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(100),
                    blurRadius: 8,
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
              size: 18,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isSelected
                          ? Colors.white.withAlpha(210)
                          : AppColors.textMuted,
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
    );
  }

  // =========================================================================
  // VIEW 1: AUTO-SCAN PC (CLICKPAD FINDS COMPUTER)
  // =========================================================================
  Widget _buildAutoScanView(bool isConnecting) {
    final status = _connService.status;
    final hasFailed = status == ConnectionStateStatus.failed;
    final pairedList = _pairedDevices.values.toList();
    final discoveredList = _discoveredDevices.values
        .where((d) => !_pairedDevices.containsKey(d.id))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        HapticHelper.lightImpact();
        await _loadBondedDevices();
        await _startAutoScan();
      },
      child: ListView(
        key: const ValueKey('auto_scan_view'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Connection Failure Banner (if any)
          if (hasFailed) _buildErrorBanner(),

          // Active Scan Status Pill & Rescan Action
          _buildScanStatusCard(),
          const SizedBox(height: 12),

          // Last Connected Device Quick Reconnect Card
          if (_settings.hasLastConnectedDevice && !isConnecting)
            _buildLastConnectedCard(),

          // SECTION 1: PAIRED COMPUTERS
          if (pairedList.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'PAIRED COMPUTERS',
              count: pairedList.length,
              icon: Icons.bookmark_added_rounded,
            ),
            const SizedBox(height: 8),
            ...pairedList.map((dev) => _buildDeviceCard(dev, isPaired: true)),
            const SizedBox(height: 16),
          ],

          // SECTION 2: NEARBY COMPUTERS & DEVICES
          _buildSectionHeader(
            title: 'NEARBY COMPUTERS & DEVICES',
            count: discoveredList.length,
            icon: Icons.bluetooth_searching_rounded,
            trailingWidget: _isAutoScanning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 8),

          if (discoveredList.isEmpty)
            _buildSearchingEmptyState()
          else
            ...discoveredList.map(
              (dev) => _buildDeviceCard(dev, isPaired: false),
            ),

          const SizedBox(height: 20),

          // Helpful 2-Way Tip Footer
          _buildTwoWayHelpCard(),
        ],
      ),
    );
  }

  Widget _buildScanStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Animated Pulse / Spin Dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAutoScanning ? AppColors.primary : AppColors.success,
              boxShadow: [
                BoxShadow(
                  color:
                      (_isAutoScanning ? AppColors.primary : AppColors.success)
                          .withAlpha(120),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isAutoScanning
                  ? 'Searching nearby PCs, Macs & Tablets...'
                  : 'Auto-scan ready. Nearby devices listed below.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _isAutoScanning
                ? null
                : () {
                    HapticHelper.selectionClick();
                    _discoveredDevices.clear();
                    _startAutoScan();
                  },
            icon: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: _isAutoScanning
                  ? AppColors.textMuted
                  : AppColors.primaryLight,
            ),
            label: Text(
              _isAutoScanning ? 'Scanning' : 'Rescan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isAutoScanning
                    ? AppColors.textMuted
                    : AppColors.primaryLight,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    Widget? trailingWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primaryLight),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
        ),
        const Spacer(),
        ?trailingWidget,
      ],
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device, {required bool isPaired}) {
    final isConnectingThis = _connectingDeviceId == device.id;
    final icon = _getDeviceIcon(device.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnectingThis
              ? AppColors.primary
              : (isPaired
                    ? AppColors.primaryLight.withAlpha(90)
                    : AppColors.border),
          width: isConnectingThis ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(AppColors.palette.isLight ? 12 : 60),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Device Icon Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPaired
                  ? AppColors.primary.withAlpha(
                      AppColors.palette.isLight ? 45 : 30,
                    )
                  : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPaired ? AppColors.primaryLight : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: isPaired
                  ? AppColors.primaryLight
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),

          // Device Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPaired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'PAIRED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildSignalBadge(device.rssi),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPaired ? 'Paired device' : 'Ready to connect',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Connect / Pair Action Button
          ElevatedButton(
            onPressed: isConnectingThis ? null : () => _connectTo(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaired ? AppColors.primary : AppColors.surface,
              foregroundColor: isPaired ? Colors.white : AppColors.primaryLight,
              elevation: isPaired ? 2 : 0,
              side: isPaired
                  ? null
                  : BorderSide(color: AppColors.primaryLight, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isConnectingThis
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isPaired ? Colors.white : AppColors.primaryLight,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaired ? Icons.bolt_rounded : Icons.link_rounded,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaired ? 'Connect' : 'Pair',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(25),
                border: Border.all(color: AppColors.primaryLight, width: 1.5),
              ),
              child: Icon(
                Icons.bluetooth_searching_rounded,
                size: 32,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Searching for nearby computers...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Make sure Bluetooth is turned ON and discoverable on your PC or Mac.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLastConnectedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST CONNECTED PC',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _settings.lastDeviceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _connectTo(
              DiscoveredDevice(
                id: _settings.lastDeviceId,
                name: _settings.lastDeviceName,
                type: ConnectionType.bluetoothHid,
              ),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text(
              'Connect',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoWayHelpCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Can\'t find your computer here?',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Switch to "Broadcast Mode" above to search for this phone directly from your computer\'s Bluetooth menu.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 2: BROADCAST MODE (COMPUTER FINDS CLICKPAD)
  // =========================================================================
  Widget _buildBroadcastView(bool isConnecting) {
    return ListView(
      key: const ValueKey('broadcast_view'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Broadcasting Radar Hero Card
        _buildBroadcastHeroCard(),
        const SizedBox(height: 16),

        // OS Platform Step-by-Step Instruction Guide
        _buildInstructionSection(),
      ],
    );
  }

  Widget _buildBroadcastHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(AppColors.palette.isLight ? 15 : 80),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          // Animated Pulsing Beacon Icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(30),
                border: Border.all(color: AppColors.primaryLight, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(70),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.sensors_rounded,
                size: 38,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your Phone is Discoverable',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Search for this exact Bluetooth name on your computer:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Glowing Device Name Capsule with Quick Copy
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _bluetoothDeviceName));
              HapticHelper.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied "$_bluetoothDeviceName" to clipboard!'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryLight, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bluetooth_connected_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _bluetoothDeviceName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          if (_isDiscoverabilityDenied) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isRequestingDiscoverability
                  ? null
                  : () {
                      HapticHelper.mediumImpact();
                      _requestDiscoverability();
                    },
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: Text(
                _isRequestingDiscoverability
                    ? 'Requesting Visibility...'
                    : 'Make Phone Visible for Pairing',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withAlpha(40),
                foregroundColor: AppColors.primaryLight,
                elevation: 0,
                side: BorderSide(color: AppColors.primaryLight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              const Text(
                'How to Connect on Your Computer',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Platform Pill Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPlatformFilterChip(0, 'macOS', Icons.laptop_mac_rounded),
                const SizedBox(width: 8),
                _buildPlatformFilterChip(
                  1,
                  'Windows 10/11',
                  Icons.desktop_windows_rounded,
                ),
                const SizedBox(width: 8),
                _buildPlatformFilterChip(2, 'Linux', Icons.terminal_rounded),
                const SizedBox(width: 8),
                _buildPlatformFilterChip(
                  3,
                  'iPad / Tablet',
                  Icons.tablet_mac_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Numbered Guide Steps
          _buildInstructionContent(_selectedPlatformTab),
        ],
      ),
    );
  }

  Widget _buildPlatformFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedPlatformTab == index;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        HapticHelper.selectionClick();
        setState(() => _selectedPlatformTab = index);
      },
      avatar: Icon(
        icon,
        size: 15,
        color: isSelected ? Colors.white : AppColors.textMuted,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primaryLight : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildInstructionContent(int tabIndex) {
    switch (tabIndex) {
      case 0: // macOS
        return Column(
          children: [
            const _StepRow(
              number: '1',
              title: 'Open macOS Bluetooth Settings',
              desc: 'Click Apple Menu () -> System Settings -> Bluetooth.',
            ),
            _StepRow(
              number: '2',
              title: 'Locate Your Device',
              desc: 'Look under "Nearby Devices" for "$_bluetoothDeviceName".',
            ),
            const _StepRow(
              number: '3',
              title: 'Connect & Authorize',
              desc:
                  'Click Connect and accept pairing prompt. Controls unlock instantly!',
            ),
          ],
        );
      case 1: // Windows
        return Column(
          children: [
            const _StepRow(
              number: '1',
              title: 'Open Windows Settings',
              desc: 'Press Win + I -> Select "Bluetooth & Devices".',
            ),
            const _StepRow(
              number: '2',
              title: 'Add Bluetooth Device',
              desc:
                  'Click "Add Device" -> Choose "Bluetooth (Mice, keyboards, etc.)".',
            ),
            _StepRow(
              number: '3',
              title: 'Pair with ClickPad',
              desc: 'Select "$_bluetoothDeviceName" to pair & connect.',
            ),
          ],
        );
      case 2: // Linux
        return Column(
          children: [
            const _StepRow(
              number: '1',
              title: 'Open Bluetooth Manager',
              desc: 'Open Settings -> Bluetooth or launch Blueman Manager.',
            ),
            _StepRow(
              number: '2',
              title: 'Scan for Devices',
              desc:
                  'Look for "$_bluetoothDeviceName" in the list of nearby devices.',
            ),
            const _StepRow(
              number: '3',
              title: 'Pair & Trust',
              desc: 'Click Pair and Trust device to start remote control.',
            ),
          ],
        );
      case 3: // iPad / Tablet
      default:
        return Column(
          children: [
            const _StepRow(
              number: '1',
              title: 'Open Tablet Bluetooth',
              desc:
                  'Go to Settings -> Bluetooth on your iPad or Android Tablet.',
            ),
            _StepRow(
              number: '2',
              title: 'Find Other Devices',
              desc: 'Look for "$_bluetoothDeviceName" under "Other Devices".',
            ),
            const _StepRow(
              number: '3',
              title: 'Tap to Pair',
              desc: 'Tap to pair. Touchpad cursor will appear immediately.',
            ),
          ],
        );
    }
  }

  // --- CONNECTING FLOATING BOTTOM BANNER ---
  Widget _buildConnectingFloatingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _connService.statusMessage ?? 'Connecting to computer...',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Accept pairing prompt on your computer if asked.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              HapticHelper.selectionClick();
              _connService.disconnect();
              setState(() => _connectingDeviceId = null);
            },
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  _connService.statusMessage ??
                      'Could not establish connection. Please retry.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticHelper.mediumImpact();
              _startAutoScan();
            },
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBadge(int rssi) {
    final label = rssi >= -60 ? 'Strong' : (rssi >= -75 ? 'Good' : 'Fair');
    final color = rssi >= -60
        ? AppColors.success
        : (rssi >= -75 ? AppColors.primaryLight : AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_tethering_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mac') ||
        lower.contains('apple') ||
        lower.contains('imac') ||
        lower.contains('book')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('pc') ||
        lower.contains('desktop') ||
        lower.contains('win') ||
        lower.contains('tower')) {
      return Icons.desktop_windows_rounded;
    }
    if (lower.contains('pad') || lower.contains('tab')) {
      return Icons.tablet_mac_rounded;
    }
    return Icons.devices_rounded;
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _StepRow({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.primary.withAlpha(40),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
