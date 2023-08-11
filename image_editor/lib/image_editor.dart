import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/draggable_resizable.dart';
import 'package:image_editor/modules/item_selector.dart';
import 'package:image_editor/theme.dart';
import 'package:image_editor/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

import 'layer_manager.dart';
import 'loading_screen.dart';
import 'modules/brush_painter.dart';
import 'modules/text_layer/text_editor.dart';

Key? selectedKey;
final GlobalKey cardKey = GlobalKey();
final GlobalKey backgroundKey = GlobalKey();
final GlobalKey frameKey = GlobalKey();
final GlobalKey deleteAreaKey = GlobalKey();
Size get cardSize => _cardSize ?? Size.zero;
Offset get cardPosition => _cardPosition ?? Offset.zero;
Size? _cardSize;
Offset? _cardPosition;

class PhotoEditor extends StatefulWidget {
  final Directory? savePath;
  final Uint8List? image;
  final List<dynamic> stickers;
  final List<dynamic> backgrounds;
  final List<dynamic> frames;
  final AspectRatioOption aspectRatio;

  const PhotoEditor({
    super.key,
    this.savePath,
    this.image,
    this.stickers = const [],
    this.backgrounds = const [],
    this.frames = const [],
    this.aspectRatio = AspectRatioOption.r16x9,
  });

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  LayerType _selectedType = LayerType.background;
  LayerManager layerManager = LayerManager();
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  ScreenshotController screenshotController = ScreenshotController();
  List<LinearGradient> gradients = [];
  LinearGradient? cardColor;

  final picker = ImagePicker();

  @override
  void dispose() {
    layerManager.layers.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    gradients = RandomGradientContainers().buildRandomGradientContainer(10);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await card();
      setState(() {});
    });
  }

  Future<void> card() async {
    final RenderBox renderBox = cardKey.currentContext?.findRenderObject() as RenderBox;
    _cardSize = renderBox.size; // The size of the card
    _cardPosition = renderBox.localToGlobal(Offset.zero); // The position of the card
  }

  Future<void> _loadImageColor(Uint8List imageFile) async {
    ColorScheme newScheme = await ColorScheme.fromImageProvider(provider: MemoryImage(imageFile));
    setState(() {
      cardColor = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          newScheme.primaryContainer,
          newScheme.primary,
        ],
      );
    });
  }

  Future<Uint8List> _loadImage(dynamic imageFile) async {
    if (imageFile is Uint8List) return imageFile;
    final image = await (imageFile as dynamic).readAsBytes();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: WillPopScope(
        onWillPop: () async => false,
        child: GestureDetector(
          key: const Key('background_gestureDetector'),
          onTap: () {
            setState(() {
              selectedKey = null;
            });
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            key: scaffoldGlobalKey,
            backgroundColor: Colors.grey,
            appBar: AppBar(
              // backgroundColor: Colors.amber[100],
              elevation: 0,
              leading: const BackButton(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    selectedKey = null;

                    setState(() {});

                    LoadingScreen(scaffoldGlobalKey).show();

                    var binaryIntList = await screenshotController.capture();

                    LoadingScreen(scaffoldGlobalKey).hide();

                    if (mounted) Navigator.pop(context, binaryIntList);
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: buildScreenshotWidget(context)),
                  Expanded(flex: 1, child: buildObjectSelector()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildObjectSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Container(
          width: cardSize.width,
          color: Colors.grey[200],
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildItemCategory(),
              Expanded(child: buildItemArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildScreenshotWidget(BuildContext context) {
    return RepaintBoundary(
      child: Screenshot(
        controller: screenshotController,
        child: ClipRRect(
          key: cardKey,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: buildImageLayer(context),
        ),
      ),
    );
  }

  Widget buildImageLayer(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        decoration: cardColor != null
            ? BoxDecoration(
                gradient: cardColor,
              )
            : const BoxDecoration(color: Colors.white),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio.ratio ?? 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ...layerManager.layers.map((layer) => buildLayerWidgets(layer)),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  key: deleteAreaKey,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green[900]!, width: 2),
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.delete,
                    color: Colors.green[900],
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildLayerWidgets(LayerItem layer) {
    return DraggableResizable(
      key: Key('${layer.key}_draggableResizable_asset'),
      isFocus: selectedKey == layer.key ? true : false,
      onLayerTapped: (LayerItem item) async {
        if (layer.type == LayerType.text) {
          setState(() {
            layerManager.removeLayerByKey(layer.key);
          });

          TextEditorStyle? textEditorStyle = await showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) {
              return PositionedWidget(
                position: cardPosition,
                size: cardSize,
                child: TextEditor(
                  textEditorStyle: layer.object,
                ),
              );
            },
          );
          setState(() {});
          if (textEditorStyle == null) return;

          var newLayer = LayerItem(
            UniqueKey(),
            type: LayerType.text,
            object: textEditorStyle,
            position: item.position,
            size: textEditorStyle.fieldSize,
          );
          layerManager.addLayer(newLayer);
          setState(() {});
        }
        setState(() {
          selectedKey = layer.key;

          if (layer.type == LayerType.sticker) {
            layerManager.moveLayerToFront(layer);
          }
        });
      },
      onDragStart: (LayerItem item) {
        setState(() {
          selectedKey = layer.key;
          if (layer.type == LayerType.text || layer.type == LayerType.sticker) {
            layerManager.moveLayerToFront(layer);
          }
        });
      },
      onDragEnd: (LayerItem item) {
        setState(() {
          selectedKey = null;
        });
      },
      onDelete: () {
        setState(() {
          layerManager.removeLayerByKey(layer.key);
        });
      },
      layerItem: layer,
    );
  }
  //---------------------------------//

  Widget buildItemArea() {
    switch (_selectedType) {
      case LayerType.sticker:
        return ItemSelector.sticker(
          items: widget.stickers,
          onSelected: (child) {
            if (child == null) return;
            // size dynamic change for device (default is 150X150)
            Size size = const Size(150, 150);
            Offset offset = Offset(cardSize.width / 2 - size.width / 2, cardSize.height / 2 - size.height / 2);
            LayerItem layer = LayerItem(
              UniqueKey(),
              type: _selectedType,
              object: child,
              position: offset,
              size: size,
            );
            layerManager.addLayer(layer);
            setState(() {});
          },
        );
      case LayerType.frame:
        return ItemSelector.frame(
          items: widget.frames,
          onSelected: (child) {
            late LayerItem layer;
            if (child == null) {
              layer = LayerItem(
                frameKey,
                type: _selectedType,
                object: null,
                position: Offset.zero,
                size: cardSize,
              );
            } else {
              layer = LayerItem(
                frameKey,
                type: _selectedType,
                object: child,
                position: Offset.zero,
                size: cardSize,
              );
            }
            layerManager.addLayer(layer);
            setState(() {});
          },
        );
      case LayerType.background:
        return ItemSelector.background(
          items: [
            ...List.generate(
              10,
              (index) => Container(
                decoration: BoxDecoration(
                  gradient: gradients[index],
                ),
                width: cardSize.width,
                height: cardSize.height,
              ),
            ),
            ...widget.backgrounds
          ],
          onSelected: (child) async {
            if (child == null) {
              var image = await picker.pickImage(source: ImageSource.gallery);
              if (image == null) return;
              Uint8List? loadImage = await _loadImage(image);
              await _loadImageColor(loadImage);
              LayerItem background = LayerItem(
                backgroundKey,
                type: _selectedType,
                object: Image.memory(loadImage),
                position: Offset.zero,
                size: cardSize,
              );
              layerManager.addLayer(background);
            } else {
              LayerItem layer = LayerItem(
                backgroundKey,
                type: _selectedType,
                object: child,
                position: Offset.zero,
                size: cardSize,
              );
              layerManager.addLayer(layer);
            }
            setState(() {});
          },
        );
      default:
        return SizedBox();
    }
  }

  Widget buildItemCategory() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Theme(
        data: ThemeData(
          chipTheme: const ChipThemeData(padding: EdgeInsets.zero, labelPadding: EdgeInsets.symmetric(horizontal: 8)),
          textTheme: Theme.of(context).textTheme.apply(
                fontSizeFactor: 0.6,
                fontSizeDelta: 2.0,
              ),
        ),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text("프레임"),
              selected: _selectedType == LayerType.frame,
              onSelected: (bool selected) async {
                setState(() {
                  _selectedType = LayerType.frame;
                });
              },
            ),
            ChoiceChip(
              label: const Text("배경"),
              selected: _selectedType == LayerType.background,
              onSelected: (bool selected) async {
                setState(() {
                  _selectedType = LayerType.background;
                });
              },
            ),
            ChoiceChip(
              label: const Text("스티커"),
              selected: _selectedType == LayerType.sticker,
              onSelected: (bool selected) async {
                setState(() {
                  _selectedType = LayerType.sticker;
                });
              },
            ),
            ChoiceChip(
              label: const Text("텍스트"),
              selected: _selectedType == LayerType.text,
              onSelected: (bool selected) async {
                setState(() {
                  _selectedType = LayerType.text;
                });

                TextEditorStyle? textEditorStyle = await showGeneralDialog(
                  context: context,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return PositionedWidget(
                      position: cardPosition,
                      size: cardSize,
                      child: const TextEditor(),
                    );
                  },
                );
                setState(() {});

                if (textEditorStyle == null) return;
                var layer = LayerItem(
                  UniqueKey(),
                  type: LayerType.text,
                  object: textEditorStyle,
                  position: Offset.zero,
                  size: textEditorStyle.fieldSize,
                );
                layerManager.addLayer(layer);
                setState(() {});
              },
            ),
            ChoiceChip(
              label: const Text("그리기"),
              selected: _selectedType == LayerType.drawing,
              onSelected: (bool selected) async {
                setState(() {
                  _selectedType = LayerType.drawing;
                });
                (Uint8List?, Size?)? data = await showGeneralDialog(
                  context: context,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return PositionedWidget(
                      position: cardPosition,
                      size: cardSize,
                      child: const BrushPainter(),
                    );
                  },
                );
                setState(() {});
                if ((data != null && data.$1 != null && data.$2 != null)) {
                  var image = Image.memory(data.$1!);
                  var size = data.$2!;
                  setState(() {
                    Offset offset = Offset(cardSize.width / 2 - size.width / 2, cardSize.height / 2 - size.height / 2);
                    var layer = LayerItem(
                      UniqueKey(),
                      type: LayerType.drawing,
                      object: image,
                      position: offset,
                      size: size,
                    );
                    layerManager.addLayer(layer);
                  });
                }
              },
            ),
          ],
        ),
      ),
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

class RandomGradientContainers {
  final random = Random();

  Color _getRandomColor() {
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  LinearGradient _getRandomGradient() {
    return LinearGradient(
      colors: [_getRandomColor(), _getRandomColor()],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  //return RandomGradientContainer with random gradient need index
  List<LinearGradient> buildRandomGradientContainer(int length) {
    return List.generate(
      length,
      (index) => _getRandomGradient(),
    );
  }
}
