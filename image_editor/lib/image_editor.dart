import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:render/render.dart';
import 'package:vibration/vibration.dart';

import 'photo_editor.dart';

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

class _PhotoEditorState extends State<PhotoEditor> with WidgetsBindingObserver, TickerProviderStateMixin {
  LayerType _selectedType = LayerType.background;
  LayerManager layerManager = LayerManager();
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  List<LinearGradient> gradients = [];
  LinearGradient? cardColor;
  bool get enableDelete => selectedLayerItem?.type == LayerType.sticker || selectedLayerItem?.type == LayerType.text;
  final cardBoxClipper = CardBoxClip();
  final picker = ImagePicker();
  @override
  void didChangeMetrics() {
    bottomInsetNotifier.value = MediaQuery.of(context).viewInsets.bottom;
    _getRect();
  }

  @override
  void dispose() {
    layerManager.layers.clear();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    gradients = RandomGradientContainers().buildRandomGradientContainer(10);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getRect();
    });
    bottomInsetNotifier.addListener(() {
      log('bottomInsetNotifier : ${bottomInsetNotifier.value}');
    });
  }

  Future<void> _getRect() async {
    //* get card box rect
    final RenderBox? cardRenderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (cardRenderBox != null) {
      Offset offset = cardRenderBox.localToGlobal(Offset.zero);
      cardBoxRect = Rect.fromLTWH(offset.dx, offset.dy, cardRenderBox.size.width, cardRenderBox.size.height);
    }
    //* get object box rect
    final RenderBox? objectRenderBox = objectAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (objectRenderBox != null) {
      Offset offset = objectRenderBox.localToGlobal(Offset.zero);
      objectBoxRect = Rect.fromLTWH(offset.dx, offset.dy, objectRenderBox.size.width, objectRenderBox.size.height);
    }
    //* get delete area rect
    final RenderBox? deleteAreaRenderBox = deleteAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (cardRenderBox != null) {
      final Offset offset = deleteAreaRenderBox!.localToGlobal(Offset.zero) - cardBoxRect.topLeft;
      deleteAreaRect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        deleteAreaRenderBox.size.width,
        deleteAreaRenderBox.size.height,
      );
    }

    log('_getRect card Box Rect : $cardBoxRect\nobject Box Rect : $objectBoxRect');
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

  void _handleDeleteAction(
    Offset currentFingerPosition,
    LayerItem layerItem,
    LayerItemStatus status,
  ) async {
    bool deletable = deleteAreaRect.contains(currentFingerPosition);
    log(deletable.toString());
    if (!enableDelete) return;
    if (!deletable) return;
    if (status == LayerItemStatus.dragging) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(amplitude: 100);
      }
    } else if (status == LayerItemStatus.completed) {
      layerManager.removeLayerByKey(layerItem.key);
    } else {
      return;
    }
  }

  Stream<RenderNotifier>? renderStream;
  final RenderController renderController = RenderController(logLevel: LogLevel.debug);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          key: scaffoldGlobalKey,
          backgroundColor: Colors.grey,
          appBar: AppBar(
            elevation: 0,
            leading: const BackButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  final stream = renderController.captureMotionWithStream(
                    const Duration(seconds: 5),
                    settings: const MotionSettings(
                      pixelRatio: 5,
                      frameRate: 80,
                      simultaneousCaptureHandlers: 10,
                    ),
                    logInConsole: true,
                  );
                  setState(() {
                    renderStream = stream;
                  });
                  final result = await stream.firstWhere((event) => event.isResult || event.isFatalError);
                  if (result.isFatalError) return;

                  if (mounted) Navigator.pop(context, (result as RenderResult).output);
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              children: [
                Expanded(flex: 3, child: buildScreenshotWidget(context)),
                const SizedBox(height: 8),
                Expanded(flex: 1, child: buildObjectSelector()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildScreenshotWidget(BuildContext context) {
    return Render(
      controller: renderController,
      child: ClipPath(
        key: cardKey,
        clipper: cardBoxClipper,
        child: buildImageLayer(context),
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
              DeleteIconButton(
                visible: enableDelete,
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
      isFocus: selectedLayerItem?.key == layer.key ? true : false,
      onLayerTapped: (LayerItem item) async {
        if (layer.type == LayerType.text) {
          setState(() {
            layerManager.removeLayerByKey(layer.key);
          });

          TextEditorStyle? textEditorStyle = await showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) {
              return RectClipper(
                rect: cardBoxRect,
                child: TextEditor(
                  textEditorStyle: layer.object as TextEditorStyle,
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
            offset: item.offset,
            size: textEditorStyle.fieldSize,
          );
          layerManager.addLayer(newLayer);
          setState(() {});
        }
        setState(() {
          selectedLayerItem = layer;

          if (layer.type == LayerType.sticker) {
            layerManager.moveLayerToFront(layer);
          }
        });
      },
      onDragStart: (LayerItem item) {
        setState(() {
          selectedLayerItem = layer;
          if (layer.type == LayerType.text || layer.type == LayerType.sticker) {
            layerManager.moveLayerToFront(layer);
          }
        });
      },
      onDragEnd: (LayerItem item) {
        setState(() {
          selectedLayerItem = null;
        });
      },
      onDelete: _handleDeleteAction,
      layerItem: layer,
    );
  }

  //---------------------------------//
  Widget buildObjectSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipPath(
        key: objectAreaKey,
        clipper: ObjectBoxClip(),
        child: Container(
          width: cardBoxClipper.width < 1 ? 100 : cardBoxClipper.width,
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

  Widget buildItemArea() {
    switch (_selectedType) {
      case LayerType.sticker:
        return ItemSelector.sticker(
          items: widget.stickers,
          onSelected: (child) {
            if (child == null) return;
            // size dynamic change for device (default is 150X150)
            Size size = const Size(150, 150);
            Offset offset =
                Offset(cardBoxRect.size.width / 2 - size.width / 2, cardBoxRect.size.height / 2 - size.height / 2);
            LayerItem layer = LayerItem(
              UniqueKey(),
              type: _selectedType,
              object: child,
              offset: offset,
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
                UniqueKey(),
                type: _selectedType,
                object: null,
                offset: Offset.zero,
                size: cardBoxRect.size,
              );
            } else {
              layer = LayerItem(
                UniqueKey(),
                type: _selectedType,
                object: child,
                offset: Offset.zero,
                size: cardBoxRect.size,
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
                width: cardBoxRect.size.width,
                height: cardBoxRect.size.height,
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
                UniqueKey(),
                type: _selectedType,
                object: Image.memory(loadImage),
                offset: Offset.zero,
                size: cardBoxRect.size,
              );
              layerManager.addLayer(background);
            } else {
              LayerItem layer = LayerItem(
                UniqueKey(),
                type: _selectedType,
                object: child,
                offset: Offset.zero,
                size: cardBoxRect.size,
              );
              layerManager.addLayer(layer);
            }
            setState(() {});
          },
        );
      default:
        return const SizedBox();
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
                TextEditorStyle? textEditorStyle = await showGeneralDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.5),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return RectClipper(
                      rect: cardBoxRect.expandToInclude(objectBoxRect),
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
                  offset: Offset.zero,
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
                (Uint8List?, Size?)? data = await showGeneralDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.5),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return RectClipper(
                      rect: cardBoxRect.expandToInclude(objectBoxRect),
                      child: const BrushPainter(),
                    );
                  },
                );
                setState(() {});
                if ((data != null && data.$1 != null && data.$2 != null)) {
                  var image = Image.memory(data.$1!);
                  var size = data.$2!;
                  setState(() {
                    Offset offset = Offset(
                        cardBoxRect.size.width / 2 - size.width / 2, cardBoxRect.size.height / 2 - size.height / 2);
                    var layer = LayerItem(
                      UniqueKey(),
                      type: LayerType.drawing,
                      object: image,
                      offset: offset,
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
