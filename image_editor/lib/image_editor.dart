import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:render/render.dart';
import 'package:vibration/vibration.dart';

import 'modules/modules.dart';
import 'ui/rect.dart';
import 'ui/rect_clipper.dart';
import 'utils/global.dart';
import 'utils/layer_manager.dart';
import 'utils/util.dart';
import 'widget/delete_icon.dart';
import 'widget/draggable_resizable.dart';

class ImageEditor extends StatefulWidget {
  final List<dynamic> stickers;
  final List<dynamic> backgrounds;
  final List<dynamic> frames;
  final AspectRatioOption aspectRatio;

  const ImageEditor({
    super.key,
    this.stickers = const [],
    this.backgrounds = const [],
    this.frames = const [],
    this.aspectRatio = AspectRatioOption.r9x16,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> with WidgetsBindingObserver, TickerProviderStateMixin {
  Size get view => MediaQuery.of(context).size;
  LayerType? _selectedType;
  LayerManager layerManager = LayerManager();
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  List<LinearGradient> gradients = [];
  LinearGradient? cardColor;

  @override
  void initState() {
    super.initState();
    gradients = RandomGradientContainers().buildRandomGradientContainer(10);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    bottomInsetNotifier.value = MediaQuery.of(context).viewInsets.bottom;
  }

  @override
  void dispose() {
    layerManager.layers.clear();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadImageColor(Uint8List? imageFile) async {
    if (imageFile != null) {
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
    } else {
      cardColor = null;
    }
  }

  Future<Uint8List> _loadImage(dynamic imageFile) async {
    if (imageFile is Uint8List) return imageFile;
    final image = await (imageFile as dynamic).readAsBytes();
    return image;
  }

  void _handleDeleteAction(
    Offset currentFingerPosition,
    LayerItem layerItem,
    bool isDragging,
  ) async {
    if (!(selectedLayerItem?.isObject ?? false)) return;
    if (!deleteAreaRect.contains(currentFingerPosition)) return;
    if (isDragging) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(amplitude: 100);
      }
    } else {
      layerManager.removeLayerByKey(layerItem.key);
    }
  }

  Stream<RenderNotifier>? renderStream;
  final RenderController renderController = RenderController(logLevel: LogLevel.debug);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: Builder(builder: (context) {
        return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              key: scaffoldGlobalKey,
              backgroundColor: Theme.of(context).canvasColor,
              body: SafeArea(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double space = 8;
                      int cardFlex = 75;
                      double maxWidth =
                          (constraints.maxHeight - space) * cardFlex / 100 * (widget.aspectRatio.ratio ?? 1);

                      return SizedBox(
                        width: maxWidth,
                        child: Column(
                          children: [
                            SizedBox(
                              width: objectBoxRect.width,
                              height: kToolbarHeight,
                            ),
                            Expanded(
                              flex: cardFlex,
                              child: Padding(
                                padding: cardPadding,
                                child: Render(
                                  controller: renderController,
                                  child: ClipPath(
                                    key: cardAreaKey,
                                    clipper: CardBoxClip(aspectRatio: widget.aspectRatio),
                                    child: buildImageLayer(context),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: space),
                            Expanded(
                              flex: 100 - cardFlex,
                              child: SizedBox(
                                width: maxWidth,
                                child: ClipPath(
                                  key: objectAreaKey,
                                  clipper: CardBoxClip(),
                                  child: buildItemArea(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ));
      }),
    );
  }

  Widget buildImageLayer(BuildContext context) {
    Logger().i(layerManager.layers.map((e) => '${e.toString()} \n'));
    return Container(
      decoration: cardColor != null
          ? BoxDecoration(
              gradient: cardColor,
            )
          : const BoxDecoration(color: Colors.white),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ...layerManager.layers.map((layer) => buildLayerWidgets(layer)),
          DeleteIconButton(
            visible: selectedLayerItem?.isObject ?? false,
          ),
        ],
      ),
    );
  }

  Widget buildLayerWidgets(LayerItem layer) {
    return DraggableResizable(
      key: Key('${layer.key}_draggableResizable_asset'),
      isFocus: selectedLayerItem?.key == layer.key ? true : false,
      onLayerTapped: (LayerItem item) async {
        if (item.type == LayerType.text) {
          Logger().e(item.toString());
          setState(() {
            layerManager.removeLayerByKey(item.key);
          });
          (TextBoxInput, Offset)? result = await showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) {
              return RectClipper(
                rect: cardBoxRect.expandToInclude(objectBoxRect),
                child: TextEditor(
                  textEditorStyle: item.object as TextBoxInput,
                ),
              );
            },
          );
          if (result != null) {
            layerManager.addLayer(
              item.copyWith(
                object: result.$1,
                rect: (item.rect.topLeft & result.$1.size),
              ),
            );
          } else {
            layerManager.addLayer(item);
          }
        }
        setState(() {
          selectedLayerItem = item;
          if (item.isObject) {
            layerManager.moveLayerToFront(item);
          }
        });
      },
      onDragStart: (LayerItem item) {
        setState(() {
          selectedLayerItem = item;
          if (item.isObject) {
            layerManager.moveLayerToFront(item);
          }
        });
      },
      onDragEnd: (LayerItem item) {
        layerManager.updateLayer(item);
        setState(() {
          selectedLayerItem = null;
        });
      },
      onDelete: _handleDeleteAction,
      layerItem: layer,
    );
  }

  Widget buildItemArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.image),
                  onPressed: () {
                    setState(() {
                      _selectedType = LayerType.background;
                    });
                    customObjectBoxSizeDialog(
                        context: context,
                        child: BackgroundSelector(
                          items: [
                            ...List.generate(
                              colors.length,
                              (index) => BackgroundItem.color(colors[index]),
                            ),
                            ...widget.backgrounds.map((image) => BackgroundItem.image(image)).toList(),
                          ],
                          galleryButton: const Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                          ),
                          onGallerySelected: (value) async {
                            if (value == null) return;
                            Uint8List? loadImage = await _loadImage(value);
                            await _loadImageColor(loadImage);
                            LayerItem imageBackground = LayerItem(
                              UniqueKey(),
                              type: LayerType.image,
                              object: Image.memory(loadImage),
                              rect: cardBoxRect.zero,
                            );
                            layerManager.addLayer(imageBackground);
                          },
                          onItemSelected: (child) async {
                            {
                              await _loadImageColor(null);
                              LayerItem layer = LayerItem(
                                UniqueKey(),
                                type: LayerType.background,
                                object: child,
                                rect: cardBoxRect.zero,
                              );
                              layerManager.addLayer(layer);
                            }
                            setState(() {});
                          },
                        ));
                  },
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.texture_outlined),
                  onPressed: () {
                    setState(() {
                      _selectedType = LayerType.frame;
                    });
                    customObjectBoxSizeDialog(
                        context: context,
                        child: FrameSelector(
                          items: widget.frames,
                          onItemSelected: (child) {
                            late LayerItem layer;
                            if (child == null) {
                              layer = LayerItem(
                                UniqueKey(),
                                type: LayerType.frame,
                                object: null,
                                rect: cardBoxRect.zero,
                              );
                            } else {
                              layer = LayerItem(
                                UniqueKey(),
                                type: LayerType.frame,
                                object: child,
                                rect: cardBoxRect.zero,
                              );
                            }
                            layerManager.addLayer(layer);
                            setState(() {});
                          },
                        ));
                  },
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.face),
                  onPressed: () {
                    setState(() {
                      _selectedType = LayerType.sticker;
                    });
                    customObjectBoxSizeDialog(
                        context: context,
                        child: ItemSelector.sticker(
                          items: widget.stickers,
                          onSelected: (child) {
                            if (child == null) return;

                            Size size = const Size(150, 150);
                            Offset offset = Offset(cardBoxRect.size.width / 2 - size.width / 2,
                                cardBoxRect.size.height / 2 - size.height / 2);

                            LayerItem layer = LayerItem(
                              UniqueKey(),
                              type: LayerType.sticker,
                              object: child,
                              rect: (offset & size),
                            );
                            layerManager.addLayer(layer);
                            setState(() {});
                          },
                        ));
                  },
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.font_download_rounded),
                  onPressed: () async {
                    (TextBoxInput, Offset)? result = await customFullSizeDialog(
                      context: context,
                      child: const TextEditor(),
                    );

                    setState(() {});

                    if (result == null) return;
                    var layer = LayerItem(
                      UniqueKey(),
                      type: LayerType.text,
                      object: result.$1,
                      rect: result.$2 & result.$1.size,
                    );
                    layerManager.addLayer(layer);
                    setState(() {});
                  },
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.brush),
                  onPressed: () async {
                    (Uint8List?, Size?)? data = await showGeneralDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return const BrushPainter();
                      },
                    );

                    setState(() {});
                    if ((data != null && data.$1 != null)) {
                      var image = Image.memory(data.$1!);

                      setState(() {
                        var layer = LayerItem(
                          UniqueKey(),
                          type: LayerType.drawing,
                          object: image,
                          rect: cardBoxRect.zero,
                        );
                        layerManager.addLayer(layer);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[850],
                  foregroundColor: Colors.white,
                  child: IconButton(
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(),
                    icon: Transform.translate(
                      offset: const Offset(5, 0),
                      child: const Icon(
                        Icons.arrow_back_ios,
                      ),
                    ),
                    onPressed: () {
                      Navigator.canPop(context) ? Navigator.pop(context) : null;
                    },
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  foregroundColor: Colors.grey[850],
                  backgroundColor: Colors.white,
                  child: IconButton(
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
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 30.0),
        )
      ],
    );
  }
}
