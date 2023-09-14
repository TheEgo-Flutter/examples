import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_ffmpeg/lib.dart';

const int _DURATION = 1;
const int _TOTAL_FRAME = _DURATION * 60;
const double _RATIO = 3.0;
const String _FILE_NAME = 'capture_';
const double _SIZE = 200.0;
const String _SCALE = '${_SIZE * _RATIO}:${_SIZE * _RATIO}';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CaptureWidget(),
    );
  }
}

class CaptureWidget extends StatefulWidget {
  const CaptureWidget({super.key});

  @override
  State<CaptureWidget> createState() => _CaptureWidgetState();
}

class _CaptureWidgetState extends State<CaptureWidget> with SingleTickerProviderStateMixin {
  List<String> _capturedImages = [];
  final GlobalKey _globalKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Renderer _renderer;
  @override
  void initState() {
    super.initState();

    _renderer = Renderer(containerKey: GlobalKey());

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RepaintBoundary(
              key: _globalKey,
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: _colorAnimation.value,
                    child: const Center(child: Text('애니메이션')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _captureAnimation,
              child: const Text('캡쳐하기'),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                ),
                itemCount: _capturedImages.length,
                itemBuilder: (context, index) {
                  return Image.file(File(_capturedImages[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAnimation() async {
    _capturedImages = [];
    final directory = await getTemporaryDirectory();

    Duration delay = const Duration(seconds: _DURATION) ~/ _TOTAL_FRAME;
    for (int i = 0; i < _TOTAL_FRAME; i++) {
      _animationController.value = i / (_TOTAL_FRAME - 1);

      Uint8List? byte = await _renderer.capture(pixelRatio: _RATIO, delay: delay);

      if (byte == null) continue;
      final imagePath = '${directory.path}/$_FILE_NAME${(i + 1).toString()}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte);
      _capturedImages.add(imagePath); // 경로를 리스트에 추가
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }
}
