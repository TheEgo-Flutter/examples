import 'dart:io';

import 'package:example/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      home: ImageEditorExample(),
    ),
  );
}

class ImageEditorExample extends StatefulWidget {
  const ImageEditorExample({super.key});

  @override
  createState() => _ImageEditorExampleState();
}

class _ImageEditorExampleState extends State<ImageEditorExample> {
  VideoPlayerController? controller;
  List<ImageProvider> stickerList = [];
  List<ImageProvider> frameList = [];
  List<ImageProvider> backgroundList = [];
  List<LayerItem> returnedLayers = [];

  @override
  void initState() {
    super.initState();
    callAssets();
  }

  Future<void> callAssets() async {
    stickerList = await loadImageProvider(stickers);
    frameList = await loadImageProvider(frames);
    backgroundList = await loadImageProvider(backgrounds);
  }

  @override
  Widget build(BuildContext context) {
    int cardFlex = 70;
    return Scaffold(
      appBar: AppBar(
        title: ElevatedButton(
          child: const Text("Single image editor"),
          onPressed: () async {
            var result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoEditor(
                  resources: DiyResources(
                      stickers: stickerList,
                      backgrounds: backgroundList,
                      frames: frameList,
                      fonts: fontUrls.keys.toList()),

                  // tempSavedLayers: returnedLayers, // you can pass any previously saved layers here
                  onReturnLayers: (layers) {
                    returnedLayers = layers;
                    setState(() {});
                  },
                  onEndDialog: () async {
                    bool? result = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: const Text('You will lose all your changes.'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );
                    return result ?? false;
                  },
                ),
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: returnedLayers.isNotEmpty
          ? Center(
              child: PhotoCard(
                tempSavedLayers: returnedLayers,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
