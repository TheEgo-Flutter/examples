import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_ffmpeg/lib.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: EncoderPage(),
    );
  }
}

class EncoderPage extends StatefulWidget {
  const EncoderPage({super.key});

  @override
  State<EncoderPage> createState() => _EncoderPageState();
}

class _EncoderPageState extends State<EncoderPage> with SingleTickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  late final Renderer _renderer;
  late final VideoEncoder _videoEncoder;

  VideoPlayerController? _videoPlayerController;
  String _videoPath = '';

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _renderer = Renderer(containerKey: _containerKey);
    _videoEncoder = VideoEncoder(fileName: FILE_NAME, totalFrame: TOTAL_FRAME, duration: DURATION, scale: SCALE);
    _animationController = AnimationController(
      duration: const Duration(seconds: DURATION),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
    _videoPlayerController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onDoubleTap: _captureAnimation,
                child: RepaintBoundary(
                  key: _containerKey,
                  child: AnimatedBuilder(
                    animation: _colorAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: SIZE,
                        height: SIZE,
                        child: Stack(
                          children: [
                            Container(
                              width: SIZE,
                              height: SIZE,
                              color: _colorAnimation.value,
                            ),
                            const Center(child: Text('애니메이션'))
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_videoPath.isNotEmpty)
                    ElevatedButton(
                      child: const Text("Save"),
                      onPressed: () async {
                        final result = await ImageGallerySaver.saveFile(_videoPath);
                        if (result['isSuccess']) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 완료! ✅')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 실패! ❌')));
                        }
                      },
                    ),
                  ElevatedButton(
                    child: const Text('to Video'),
                    onPressed: () async {
                      File? video = await _videoEncoder.fileToVideo(capturedImages);
                      _videoPath = video?.path ?? '';
                      if (!(await File(_videoPath).exists())) {
                        developer.log("파일이 존재하지 않습니다.");
                        return;
                      }
                      _videoPlayerController = VideoPlayerController.file(File(_videoPath))
                        ..initialize().then((_) {
                          setState(() {
                            _videoPlayerController?.play();
                          });
                        }, onError: (error) {
                          developer.log("Error initializing video player: $error");
                        });
                    },
                  ),
                ],
              ),
              Container(
                child: _videoPlayerController?.value.isInitialized ?? false
                    ? GestureDetector(
                        onDoubleTap: () => _videoPlayerController?.play(),
                        child: SizedBox(
                          height: 200,
                          width: 200,
                          child: AspectRatio(
                            aspectRatio: _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5.0,
                    mainAxisSpacing: 5.0,
                  ),
                  itemCount: capturedImages.length,
                  itemBuilder: (context, index) {
                    String item = capturedImages[index];
                    return Stack(
                      children: [
                        Image.file(File(item)),
                        Text(
                          item.split('/').last.split('.').first,
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> capturedImages = [];
  void _captureAnimation() async {
    capturedImages = [];
    final directory = await getTemporaryDirectory();

    Duration duration = const Duration(seconds: DURATION) ~/ TOTAL_FRAME;
    for (int i = 0; i < TOTAL_FRAME; i++) {
      _animationController.value = i / (TOTAL_FRAME - 1);

      Uint8List? byte = await _renderer.capture(pixelRatio: RATIO, delay: duration);

      if (byte == null) continue;
      final imagePath = '${directory.path}/$FILE_NAME${(i + 1).toString()}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte);
      capturedImages.add(imagePath); // 경로를 리스트에 추가
    }

    setState(() {});
  }
}
