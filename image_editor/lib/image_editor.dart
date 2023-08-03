import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/draggable_resizable.dart';
import 'package:image_editor/loading_screen.dart';
import 'package:image_editor/modules/sticker.dart';
import 'package:image_editor/theme.dart';
import 'package:image_editor/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

import 'layer_manager.dart';
import 'modules/brush_painter.dart';
import 'modules/text.dart';

Key? selectedKey;
final GlobalKey cardKey = GlobalKey();
final GlobalKey backgroundKey = GlobalKey();
Size get cardSize => _cardSize ?? Size.zero;
Offset get cardPosition => _cardPosition ?? Offset.zero;
Size? _cardSize;
Offset? _cardPosition;

class PhotoEditor extends StatefulWidget {
  final Directory? savePath;
  final Uint8List? image;
  final List<String> stickers;
  final AspectRatioOption aspectRatio;

  const PhotoEditor({
    super.key,
    this.savePath,
    this.image,
    this.stickers = const [],
    this.aspectRatio = AspectRatioOption.r16x9,
  });

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  LayerManager layerManager = LayerManager();
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  ScreenshotController screenshotController = ScreenshotController();
  Uint8List? currentImage;
  Size viewportSize = const Size(0, 0);
  bool showAppBar = true;
  LinearGradient cardColor = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.transparent,
    ],
  );

  final picker = ImagePicker();

  @override
  void dispose() {
    layerManager.layers.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      await card();
      await loadImage(image);
    });
  }

  Future<void> card() async {
    final RenderBox renderBox = cardKey.currentContext?.findRenderObject() as RenderBox;
    _cardSize = renderBox.size; // The size of the card
    _cardPosition = renderBox.localToGlobal(Offset.zero); // The position of the card
  }

  Future<void> loadImage(dynamic imageFile) async {
    currentImage = await _loadImage(imageFile);
    if (currentImage != null) {
      ColorScheme newScheme = await ColorScheme.fromImageProvider(provider: MemoryImage(currentImage!));
      setState(() {
        cardColor = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            newScheme.primary,
            newScheme.secondary,
          ],
        );
        layerManager.layers.clear();
      });
    }
  }

  Future<Uint8List> _loadImage(dynamic imageFile) async {
    if (imageFile is Uint8List) {
      return imageFile;
    } else if (imageFile is File || imageFile is XFile) {
      final image = await imageFile.readAsBytes();
      return image;
    }
    return Uint8List.fromList([]);
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    return Theme(
      data: theme,
      child: GestureDetector(
        key: const Key('background_gestureDetector'),
        onTap: () {
          setState(() {
            selectedKey = null;
          });
        },
        child: Scaffold(
          key: scaffoldGlobalKey,
          backgroundColor: Colors.grey,
          body: Scaffold(body: buildScreenshotWidget(context)),
        ),
      ),
    );
  }

  Widget buildScreenshotWidget(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Center(
      child: RepaintBoundary(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.0, statusBarHeight + 8.0, 8.0, 8.0),
          child: Screenshot(
            controller: screenshotController,
            child: ClipRRect(
              key: cardKey,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: cardColor,
                ),
                child: AspectRatio(
                  aspectRatio: widget.aspectRatio.ratio ?? 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DraggableBackground(
                        size: cardSize != Size.zero ? cardSize : MediaQuery.of(context).size,
                        uint8List: currentImage,
                        canTransform: selectedKey == backgroundKey ? true : false,
                        onDragStart: () {
                          setState(() {
                            selectedKey = backgroundKey;
                          });
                        },
                        onDragEnd: () {
                          setState(() {
                            selectedKey = null;
                          });
                        },
                      ),
                      ...layerManager.layers.map((layer) {
                        return DraggableObject(
                          key: Key('${layer.key}_draggableResizable_asset'),
                          canTransform: selectedKey == layer.key ? true : false,
                          onDragStart: () {
                            setState(() {
                              selectedKey = layer.key;
                              var listLength = layerManager.layers.length;
                              var index = layerManager.layers.indexOf(layer);
                              if (index != listLength) {
                                layerManager.layers.remove(layer);
                                layerManager.layers.add(layer);
                              }
                            });
                          },
                          onDragEnd: () {
                            setState(() {
                              selectedKey = null;
                            });
                          },
                          onDelete: () async {
                            setState(() {
                              layerManager.removeLayer(layer);
                            });
                          },
                          size: const Size(150, 150),
                          child: layer,
                        );
                      }).toList(),
                      Positioned(top: 0, right: 0, child: buildAppBar())
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //---------------------------------//

  Widget buildAppBar() {
    if (!showAppBar) return const SizedBox.shrink();
    return SizedBox(
      width: cardSize.width,
      child: Row(children: [
        const BackButton(),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              setState(() {
                showAppBar = false;
              });
              Widget? layer = await showGeneralDialog(
                context: context,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return PositionedWidget(
                    position: cardPosition,
                    size: cardSize,
                    child: const BrushPainter(),
                  );
                },
              );
              if (layer == null) {
                setState(() {
                  showAppBar = true;
                });
                return;
              }
              setState(() {
                showAppBar = true;
                layerManager.addLayer(layer);
              });
            }),
        IconButton(
          icon: const Icon(Icons.text_fields),
          onPressed: () async {
            Widget? layer = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TextEditorImage(),
              ),
            );
            if (layer == null) return;
            layerManager.addLayer(layer);
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.face_5_outlined),
          onPressed: () async {
            Widget? layer = await showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black,
              builder: (BuildContext context) {
                return Stickers(
                  stickers: widget.stickers,
                );
              },
            );
            if (layer == null) return;
            layerManager.addLayer(layer);
            setState(() {});
          },
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: const Icon(Icons.check),
          onPressed: () async {
            selectedKey = null;
            showAppBar = false;

            setState(() {});

            LoadingScreen(scaffoldGlobalKey).show();

            var binaryIntList = await screenshotController.capture();

            LoadingScreen(scaffoldGlobalKey).hide();

            if (mounted) Navigator.pop(context, binaryIntList);
          },
        ),
      ]),
    );
  }
}

class PositionedWidget extends StatelessWidget {
  final Widget child;
  final Size size;
  final Offset position;

  const PositionedWidget({super.key, required this.child, required this.size, required this.position});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Transform.translate(
        offset: Offset(position.dx, position.dy),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
