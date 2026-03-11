import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _targetController = TextEditingController(text: "google.com");
  String _terminalOutput = "CyberShield Advanced Toolkit initialized.\nEnter a target IP or Domain and select a module...\n";
  bool _isRunning = false;

  void _printToTerminal(String text, {bool clear = false}) {
    if (!mounted) return;
    setState(() {
      if (clear) {
        _terminalOutput = text;
      } else {
        _terminalOutput += "\n$text";
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NETWORK & SECURITY TOOLS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _runPing() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    _printToTerminal("Initiating ICMP Ping to ${_targetController.text}...", clear: true);

    try {
      final result = await Process.run('ping', ['-c', '4', _targetController.text]);
      if (result.stdout.toString().isNotEmpty) _printToTerminal(result.stdout.toString());
      if (result.stderr.toString().isNotEmpty) _printToTerminal("ERROR: ${result.stderr}");
    } catch (e) {
      _printToTerminal("Ping Failed: $e");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runDnsLookup() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    _printToTerminal("Querying DNS records for ${_targetController.text}...", clear: true);

    try {
      final addresses = await InternetAddress.lookup(_targetController.text);
      String resultText = "DNS Resolution Successful:\n\n";
      for (var address in addresses) {
        resultText += "Host: ${address.host}\nIP Address: ${address.address}\nType: IPv${address.type == InternetAddressType.IPv4 ? '4' : '6'}\n\n";
      }
      _printToTerminal(resultText);
    } catch (e) {
      _printToTerminal("DNS Lookup Failed: $e");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runPortScan() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    final target = _targetController.text;
    _printToTerminal("Scanning common TCP ports on $target...\n", clear: true);

    final ports = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 3306, 3389, 8080, 8443];
    int openCount = 0;

    for (int port in ports) {
      if (!mounted) break;
      try {
        final socket = await Socket.connect(target, port, timeout: const Duration(milliseconds: 500));
        _printToTerminal("[OPEN] Port $port is accepting connections.");
        socket.destroy();
        openCount++;
      } catch (_) {}
    }
    _printToTerminal("\nScan complete. Found $openCount open ports.");
    setState(() => _isRunning = false);
  }

  Future<void> _runSslInspector() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    final target = _targetController.text;
    _printToTerminal("Pulling SSL/TLS Certificate for $target on Port 443...\n", clear: true);

    try {
      final secureSocket = await SecureSocket.connect(target, 443, timeout: const Duration(seconds: 5));
      final cert = secureSocket.peerCertificate;

      if (cert != null) {
        _printToTerminal("🔒 SECURE CONNECTION ESTABLISHED\n");
        _printToTerminal("ISSUED TO: ${cert.subject}");
        _printToTerminal("ISSUED BY: ${cert.issuer}");
        _printToTerminal("VALID FROM: ${cert.startValidity}");
        _printToTerminal("VALID UNTIL: ${cert.endValidity}");
      } else {
        _printToTerminal("No valid certificate found. Connection might not be secure.");
      }
      secureSocket.destroy();
    } catch (e) {
      _printToTerminal("SSL Inspection Failed: Target might not support HTTPS.\nError: $e");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runWhois() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    final target = _targetController.text;
    _printToTerminal("Querying Global WHOIS Registry for $target...\n", clear: true);

    try {
      final socket = await Socket.connect('whois.iana.org', 43, timeout: const Duration(seconds: 5));
      socket.write('$target\r\n');

      final response = await utf8.decoder.bind(socket).join();
      _printToTerminal(response);
      socket.destroy();
    } catch (e) {
      _printToTerminal("WHOIS Query Failed: $e");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _runLanScanner() async {
    setState(() => _isRunning = true);
    _printToTerminal("Scanning Local Area Network (LAN) interfaces...\n", clear: true);

    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        _printToTerminal("Interface: ${interface.name}");
        for (var addr in interface.addresses) {
          _printToTerminal(" -> ${addr.address} (IPv${addr.type == InternetAddressType.IPv4 ? '4' : '6'})");
        }
      }
      _printToTerminal("\n[Note: Full 0-255 subnet sweeping requires active ARP tables. Showing bound local addresses.]");
    } catch (e) {
      _printToTerminal("LAN Scan Failed: $e");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  // ✨ NEW: HTTP HEADERS INSPECTOR
  Future<void> _runHeaders() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    final target = _targetController.text;
    _printToTerminal("Fetching HTTP Server Headers for $target...\n", clear: true);

    try {
      String url = target.startsWith('http') ? target : 'https://$target';
      final request = await HttpClient().headUrl(Uri.parse(url)).timeout(const Duration(seconds: 5));
      final response = await request.close();

      _printToTerminal("Status Code: ${response.statusCode}");
      response.headers.forEach((name, values) {
        _printToTerminal("$name: ${values.join(', ')}");
      });
    } catch (e) {
      _printToTerminal("Header Fetch Failed. (Make sure domain accepts HTTPS/HTTP connections).");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  // ✨ NEW: GEO-IP LOOKUP
  Future<void> _runGeoIp() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    final target = _targetController.text;
    _printToTerminal("Triangulating Geo-IP data for $target...\n", clear: true);

    try {
      final request = await HttpClient().getUrl(Uri.parse('http://ip-api.com/json/$target'));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);

      if (data['status'] == 'success') {
        _printToTerminal("🎯 TARGET ACQUIRED:");
        _printToTerminal("Country: ${data['country']} (${data['countryCode']})");
        _printToTerminal("City/Region: ${data['city']}, ${data['regionName']}");
        _printToTerminal("ISP / Host: ${data['isp']}");
        _printToTerminal("Coordinates: ${data['lat']}, ${data['lon']}");
        _printToTerminal("Resolved IP: ${data['query']}");
      } else {
        _printToTerminal("Geo-IP lookup failed: ${data['message']}");
      }
    } catch (e) {
      _printToTerminal("Geo-IP Error: $e");
    } finally {
      setState(() => _isRunning = false);
    }
  }

  // ✨ NEW: TRACEROUTE (Linux Ping TTL simulation)
  Future<void> _runTraceroute() async {
    if (_targetController.text.isEmpty) return;
    setState(() => _isRunning = true);
    final target = _targetController.text;
    _printToTerminal("Tracing route to $target (Max 15 hops)...\n", clear: true);

    for (int ttl = 1; ttl <= 15; ttl++) {
      if (!mounted) break;
      try {
        final result = await Process.run('ping', ['-c', '1', '-t', ttl.toString(), '-w', '1', target]);
        String out = result.stdout.toString() + result.stderr.toString();

        if (out.contains("Time to live exceeded") || out.contains("Time to live exc")) {
          RegExp regExp = RegExp(r"From\s+([\d\.]+)");
          var match = regExp.firstMatch(out);
          String hopIp = match != null ? match.group(1)! : "Hidden Router";
          _printToTerminal("Hop $ttl: $hopIp");
        } else if (out.contains("bytes from") || out.contains("ttl=")) {
          _printToTerminal("Hop $ttl: Reached Target ($target)");
          break; // Stop when target is reached
        } else {
          _printToTerminal("Hop $ttl: * * * (Request timed out)");
        }
      } catch (e) {
        _printToTerminal("Hop $ttl: Error");
      }
    }
    _printToTerminal("\nTrace complete.");
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("System Tools", style: TextStyle(color: CyberTheme.primaryAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CyberTheme.primaryAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Input Field
            Container(
              decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _targetController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "Enter IP or Domain (e.g., google.com)", hintStyle: TextStyle(color: Colors.white38), prefixIcon: Icon(Icons.language, color: CyberTheme.primaryAccent), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 16),

            // Network Action Buttons (Grid)
            const Text("Network Terminal", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildToolBtn("Ping", Icons.sync_alt, _isRunning ? null : _runPing)),
                const SizedBox(width: 8),
                Expanded(child: _buildToolBtn("DNS", Icons.dns, _isRunning ? null : _runDnsLookup)),
                const SizedBox(width: 8),
                Expanded(child: _buildToolBtn("Ports", Icons.radar, _isRunning ? null : _runPortScan)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildToolBtn("SSL/TLS", Icons.lock_outline, _isRunning ? null : _runSslInspector)),
                const SizedBox(width: 8),
                Expanded(child: _buildToolBtn("WHOIS", Icons.travel_explore, _isRunning ? null : _runWhois)),
                const SizedBox(width: 8),
                Expanded(child: _buildToolBtn("LAN", Icons.wifi_tethering, _isRunning ? null : _runLanScanner)),
              ],
            ),
            const SizedBox(height: 8),
            // ✨ NEW 3rd Row!
            Row(
              children: [
                Expanded(child: _buildToolBtn("Trace", Icons.route, _isRunning ? null : _runTraceroute)),
                const SizedBox(width: 8),
                Expanded(child: _buildToolBtn("Geo-IP", Icons.location_on, _isRunning ? null : _runGeoIp)),
                const SizedBox(width: 8),
                Expanded(child: _buildToolBtn("Headers", Icons.data_object, _isRunning ? null : _runHeaders)),
              ],
            ),
            const SizedBox(height: 16),

            // The Cyber Terminal Output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: CyberTheme.primaryAccent.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: CyberTheme.primaryAccent.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)]),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _isRunning && _terminalOutput.contains("initialized")
                      ? const Center(child: CircularProgressIndicator(color: CyberTheme.primaryAccent))
                      : Text(_terminalOutput, style: const TextStyle(color: CyberTheme.primaryAccent, fontFamily: 'monospace', fontSize: 13, height: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBtn(String label, IconData icon, VoidCallback? onTap, {Color color = CyberTheme.primaryAccent}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: onTap == null ? Colors.white10 : color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: onTap == null ? Colors.transparent : color.withValues(alpha: 0.5))),
        child: Column(
          children: [
            Icon(icon, color: onTap == null ? Colors.white38 : color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: onTap == null ? Colors.white38 : color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}