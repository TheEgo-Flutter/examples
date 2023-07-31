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
import 'package:image_editor/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

import 'modules/blur.dart';
import 'modules/drawing_page.dart';
import 'modules/text.dart';

// List of global variables
List<Layer> layers = [], undoLayers = [], removedLayers = [];
Key? selectedAssetId;
final GlobalKey editGlobalKey = GlobalKey();

class ImageEditor extends StatefulWidget {
  final Directory? savePath;
  final Uint8List? image;
  final List<String> stickers;

  const ImageEditor({
    super.key,
    this.savePath,
    this.image,
    this.stickers = const [],
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  ImageItem currentImage = ImageItem();
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  ScreenshotController screenshotController = ScreenshotController();
  Widget baseLayer = const SizedBox.shrink();
  Size viewportSize = const Size(0, 0);

  final picker = ImagePicker();

  @override
  void dispose() {
    layers.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      loadImage(widget.image!);
    }
  }

  resetTransformation() {
    setState(() {});
  }

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile, viewportSize);
    baseLayer = Image.memory(currentImage.image, fit: BoxFit.contain);
    layers.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    return Theme(
      data: theme,
      child: Scaffold(
        key: scaffoldGlobalKey,
        backgroundColor: Colors.grey,
        appBar: buildAppBar(),
        body: buildScreenshotWidget(context),
        bottomNavigationBar: bottomBar,
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      actions: [
        const BackButton(),
        SizedBox(
          width: MediaQuery.of(context).size.width - 48,
          child: SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon:
                    Icon(Icons.undo, color: layers.length > 1 || removedLayers.isNotEmpty ? Colors.white : Colors.grey),
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
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: const Icon(Icons.photo),
                onPressed: () async {
                  var image = await picker.pickImage(source: ImageSource.gallery);

                  if (image == null) return;

                  loadImage(image);
                },
              ),
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

                  var binaryIntList = await screenshotController.capture();

                  LoadingScreen(scaffoldGlobalKey).hide();

                  if (mounted) Navigator.pop(context, binaryIntList);
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget buildScreenshotWidget(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: RepaintBoundary(
        key: editGlobalKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              baseLayer,
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('background_gestureDetector'),
                  onTap: () {
                    selectedAssetId = null;
                    setState(() {});
                  },
                ),
              ),
              ...layers.map((layer) {
                if (layer is BlurLayerData) {
                  return Positioned.fill(
                    child: GestureDetector(
                      key: const Key('blurLayer_gestureDetector'),
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
                    key: Key('${layer.key}_draggableResizable_asset'),
                    canTransform: selectedAssetId == layer.key ? true : false,
                    onLayerTapped: () {
                      selectedAssetId = layer.key;
                      var listLength = layers.length;
                      var index = layers.indexOf(layer);
                      if (index != listLength) {
                        layers.remove(layer);
                        layers.add(layer);
                      }
                      setState(() {});
                    },
                    onDragEnd: () {
                      selectedAssetId = null;
                      setState(() {});
                    },
                    onDelete: () async {
                      layers.remove(layer);
                      setState(() {});
                    },
                    layer: layer,
                  );
                } else {
                  return Container();
                }
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget get bottomBar => Container(
        height: const ButtonThemeData().height * 2,
        color: Colors.black87,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit),
                    Text(
                      'Brush',
                    )
                  ],
                ),
                onPressed: () async {
                  LayerData? layer = await Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => const BrushPainter(),
                    ),
                  );
                  if (layer == null) return;
                  undoLayers.clear();
                  removedLayers.clear();

                  layers.add(layer);

                  setState(() {});
                },
              ),
              ElevatedButton(
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.text_fields),
                    Text(
                      'Text',
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
              ElevatedButton(
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.blur_on),
                    Text(
                      'Blur',
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
              ElevatedButton(
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.face_5_outlined),
                    Text(
                      'Sticker',
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
