import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ This was the cause of the error. It is now at the top.
import '../../core/theme.dart';

// --- 1. DISPLAY TEST (Dead Pixel Check) ---
class DisplayTestScreen extends StatefulWidget {
  const DisplayTestScreen({super.key});

  @override
  State<DisplayTestScreen> createState() => _DisplayTestScreenState();
}

class _DisplayTestScreenState extends State<DisplayTestScreen> {
  int _index = 0;
  // Cycle: Red -> Green -> Blue -> White -> Black
  final List<Color> _colors = [Colors.red, Colors.green, Colors.blue, Colors.white, Colors.black];
  final List<String> _names = ["RED", "GREEN", "BLUE", "WHITE", "BLACK"];

  void _nextColor() {
    setState(() {
      if (_index < _colors.length - 1) {
        _index++;
      } else {
        // Finish Test: Return 'true' (Passed) to the previous screen
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Force full screen, hide bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return Scaffold(
      backgroundColor: _colors[_index],
      body: InkWell(
        onTap: _nextColor,
        child: Center(
          child: Text(
            "TAP SCREEN\n${_names[_index]}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _colors[_index] == Colors.white ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Restore UI bars when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

// --- 2. MULTITOUCH TEST ---
class MultitouchTestScreen extends StatefulWidget {
  const MultitouchTestScreen({super.key});

  @override
  State<MultitouchTestScreen> createState() => _MultitouchTestScreenState();
}

class _MultitouchTestScreenState extends State<MultitouchTestScreen> {
  // Track multiple touch points
  final Map<int, Offset> _touches = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Multitouch Test"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: CyberTheme.neonGreen),
            onPressed: () => Navigator.pop(context, true), // Pass
          )
        ],
      ),
      body: Listener(
        onPointerDown: (e) => setState(() => _touches[e.pointer] = e.position),
        onPointerMove: (e) => setState(() => _touches[e.pointer] = e.position),
        onPointerUp: (e) => setState(() => _touches.remove(e.pointer)),
        onPointerCancel: (e) => setState(() => _touches.remove(e.pointer)),
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: TouchPainter(_touches),
            child: Center(
              child: Text(
                "${_touches.length} Touch Points",
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TouchPainter extends CustomPainter {
  final Map<int, Offset> touches;
  TouchPainter(this.touches);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Different colors for different fingers
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple];

    touches.forEach((id, offset) {
      paint.color = colors[id % colors.length];
      canvas.drawCircle(offset, 40, paint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}