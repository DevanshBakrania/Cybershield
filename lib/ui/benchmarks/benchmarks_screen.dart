import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BenchmarksScreen extends StatefulWidget {
  const BenchmarksScreen({super.key});

  @override
  State<BenchmarksScreen> createState() => _BenchmarksScreenState();
}

class _BenchmarksScreenState extends State<BenchmarksScreen> {
  bool _isRunning = false;
  bool _isFinished = false;
  double _progress = 0.0;
  String _currentTask = "Ready to test device performance?";
  int _score = 0;

  void _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _isFinished = false;
      _progress = 0.1;
      _currentTask = "Running CPU Integer Test (Prime Crunching)...";
    });

    final stopwatch = Stopwatch()..start();

    await compute(_cpuIntegerTask, 250000);
    if (!mounted) return;
    setState(() {
      _progress = 0.4;
      _currentTask = "Running CPU Float Test (Trigonometry)...";
    });

    await compute(_cpuFloatTask, 10000000);
    if (!mounted) return;
    setState(() {
      _progress = 0.7;
      _currentTask = "Running Memory I/O Test (Allocation)...";
    });

    await compute(_memoryTask, 15000000);
    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _currentTask = "Finalizing Score...";
    });

    stopwatch.stop();
    int timeTakenMs = stopwatch.elapsedMilliseconds;
    int finalScore = (100000000 / (timeTakenMs > 0 ? timeTakenMs : 1)).round();

    if (mounted) {
      setState(() {
        _isRunning = false;
        _isFinished = true;
        _score = finalScore;
        _currentTask = "Test completed in ${timeTakenMs / 1000} seconds";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("Benchmarks", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, size: 80, color: _isFinished ? CyberTheme.primaryAccent : Colors.white24),
              const SizedBox(height: 30),

              Text(_currentTask, textAlign: TextAlign.center, style: TextStyle(color: _isRunning ? CyberTheme.primaryAccent : Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),

              if (_isRunning) ...[
                LinearProgressIndicator(value: _progress, color: CyberTheme.primaryAccent, backgroundColor: Colors.white10, minHeight: 8),
                const SizedBox(height: 10),
                Text("${(_progress * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
              ],

              if (_isFinished) ...[
                const Text("CYBERSHIELD SCORE", style: TextStyle(color: Colors.grey, letterSpacing: 1.5)),
                Text("$_score", style: const TextStyle(color: CyberTheme.primaryAccent, fontSize: 60, fontWeight: FontWeight.bold)),
              ],

              const SizedBox(height: 50),

              if (!_isRunning)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.primaryAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _runBenchmark,
                    child: Text(_isFinished ? "RUN AGAIN" : "START BENCHMARK", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

int _cpuIntegerTask(int limit) {
  int primes = 0;
  for (int i = 2; i < limit; i++) {
    bool isPrime = true;
    for (int j = 2; j * j <= i; j++) {
      if (i % j == 0) {
        isPrime = false;
        break;
      }
    }
    if (isPrime) primes++;
  }
  return primes;
}

double _cpuFloatTask(int limit) {
  double result = 0.0;
  for (int i = 1; i < limit; i++) {
    result += sin(i) * cos(i) + sqrt(i);
  }
  return result;
}

int _memoryTask(int size) {
  List<int> list = List.generate(size, (index) => index * 2);
  int sum = 0;
  for (int i = 0; i < list.length; i += 100) {
    sum += list[i];
  }
  return sum;
}