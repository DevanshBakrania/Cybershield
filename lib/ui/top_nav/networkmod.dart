import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:async';
import 'dart:io';
import '../../widgets/info_tile.dart';
import '../../services/native_network_service.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  final NativeNetworkService _native = NativeNetworkService();
  Timer? _pollTimer;

  Map<String, dynamic>? _wifiSupport;
  Map<String, dynamic>? _wifiNative;
  Map<String, dynamic>? _mobile;

  String? _wifiName;
  String? _wifiIp;
  String? _wifiGateway;
  String? _wifiSubmask;
  String? _wifiBroadcast;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = result;
      });
    });

    unawaited(_ensureNetworkPermissions());
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_refreshAll()));
    unawaited(_refreshAll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() {
      _connectionStatus = result;
    });
  }

  Future<void> _ensureNetworkPermissions() async {
    if (!Platform.isAndroid) return;

    // Best-effort: without these, SSID/cell identity/signal can be blank.
    await Permission.location.request();
    await Permission.phone.request();

    // Android 13+ Wi‑Fi details may require Nearby Wi‑Fi Devices.
    try {
      await Permission.nearbyWifiDevices.request();
    } catch (_) {
      // Ignore on older OS / unsupported platforms.
    }
  }

  bool get _isWifi => _connectionStatus.contains(ConnectivityResult.wifi);
  bool get _isMobile =>
      _connectionStatus.contains(ConnectivityResult.mobile) ||
      _connectionStatus.contains(ConnectivityResult.ethernet) == false && _connectionStatus.contains(ConnectivityResult.vpn) == false
          ? _connectionStatus.contains(ConnectivityResult.mobile)
          : _connectionStatus.contains(ConnectivityResult.mobile);

  Future<void> _refreshAll() async {
    final wifiSupport = await _native.getWifiHardwareSupport();
    final wifiNative = await _native.getWifiNativeInfo();
    final mobile = await _native.getMobileInfo();

    String? wifiName;
    String? wifiIp;
    String? wifiGateway;
    String? wifiSubmask;
    String? wifiBroadcast;

    try {
      wifiName = await _networkInfo.getWifiName();
      wifiIp = await _networkInfo.getWifiIP();
      wifiGateway = await _networkInfo.getWifiGatewayIP();
      wifiSubmask = await _networkInfo.getWifiSubmask();
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } catch (_) {
      // Ignore plugin errors; UI will show "Unavailable".
    }

    if (!mounted) return;
    setState(() {
      _wifiSupport = wifiSupport;
      _wifiNative = wifiNative;
      _mobile = mobile;
      _wifiName = wifiName;
      _wifiIp = wifiIp;
      _wifiGateway = wifiGateway;
      _wifiSubmask = wifiSubmask;
      _wifiBroadcast = wifiBroadcast;
    });
  }

  Future<void> _openWifiSettings() async {
    if (Platform.isAndroid) {
      try {
        await const AndroidIntent(
          action: 'android.settings.WIFI_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return;
      } catch (_) {
        // fall through
      }
    }
    await _openGeneralSettingsFallback();
  }

  Future<void> _openMobileSettings() async {
    if (Platform.isAndroid) {
      try {
        await const AndroidIntent(
          action: 'android.settings.DATA_ROAMING_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return;
      } catch (_) {
        // fall through
      }
      try {
        await const AndroidIntent(
          action: 'android.settings.WIRELESS_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return;
      } catch (_) {
        // fall through
      }
    }
    await _openGeneralSettingsFallback();
  }

  Future<void> _openGeneralSettingsFallback() async {
    if (Platform.isAndroid) {
      try {
        await const AndroidIntent(
          action: 'android.settings.SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ).launch();
        return;
      } catch (_) {
        // ignore
      }
    }
  }

  int? _mobileSignalDbm() => (_mobile?['signalDbm'] as int?);
  int? _mobileSignalLevel() => (_mobile?['signalLevel'] as int?);
  String _mobileOperator() => ((_mobile?['operatorName'] as String?)?.trim().isNotEmpty ?? false) ? (_mobile!['operatorName'] as String) : 'Mobile';

  int _signalPercentFromLevel(int? level) {
    if (level == null) return 0;
    final clamped = level.clamp(0, 4);
    return ((clamped / 4.0) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final surface = const Color(0xFF0A0D3A);
    final neon = const Color(0xFF00E5FF);

    final mobileDbm = _mobileSignalDbm();
    final mobileLevel = _mobileSignalLevel();
    final mobilePercent = _signalPercentFromLevel(mobileLevel);

    final wifiDisconnected = !_isWifi;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _NetworkCard(
          title: 'Connection',
          accent: neon,
          surface: surface,
          onSettingsTap: _openMobileSettings,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detailed mobile info is shown in the Mobile card below.')),
            );
          },
          child: Row(
            children: [
              _SignalBars(
                level: mobileLevel ?? 0,
                activeColor: neon,
                inactiveColor: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _mobileOperator(),
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mobileDbm != null ? '$mobilePercent%   $mobileDbm dBm' : (mobileLevel != null ? '$mobilePercent%' : 'Unavailable'),
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NetworkCard(
          title: 'Wi‑Fi',
          accent: neon,
          surface: surface,
          onSettingsTap: _openWifiSettings,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wi‑Fi details are shown on this screen.')),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Status',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    wifiDisconnected ? 'Disconnected' : 'Connected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Hardware',
                style: TextStyle(color: neon.withOpacity(0.9), fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _SupportRow(label: '802.11', ok: (_wifiSupport?['supportsWifi'] as bool?) ?? true),
              _SupportRow(label: 'Wi‑Fi Direct support', ok: (_wifiSupport?['supportsWifiDirect'] as bool?) ?? false),
              _SupportRow(label: 'Wi‑Fi Aware support', ok: (_wifiSupport?['supportsWifiAware'] as bool?) ?? false),
              _SupportRow(label: 'Wi‑Fi Passpoint support', ok: (_wifiSupport?['supportsWifiPasspoint'] as bool?) ?? false),
              _SupportRow(label: '5GHz band support', ok: (_wifiSupport?['supports5Ghz'] as bool?) ?? false),
              _SupportRow(label: '6GHz band support', ok: (_wifiSupport?['supports6Ghz'] as bool?) ?? false),
              const SizedBox(height: 12),
              if (!wifiDisconnected) ...[
                const InfoHeader(title: 'Wi‑Fi Details'),
                InfoTile(label: 'SSID', value: _wifiName ?? 'Unavailable'),
                InfoTile(label: 'IP', value: _wifiIp ?? 'Unavailable'),
                InfoTile(label: 'Gateway', value: _wifiGateway ?? 'Unavailable'),
                InfoTile(label: 'Subnet mask', value: _wifiSubmask ?? 'Unavailable'),
                InfoTile(label: 'Broadcast', value: _wifiBroadcast ?? 'Unavailable'),
                InfoTile(
                  label: 'Link speed',
                  value: (_wifiNative?['linkSpeedMbps'] != null) ? '${_wifiNative!['linkSpeedMbps']} Mbps' : 'Unavailable',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NetworkCard(
          title: 'Mobile',
          accent: neon,
          surface: surface,
          onSettingsTap: _openMobileSettings,
          onTap: () {},
          child: _MobileDetailsBody(mobile: _mobile),
        ),
      ],
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final String title;
  final Color accent;
  final Color surface;
  final VoidCallback onSettingsTap;
  final VoidCallback onTap;
  final Widget child;

  const _NetworkCard({
    required this.title,
    required this.accent,
    required this.surface,
    required this.onSettingsTap,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: onSettingsTap,
                    tooltip: 'Open system settings',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int level; // 0..4
  final Color activeColor;
  final Color inactiveColor;

  const _SignalBars({
    required this.level,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = level.clamp(0, 4);
    const bars = 5;
    final heights = const [8.0, 12.0, 16.0, 20.0, 24.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars, (i) {
        final active = i <= clamped;
        return Container(
          width: 10,
          height: heights[i],
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _SupportRow extends StatelessWidget {
  final String label;
  final bool ok;

  const _SupportRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final icon = ok ? Icons.check_circle : Icons.cancel;
    final color = ok ? const Color(0xFF00E5FF) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDetailsBody extends StatefulWidget {
  final Map<String, dynamic>? mobile;
  const _MobileDetailsBody({required this.mobile});

  @override
  State<_MobileDetailsBody> createState() => _MobileDetailsBodyState();
}

class _MobileDetailsBodyState extends State<_MobileDetailsBody> {
  bool _showCellId = false;
  bool _showTac = false;

  @override
  Widget build(BuildContext context) {
    final mobile = widget.mobile ?? const <String, dynamic>{};

    String v(String key, {String fallback = 'Unavailable'}) {
      final val = mobile[key];
      if (val == null) return fallback;
      if (val is String && val.trim().isEmpty) return fallback;
      return val.toString();
    }

    final dns = (mobile['dnsServers'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final dns1 = dns.isNotEmpty ? dns.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoHeader(title: 'Mobile'),
        InfoTile(
          label: 'Dual SIM',
          value: (mobile['dualSim'] == null) ? 'Unavailable' : ((mobile['dualSim'] as bool) ? 'Yes' : 'No'),
        ),
        InfoTile(label: 'Phone type', value: v('phoneType')),
        InfoTile(
          label: 'eSIM',
          value: (mobile['esimSupported'] == true) ? 'Yes' : 'No',
        ),
        const SizedBox(height: 10),
        const InfoHeader(title: 'Connection'),
        InfoTile(label: 'Status', value: v('connectionStatus', fallback: 'Disconnected')),
        InfoTile(label: 'APN', value: 'Unavailable'),
        InfoTile(
          label: 'Signal strength',
          value: [
            if (mobile['signalDbm'] != null) '${mobile['signalDbm']} dBm',
            if (mobile['signalAsu'] != null) '${mobile['signalAsu']} asu',
          ].isEmpty
              ? 'Unavailable'
              : [
                  if (mobile['signalDbm'] != null) '${mobile['signalDbm']} dBm',
                  if (mobile['signalAsu'] != null) '${mobile['signalAsu']} asu',
                ].join('  '),
        ),
        InfoTile(
          label: 'Link speed',
          value: mobile['downstreamKbps'] != null ? '${(mobile['downstreamKbps'] as int) / 1000.0} Mbps' : 'Unavailable',
        ),
        _RevealTile(
          label: 'Cell Identifier',
          shown: _showCellId,
          value: v('cellId'),
          onToggle: () => setState(() => _showCellId = !_showCellId),
        ),
        _RevealTile(
          label: 'Tracking area code',
          shown: _showTac,
          value: v('trackingAreaCode'),
          onToggle: () => setState(() => _showTac = !_showTac),
        ),
        InfoTile(label: 'Interface', value: v('interfaceName')),
        InfoTile(label: 'DNS1', value: dns1 ?? 'Unavailable'),
      ],
    );
  }
}

class _RevealTile extends StatelessWidget {
  final String label;
  final bool shown;
  final String value;
  final VoidCallback onToggle;

  const _RevealTile({
    required this.label,
    required this.shown,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: TextButton(
          onPressed: onToggle,
          child: Text(
            shown ? value : 'SHOW',
            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
