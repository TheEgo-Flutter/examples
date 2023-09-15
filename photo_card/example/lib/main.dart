import 'dart:developer';
import 'dart:io';

import 'package:example/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:photo_card/lib.dart';
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

Future<ByteData> fetchFont(String url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return ByteData.view(response.bodyBytes.buffer);
  } else {
    throw Exception('Failed to load font');
  }
}

class ImageEditorExample extends StatefulWidget {
  const ImageEditorExample({super.key});

  @override
  createState() => _ImageEditorExampleState();
}

class _ImageEditorExampleState extends State<ImageEditorExample> {
  VideoPlayerController? controller;
  List<Uint8List> stickerList = [];
  List<ImageProvider> frameList = [];
  List<ImageProvider> backgroundList = [];
  List<LayerItem> returnedLayers = [];

  Future<List<ImageProvider>> loadImageProvider(List<String> assetPaths) async {
    List<ImageProvider> stickers = [];
    for (String path in assetPaths) {
      try {
        final ByteData data = await rootBundle.load('assets/$path');
        final Uint8List bytes = data.buffer.asUint8List();
        stickers.add(MemoryImage(bytes));
      } catch (e) {
        log("이미지를 불러오는 도중 오류가 발생했습니다: $e");
      }
    }
    return stickers;
  }

  Future<List<Uint8List>> loadStickers(List<String> assetPaths) async {
    List<Uint8List> stickers = [];
    for (String path in assetPaths) {
      try {
        final ByteData data = await rootBundle.load('assets/$path');
        final List<int> bytes = data.buffer.asUint8List();
        stickers.add(Uint8List.fromList(bytes));
      } catch (e) {
        log("이미지를 불러오는 도중 오류가 발생했습니다: $e");
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
    frameList = await loadImageProvider(frames);
    backgroundList = await loadImageProvider(backgrounds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ImageEditor Example"),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        int cardFlex = 70;
        double maxWidth = (constraints.maxHeight) * cardFlex / 100 * (AspectRatioEnum.photoCard.ratio ?? 1);
        return Stack(
          children: [
            Center(
              child: Column(
                children: [
                  Expanded(
                    flex: cardFlex,
                    child: returnedLayers.isNotEmpty
                        ? ClipPath(
                            clipper: CardBoxClip(aspectRatio: AspectRatioEnum.photoCard),
                            child: PhotoCard.view(
                              width: returnedLayers.first.rect.width,
                              tempSavedLayers: returnedLayers,
                            ),
                          )
                        : const Center(child: Text('photo card is null')),
                  ),
                  Expanded(
                    flex: 100 - cardFlex,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        child: const Text("Single image editor"),
                        onPressed: () async {
                          var result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoCard(
                                stickers: stickerList,
                                backgrounds: backgroundList,
                                frames: frameList,
                                fonts: fontUrls.keys.toList(),
                                tempSavedLayers: returnedLayers, // you can pass any previously saved layers here
                                onReturnLayers: (layers) {
                                  returnedLayers = layers;
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
