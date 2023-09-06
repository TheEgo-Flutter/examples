import 'dart:async';

import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:render/render.dart';
import 'package:vibration/vibration.dart';

import 'lib.dart';

class ImageEditor extends StatelessWidget {
  final List<Uint8List> stickers;
  final List<ImageProvider> backgrounds;
  final List<ImageProvider> frames;
  final AspectRatioOption aspectRatio;

  const ImageEditor({
    super.key,
    this.stickers = const [],
    this.backgrounds = const [],
    this.frames = const [],
    this.aspectRatio = AspectRatioOption.r9x16,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: _ImageEditorView(
        stickers: stickers,
        backgrounds: backgrounds,
        frames: frames,
        aspectRatio: aspectRatio,
      ),
    );
  }
}

class _ImageEditorView extends StatefulWidget {
  final List<Uint8List> stickers;
  final List<ImageProvider> backgrounds;
  final List<ImageProvider> frames;
  final AspectRatioOption aspectRatio;

  const _ImageEditorView({
    super.key,
    this.stickers = const [],
    this.backgrounds = const [],
    this.frames = const [],
    this.aspectRatio = AspectRatioOption.r9x16,
  });

  @override
  State<_ImageEditorView> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<_ImageEditorView> with WidgetsBindingObserver, TickerProviderStateMixin {
  Size get view => MediaQuery.of(context).size;

  LayerManager layerManager = LayerManager();
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  List<LinearGradient> gradients = [];
  LinearGradient? cardColor;

  @override
  void initState() {
    super.initState();
    gradients = RandomGradientContainers().buildRandomGradientContainer(10);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureRects();
    });
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

  void _captureRects() {
    GlobalRect()
      ..cardRect = GlobalRect().getRect(GlobalRect().cardAreaKey)
      ..objectRect = GlobalRect().getRect(GlobalRect().objectAreaKey)
      ..statusBarSize = MediaQuery.of(context).padding.top;
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
    if (!GlobalRect().deleteRect.contains(currentFingerPosition)) return;
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: scaffoldGlobalKey,
        backgroundColor: Theme.of(context).canvasColor,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                double space = 8;
                int cardFlex = 75;
                double maxWidth = (constraints.maxHeight - space) * cardFlex / 100 * (widget.aspectRatio.ratio ?? 1);

                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: Column(
                      children: [
                        SizedBox(
                          height: kToolbarHeight,
                          width: GlobalRect().objectRect.width,
                        ),
                        Expanded(
                          flex: cardFlex,
                          child: Padding(
                            padding: cardPadding,
                            child: ClipPath(
                              key: GlobalRect().cardAreaKey,
                              clipper: CardBoxClip(aspectRatio: widget.aspectRatio),
                              child: Render(
                                controller: renderController,
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
                              key: GlobalRect().objectAreaKey,
                              clipper: CardBoxClip(),
                              child: buildItemArea(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImageLayer(BuildContext context) {
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
              barrierColor: Colors.transparent,
              pageBuilder: (context, animation, secondaryAnimation) {
                return TextEditor(
                  textEditorStyle: item.object as TextBoxInput,
                );
              });

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
      mainAxisAlignment: MainAxisAlignment.start,
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
                  icon: const Icon(DUIcons.picture),
                  onPressed: () {
                    LayerItem? background =
                        layerManager.layers.where((element) => element.type == LayerType.backgroundImage).firstOrNull;
                    Color? initialColor = background == null
                        ? Colors.white
                        : background.object.runtimeType == ColoredBox
                            ? (background.object as ColoredBox).color
                            : null;
                    customObjectBoxSizeDialog(
                        context: context,
                        child: Column(
                          children: [
                            ColorBar(
                              initialColor: initialColor,
                              onColorChanged: (color) async {
                                {
                                  await _loadImageColor(null);
                                  LayerItem layer = LayerItem(
                                    UniqueKey(),
                                    type: LayerType.backgroundColor,
                                    object: color,
                                    rect: GlobalRect().cardRect.zero,
                                  );
                                  layerManager.addLayer(layer);
                                }
                                setState(() {});
                              },
                            ),
                            Expanded(
                              child: ImageSelector(
                                items: widget.backgrounds,
                                firstItem: GestureDetector(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      var value = await picker.pickImage(source: ImageSource.gallery);
                                      if (value == null) return;
                                      Uint8List? loadImage = await _loadImage(value);
                                      await _loadImageColor(loadImage);
                                      LayerItem imageBackground = LayerItem(
                                        UniqueKey(),
                                        type: LayerType.selectImage,
                                        object: Image.memory(loadImage),
                                        rect: GlobalRect().cardRect.zero,
                                      );
                                      layerManager.addLayer(imageBackground);
                                    },
                                    child: const Icon(
                                      DUIcons.picture,
                                      color: Colors.white,
                                    )),
                                onItemSelected: (child) async {
                                  {
                                    await _loadImageColor(null);
                                    LayerItem layer = LayerItem(
                                      UniqueKey(),
                                      type: LayerType.backgroundImage,
                                      object: child,
                                      rect: GlobalRect().cardRect.zero,
                                    );
                                    layerManager.addLayer(layer);
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
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
                  icon: const Icon(DUIcons.tool_marquee),
                  onPressed: () {
                    customObjectBoxSizeDialog(
                        context: context,
                        child: ImageSelector(
                          items: widget.frames,
                          firstItem: GestureDetector(
                            onTap: () async {
                              LayerItem layer = LayerItem(
                                UniqueKey(),
                                type: LayerType.frame,
                                object: null,
                                rect: GlobalRect().cardRect.zero,
                              );
                              layerManager.addLayer(layer);
                              setState(() {});
                            },
                            child: const Icon(
                              DUIcons.ban,
                              color: Colors.white,
                            ),
                          ),
                          onItemSelected: (child) {
                            LayerItem layer = LayerItem(
                              UniqueKey(),
                              type: LayerType.frame,
                              object: child,
                              rect: GlobalRect().cardRect.zero,
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
                  icon: const Icon(DUIcons.sticker),
                  onPressed: () {
                    customObjectBoxSizeDialog(
                        context: context,
                        child: StickerSelector(
                          items: widget.stickers,
                          onSelected: (child) {
                            if (child == null) return;

                            Size size = const Size(150, 150);
                            Offset offset = Offset(GlobalRect().cardRect.size.width / 2 - size.width / 2,
                                GlobalRect().cardRect.size.height / 2 - size.height / 2);

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
                  icon: const Icon(DUIcons.letter_case),
                  onPressed: () async {
                    (TextBoxInput, Offset)? result = await showGeneralDialog(
                        context: context,
                        barrierColor: Colors.transparent,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return const TextEditor();
                        });

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
                  icon: const Icon(DUIcons.paint_brush),
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
                      setState(() {
                        var layer = LayerItem(
                          UniqueKey(),
                          type: LayerType.drawing,
                          object: data.$1!,
                          rect: GlobalRect().cardRect.zero,
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
        const SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                child: IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    DUIcons.back,
                  ),
                  onPressed: () {
                    Navigator.canPop(context) ? Navigator.pop(context) : null;
                  },
                ),
              ),
              Center(
                child: GestureDetector(
                    onTap: () async {
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
                    child: const VideoContainer()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
