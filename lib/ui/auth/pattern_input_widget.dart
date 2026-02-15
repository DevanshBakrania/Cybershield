import 'package:flutter/material.dart';

class PatternInputWidget extends StatefulWidget {
  final void Function(List<int>) onComplete;

  const PatternInputWidget({super.key, required this.onComplete});

  @override
  State<PatternInputWidget> createState() => _PatternInputWidgetState();
}

class _PatternInputWidgetState extends State<PatternInputWidget> {
  final List<int> _pattern = [];

  void _onPanUpdate(Offset localPosition, double size) {
    final cellSize = size / 3;
    final col = (localPosition.dx ~/ cellSize);
    final row = (localPosition.dy ~/ cellSize);

    if (row < 0 || col < 0 || row > 2 || col > 2) return;

    final index = row * 3 + col + 1;
    if (!_pattern.contains(index)) {
      setState(() => _pattern.add(index));
    }
  }

  void _onPanEnd() {
    if (_pattern.length >= 3) {
      widget.onComplete(List.from(_pattern));
    }
    setState(() => _pattern.clear());
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Draw Unlock Pattern",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Center(
          child: GestureDetector(
            onPanUpdate: (d) => _onPanUpdate(d.localPosition, size),
            onPanEnd: (_) => _onPanEnd(),
            child: SizedBox(
              width: size,
              height: size,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (_, i) {
                  final idx = i + 1;
                  return Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pattern.contains(idx)
                          ? Colors.greenAccent
                          : Colors.grey.shade800,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
