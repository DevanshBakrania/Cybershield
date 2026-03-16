import 'package:flutter/material.dart';
import '../../services/native_camera_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  final NativeCameraService _native = NativeCameraService();

  List<Map<String, dynamic>> _cameraInfo = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCameraInfo();
  }

  Future<void> _loadCameraInfo() async {

    try {

      final data = await _native.getCameraInfo();

      if (!mounted) return;

      setState(() {
        _cameraInfo = data;
        _loading = false;
      });

    } catch (_) {

      setState(() => _loading = false);

    }
  }

  @override
  Widget build(BuildContext context) {

    const accent = Color(0xFF00E5FF);
    const bg = Color(0xFF00012B);

    if (_loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    if (_cameraInfo.isEmpty) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            "No camera hardware detected",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _cameraInfo.length,
        itemBuilder: (context, index) {

          final cam = _cameraInfo[index];

          return _CameraCard(data: cam);
        },
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {

  final Map<String, dynamic> data;

  const _CameraCard({required this.data});

  @override
  Widget build(BuildContext context) {

    const accent = Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF0A0D3A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "${data['facing']} Camera",
            style: const TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [

              const Icon(
                Icons.camera_alt_rounded,
                size: 60,
                color: accent,
              ),

              const SizedBox(width: 24),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      data['megapixels'] ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),

                    Text(
                      data['apertures'] ?? "",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 6,
            ),
            children: [

              _InfoTile("Resolution", data['resolution']),
              _InfoTile("Focal length", data['focalLengths']),
              _InfoTile("Sensor width", "${data['sensorWidthMm']} mm"),
              _InfoTile("Sensor height", "${data['sensorHeightMm']} mm"),
              _InfoTile("Hardware level", data['hardwareLevel']),
              _InfoTile("RAW capture", data['rawSupport'] ? "Yes" : "No"),
              _InfoTile("Max zoom", "${data['maxZoom']}x"),

            ],
          )
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {

  final String label;
  final dynamic value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value?.toString() ?? "-",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.white,
            ),
          ),

        ],
      ),
    );
  }
}