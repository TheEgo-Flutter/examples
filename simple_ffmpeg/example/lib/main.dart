import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:simple_ffmpeg/ffmpeg_controller.dart';
import 'package:simple_ffmpeg/ffmpeg_widget.dart';
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
  late FFMpegController ffMpegController;
  VideoPlayerController? _videoPlayerController;
  String _videoPath = '';
  List<String> capturedImages = [];
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    ffMpegController = FFMpegController();
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
                onDoubleTap: () async {
                  capturedImages =
                      await ffMpegController.captureAnimation(controller: _animationController, framerate: 30);
                },
                child: FFmpegWidget(
                  controller: ffMpegController,
                  child: AnimatedBuilder(
                    animation: _colorAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 300,
                        height: 200,
                        child: Stack(
                          children: [
                            Container(
                              width: 300,
                              height: 200,
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
                      File? video = await ffMpegController.fileToVideo(controller: _animationController, framerate: 30);
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
                width: 300,
                child: _videoPlayerController?.value.isInitialized ?? false
                    ? GestureDetector(
                        onDoubleTap: () => _videoPlayerController?.play(),
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
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
}
