import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../models/network_model.dart';

class NetworkService {
  Future<NetworkModel> getNetworkStatus() async {
    // connectivity_plus ^6.0.0 returns a List<ConnectivityResult>
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    String type = "No Connection";
    bool secure = false;
    String ip = "Scanning...";

    // 1. Determine Connection Type
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      type = "Mobile Data";
      secure = true;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      type = "WiFi Active";
      secure = true;
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      type = "VPN Secured";
      secure = true;
    } else if (connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty) {
      type = "Offline";
      secure = false;
      ip = "0.0.0.0";
    }

    // 2. Fetch Real Public IP (Only if connected)
    if (type != "Offline") {
      try {
        ip = await _getPublicIp();
      } catch (e) {
        ip = "Unavailable";
      }
    }

    return NetworkModel(ip: ip, type: type, isSecure: secure);
  }

  Future<String> _getPublicIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      }
      return "Unknown";
    } catch (e) {
      return "Error";
    }
  }
}