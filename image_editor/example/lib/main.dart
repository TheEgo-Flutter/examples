import 'dart:io';

import 'package:example/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:image_editor/image_editor.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ImageEditorExample(),
    ),
  );
}

class ImageEditorExample extends StatefulWidget {
  const ImageEditorExample({
    super.key,
  });

  @override
  createState() => _ImageEditorExampleState();
}

class _ImageEditorExampleState extends State<ImageEditorExample> {
  File? _file;
  VideoPlayerController? controller;
  List<Uint8List> stickerList = [];
  List<Uint8List> frameList = [];
  List<Uint8List> backgroundList = [];
  Future<List<Uint8List>> loadStickers(List<String> assetPaths) async {
    List<Uint8List> stickers = [];
    for (String path in assetPaths) {
      try {
        final ByteData data = await rootBundle.load('assets/$path');
        final List<int> bytes = data.buffer.asUint8List();
        stickers.add(Uint8List.fromList(bytes));
      } catch (e) {
        print("스티커를 불러오는 도중 오류가 발생했습니다: $e");
      }
    }
    return stickers;
  }

  @override
  void initState() {
    super.initState();
    callAssets();
  }

  Future<void> callAssets() async {
    stickerList = await loadStickers(stickers);
    frameList = await loadStickers(frames);
    backgroundList = await loadStickers(backgrounds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ImageEditor Example"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_file != null)
            Expanded(
              child: FutureBuilder(future: () async {
                controller = VideoPlayerController.file(_file!);
                await controller!.initialize();
                await controller!.setLooping(true);
                controller!.play();
                return controller;
              }(), builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return Column(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: snapshot.data?.value.size.width ?? 0,
                            height: snapshot.data?.value.size.height ?? 0,
                            child: VideoPlayer(snapshot.data!),
                          ),
                        ),
                      ),
                      VideoProgressIndicator(
                        snapshot.data!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          backgroundColor: Colors.transparent,
                          bufferedColor: Colors.transparent,
                          playedColor: Colors.transparent,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: Text(
                      "Error loading file: ${snapshot.error}",
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  );
                }
              }),
            ),
          const SizedBox(height: 16),
          if (_file != null)
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                await Gal.putVideo(_file!.path, album: 'dingdongU');

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Saved! ✅'),
                ));
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text("Single image editor"),
            onPressed: () async {
              var file = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageEditor(
                    stickers: stickerList,
                    backgrounds: backgroundList,
                    frames: frameList,
                  ),
                ),
              );

              if (file != null) {
                _file = file;
                setState(() {});
              }
            },
          ),
        ]),
      ),
    );
  }
}
