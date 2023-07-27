library image_editor_plus;

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/data/image_item.dart';
import 'package:image_editor/data/layer.dart';
import 'package:image_editor/layers/draggable_resizable.dart';
import 'package:image_editor/loading_screen.dart';
import 'package:image_editor/modules/sticker.dart';
import 'package:image_editor/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

import 'modules/blur.dart';
import 'modules/drawing_page.dart';
import 'modules/text.dart';

late Size viewportSize;
double viewportRatio = 1;
ImageItem? baseLayer;
List<Layer> layers = [], undoLayers = [], removedLayers = [];
Map<String, String> _translations = {};
final GlobalKey editGlobalKey = GlobalKey();
Key? selectedAssetId;
final GlobalKey globalKey = GlobalKey();
String i18n(String sourceString) => _translations[sourceString.toLowerCase()] ?? sourceString;

class ImageEditor extends StatelessWidget {
  final Uint8List? image;
  final List? images;
  final List<String> stickers;
  final Directory? savePath;
  final int maxLength;
  final ImageEditorFeatures features;
  final List<AspectRatioOption> cropAvailableRatios;

  const ImageEditor({
    super.key,
    this.image,
    this.images,
    this.stickers = const [],
    this.savePath,
    this.maxLength = 99,
    this.features = const ImageEditorFeatures(
      pickFromGallery: true,
      captureFromCamera: true,
      crop: true,
      blur: true,
      brush: true,
      sticker: true,
      filters: true,
      flip: true,
      rotate: true,
      text: true,
    ),
    this.cropAvailableRatios = const [
      AspectRatioOption(title: 'Freeform'),
      AspectRatioOption(title: '1:1', ratio: 1),
      AspectRatioOption(title: '4:3', ratio: 4 / 3),
      AspectRatioOption(title: '5:4', ratio: 5 / 4),
      AspectRatioOption(title: '7:5', ratio: 7 / 5),
      AspectRatioOption(title: '16:9', ratio: 16 / 9),
    ],
  });
  static i18n(Map<String, String> translations) {
    translations.forEach((key, value) {
      _translations[key.toLowerCase()] = value;
    });
  }

  /// Set custom theme properties default is dark theme with white text
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      background: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarTextStyle: TextStyle(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (images == null && image == null && !features.captureFromCamera && !features.pickFromGallery) {
      throw Exception('No image to work with, provide an image or allow the image picker.');
    }
    return SingleImageEditor(
      image: image,
      stickers: stickers,
      savePath: savePath,
      features: features,
      cropAvailableRatios: cropAvailableRatios,
    );
  }
}

class SingleImageEditor extends StatefulWidget {
  final Directory? savePath;
  final dynamic image;
  final List<String> stickers;
  final ImageEditorFeatures features;
  final List<AspectRatioOption> cropAvailableRatios;

  const SingleImageEditor({
    super.key,
    this.savePath,
    this.image,
    this.stickers = const [],
    this.features = const ImageEditorFeatures(
      pickFromGallery: true,
      captureFromCamera: true,
      crop: true,
      blur: true,
      brush: true,
      sticker: true,
      filters: true,
      flip: true,
      rotate: true,
      text: true,
    ),
    this.cropAvailableRatios = const [
      AspectRatioOption(title: 'Freeform'),
      AspectRatioOption(title: '1:1', ratio: 1),
      AspectRatioOption(title: '4:3', ratio: 4 / 3),
      AspectRatioOption(title: '5:4', ratio: 5 / 4),
      AspectRatioOption(title: '7:5', ratio: 7 / 5),
      AspectRatioOption(title: '16:9', ratio: 16 / 9),
    ],
  });

  @override
  createState() => _SingleImageEditorState();
}

class _SingleImageEditorState extends State<SingleImageEditor> {
  ImageItem currentImage = ImageItem();
  Offset offset1 = Offset.zero;
  Offset offset2 = Offset.zero;
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    layers.clear();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.image != null) {
      loadImage(widget.image!);
    }

    super.initState();
  }

  double flipValue = 0;
  int rotateValue = 0;

  double x = 0;
  double y = 0;
  double z = 0;

  double lastScaleFactor = 1, scaleFactor = 1;
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;

  resetTransformation() {
    scaleFactor = 1;
    x = 0;
    y = 0;
    setState(() {});
  }

  /// obtain image Uint8List by merging layers
  Future<Uint8List?> getMergedImage() async {
    if (layers.length == 1 && layers.first is BaseLayerData) {
      return (layers.first as BaseLayerData).file.image;
    }
    // else if (layers.length == 1 && layers.first is LayerData) {
    //   return (layers.first as LayerData).object;
    // }

    return screenshotController.capture(
      pixelRatio: pixelRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    return Theme(
      data: ImageEditor.theme,
      child: Scaffold(
        key: scaffoldGlobalKey,
        backgroundColor: Colors.grey,
        appBar: appBar,
        body: Screenshot(
          controller: screenshotController,
          child: RepaintBoundary(
            key: editGlobalKey,
            child: baseLayer != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Image.memory(
                          baseLayer!.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          key: const Key('stickersView_background_gestureDetector'),
                          onTap: () {},
                        ),
                      ),
                      ...layers.map((layer) {
                        if (layer is BlurLayerData) {
                          return Positioned.fill(
                            child: GestureDetector(
                              key: const Key('stickersView_blurLayer_gestureDetector'),
                              onTap: () {},
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: layer.radius,
                                  sigmaY: layer.radius,
                                ),
                                child: Container(
                                  color: layer.color.withOpacity(layer.opacity),
                                ),
                              ),
                            ),
                          );
                        } else if (layer is LayerData) {
                          return DraggableResizable(
                            key: Key('stickerPage_${layer.key}_draggableResizable_asset'),
                            canTransform: selectedAssetId == layer.key ? true : false,
                            onDelete: () async {
                              layers.remove(layer);
                              setState(() {});
                            },
                            size: layer.size * layer.scale,
                            constraints: BoxConstraints.tight(layer.size * layer.scale),
                            child: GestureDetector(
                              onTapDown: (TapDownDetails details) {
                                selectedAssetId = layer.key;
                                var listLength = layers.length;
                                var index = layers.indexOf(layer);
                                if (index != listLength) {
                                  layers.remove(layer);
                                  layers.add(layer);
                                }
                                setState(() {});
                              },
                              child: SizedBox(
                                width: layer.size.width,
                                height: layer.size.height,
                                child: layer.object,
                              ),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      }).toList()
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: bottomBar,
      ),
    );
  }

  AppBar get appBar {
    return AppBar(automaticallyImplyLeading: false, actions: [
      const BackButton(),
      SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: SingleChildScrollView(
          reverse: true,
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(Icons.undo, color: layers.length > 1 || removedLayers.isNotEmpty ? Colors.white : Colors.grey),
              onPressed: () {
                if (removedLayers.isNotEmpty) {
                  layers.add(removedLayers.removeLast());
                  setState(() {});
                  return;
                }

                if (layers.length <= 1) return; // do not remove image layer

                undoLayers.add(layers.removeLast());

                setState(() {});
              },
            ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(Icons.redo, color: undoLayers.isNotEmpty ? Colors.white : Colors.grey),
              onPressed: () {
                if (undoLayers.isEmpty) return;

                layers.add(undoLayers.removeLast());

                setState(() {});
              },
            ),
            if (widget.features.pickFromGallery)
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: const Icon(Icons.photo),
                onPressed: () async {
                  var image = await picker.pickImage(source: ImageSource.gallery);

                  if (image == null) return;

                  loadImage(image);
                },
              ),
            if (widget.features.captureFromCamera)
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: const Icon(Icons.camera_alt),
                onPressed: () async {
                  var image = await picker.pickImage(source: ImageSource.camera);

                  if (image == null) return;

                  loadImage(image);
                },
              ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {
                resetTransformation();
                setState(() {});

                LoadingScreen(scaffoldGlobalKey).show();

                var binaryIntList = await screenshotController.capture(pixelRatio: pixelRatio);

                LoadingScreen(scaffoldGlobalKey).hide();

                if (mounted) Navigator.pop(context, binaryIntList);
              },
            ),
          ]),
        ),
      ),
    ]);
  }

  final picker = ImagePicker();

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);
    baseLayer = currentImage;
    layers.clear();
    setState(() {});
  }

  Widget get bottomBar => Container(
        height: const ButtonThemeData().height * 2,
        color: Colors.black87,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.features.brush)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit),
                      Text(
                        i18n('Brush'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    Uint8List? drawing = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Brush(
                          image: currentImage,
                        ),
                      ),
                    );
                    if (drawing != null) {
                      undoLayers.clear();
                      removedLayers.clear();
                      layers.add(
                        LayerData(
                          key: UniqueKey(),
                          object: Image.memory(drawing),
                        ),
                      );
                      setState(() {});
                    }
                  },
                ),
              if (widget.features.text)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.text_fields),
                      Text(
                        i18n('Text'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    LayerData? layer = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TextEditorImage(),
                      ),
                    );
                    if (layer == null) return;
                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(layer);
                    setState(() {});
                  },
                ),
              if (widget.features.blur)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.blur_on),
                      Text(
                        i18n('Blur'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    var blurLayer = BlurLayerData(
                      color: Colors.transparent,
                      radius: 0.0,
                      opacity: 0.0,
                    );
                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(blurLayer);
                    setState(() {});
                    showModalBottomSheet(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                      ),
                      context: context,
                      builder: (context) {
                        return Blur(
                          blurLayer: blurLayer,
                          onSelected: (BlurLayerData updatedBlurLayer) {
                            setState(() {
                              layers.removeWhere((element) => element is BlurLayerData);
                              layers.add(updatedBlurLayer);
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              if (widget.features.sticker)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.face_5_outlined),
                      Text(
                        i18n('Sticker'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    LayerData? layer = await showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.black,
                      builder: (BuildContext context) {
                        return Stickers(
                          stickers: widget.stickers,
                        );
                      },
                    );
                    if (layer == null) return;
                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(layer);
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      );
}
