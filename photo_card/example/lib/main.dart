import 'dart:io';

import 'package:example/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_card/lib.dart';
import 'package:photo_card/photo_card.edit.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder(
        future: callAssets(),
        builder: (futureContext, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return PhotoEditor(
              resources: DiyResources(
                  stickers: stickerList, backgrounds: backgroundList, frames: frameList, fonts: fontUrls.keys.toList()),
              completed: const Text('완료오'),
              onComplete: (layers) {
                // capture(layers);
              },
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
