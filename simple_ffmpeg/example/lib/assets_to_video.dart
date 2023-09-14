import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_ffmpeg/lib.dart';
import 'package:video_player/video_player.dart';

const int _DURATION = 1;
const int _TOTAL_FRAME = _DURATION * 60;
const double _RATIO = 3.0;
const String _FILE_NAME = 'capture_';
const double _SIZE = 200.0;
const String _SCALE = '${_SIZE * _RATIO}:${_SIZE * _RATIO}';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RenderPage());
  }
}

List<String> _assets = [
  'assets/bg_0.png',
  'assets/bg_1.png',
  'assets/bg_2.png',
  'assets/bg_3.png',
  'assets/bg_4.png',
  'assets/bg_5.png',
  'assets/bg_6.png',
  'assets/bg_7.png',
  'assets/bg_8.png'
];
Future<String> assetPath(String assetName) async {
  return join((await tempDirectory).path, assetName);
}

Future<Directory> get documentsDirectory async {
  return await getApplicationDocumentsDirectory();
}

Future<Directory> get tempDirectory async {
  return await getTemporaryDirectory();
}

Future<List<String>> writeAsset() async {
  final directory = await tempDirectory;
  List<String> capturedImages = [];
  for (var assetName in _assets) {
    final assetByteData = await rootBundle.load(assetName);
    final buffer = assetByteData.buffer.asUint8List();
    final imagePath = '${directory.path}/${assetName.split('/').last}';
    final file = File(imagePath);
    await file.writeAsBytes(buffer);
    capturedImages.add(imagePath);
  }
  return capturedImages;
}

class RenderPage extends StatefulWidget {
  const RenderPage({super.key});

  @override
  _RenderPageState createState() => _RenderPageState();
}

class _RenderPageState extends State<RenderPage> with SingleTickerProviderStateMixin {
  late VideoEncoder _videoEncoder;
  VideoPlayerController? _videoPlayerController;
  String _videoPath = '';
  @override
  void initState() {
    super.initState();

    _videoEncoder = VideoEncoder(
      fileName: _FILE_NAME,
      totalFrame: _TOTAL_FRAME,
      duration: _DURATION, // Assuming 1 second per frame
      scale: _SCALE, // Example pixel ratio
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FutureBuilder(
            future: writeAsset(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
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
                        File? video = await _videoEncoder.fileToVideo(snapshot.requireData);
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
                    Container(
                      child: _videoPlayerController?.value.isInitialized ?? false
                          ? AspectRatio(
                              aspectRatio: _videoPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController!),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 5.0,
                          mainAxisSpacing: 5.0,
                        ),
                        itemCount: snapshot.data?.length,
                        itemBuilder: (context, index) {
                          String item = snapshot.data![index];
                          return Stack(
                            children: [
                              Image.file(File(item)),
                              Text(item.split('/').last.split('.').first,
                                  style: const TextStyle(color: Colors.white, fontSize: 20)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController?.dispose();
  }
}
