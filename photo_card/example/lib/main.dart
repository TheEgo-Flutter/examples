import 'dart:io';

import 'package:example/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:photo_card/lib.dart';
import 'package:photo_card/utils/diy_resources.dart';
import 'package:video_player/video_player.dart';

void main() async {
  if (Platform.isIOS) {
    for (var fontName in fontUrls.keys) {
      var fontLoader = FontLoader(fontName);
      fontLoader.addFont(fetchFont(fontUrls[fontName] ?? ''));
      await fontLoader.load();
    }
  }

  runApp(
    const MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return const ImageEditor();
  }
}

class ImageEditor extends StatefulWidget {
  const ImageEditor({super.key});

  @override
  createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  List<StickerImageProvider> stickerList = [];
  List<ImageProvider> frameList = [];
  List<ImageProvider> backgroundList = [];
  List<LayerItem> returnedLayers = [];

  Future<void> callAssets() async {
    List<ImageProvider> thumbnailStickerList = await loadImageProvider(stickers);
    stickerList = List<StickerImageProvider>.generate(
        thumbnailStickerList.length, (index) => StickerImageProvider(image: thumbnailStickerList[index]));

    frameList = await loadImageProvider(frames);
    backgroundList = await loadImageProvider(backgrounds);
  }

  @override
  Widget build(BuildContext mainContext) {
    int cardFlex = 70;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder(
        future: callAssets(),
        builder: (futureContext, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Row(
                  children: [
                    TextButton(
                        onPressed: () {
                          try {
                            Navigator.push(
                              mainContext,
                              MaterialPageRoute(
                                builder: (context) => CardViewPage(returnedLayers: returnedLayers),
                              ),
                            );
                          } catch (e) {
                            print("Navigator.push error: $e");
                          }
                        },
                        child: const Text('Go to CardViewPage')),
                  ],
                ),
                Expanded(
                  child: PhotoEditor(
                    resources: DiyResources(
                        stickers: stickerList,
                        backgrounds: backgroundList,
                        frames: frameList,
                        fonts: fontUrls.keys.toList()),
                    completed: const Text('완료오'),
                    onComplete: (layers) {
                      returnedLayers = layers;

                      try {
                        print(returnedLayers.length);
                        Navigator.push(
                          mainContext,
                          MaterialPageRoute(
                            builder: (context) => CardViewPage(returnedLayers: returnedLayers),
                          ),
                        );
                      } catch (e) {
                        print("Navigator.push error: $e");
                      }
                    },
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );

    ;
  }
}

class CardViewPage extends StatefulWidget {
  final List<LayerItem> returnedLayers;

  const CardViewPage({super.key, required this.returnedLayers});

  @override
  State<CardViewPage> createState() => _CardViewPageState();
}

class _CardViewPageState extends State<CardViewPage> {
  late PhotoCardController controller;
  late VideoPlayerController videoController;
  File? file;
  @override
  void initState() {
    super.initState();

    controller = PhotoCardController();
    videoController = VideoPlayerController.file(File(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Card View Page')),
        body: Row(
          children: [
            Expanded(
              child: PhotoCard(
                controller: controller,
                tempSavedLayers: widget.returnedLayers,
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  videoController.play();
                },
                child: VideoPlayer(videoController),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'save',
              onPressed: (file != null)
                  ? () async {
                      await Gal.putVideo(file!.path).whenComplete(() =>
                          //SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('저장 완료'),
                              duration: Duration(seconds: 1),
                            ),
                          ));
                    }
                  : null,
              child: const Icon(Icons.save),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'video',
              onPressed: () async {
                File? _file = await controller.encoding();
                setState(() {
                  file = _file;
                });
              },
              child: const Icon(Icons.video_camera_back),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'play',
              onPressed: () {
                controller.play();
              },
              child: const Icon(Icons.play_arrow),
            ),
          ],
        ));
  }
}
