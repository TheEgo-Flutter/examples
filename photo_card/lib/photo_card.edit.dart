import 'package:du_icons/du_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_card.dart';

class PhotoEditor extends StatefulWidget {
  final CaptureController? captureController;
  final DiyResources resources;
  final double aspectRatio;
  final Widget completed;
  final Function(List<LayerItem>)? onComplete;
  final Function(List<LayerItem>)? onCancel;
  final AsyncValueGetter<List<LayerItem>?>? onStartDialog;
  final AsyncValueGetter<bool?>? onCancelDialog;
  final Radius cardRadius;
  const PhotoEditor({
    Key? key,
    required this.resources,
    this.captureController,
    this.aspectRatio = 300 / 464,
    this.cardRadius = const Radius.circular(16),
    this.completed = const Text('저장'),
    this.onComplete,
    this.onCancel,
    this.onStartDialog,
    this.onCancelDialog,
  }) : super(key: key);
  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> with WidgetsBindingObserver, TickerProviderStateMixin {
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  var layerManager = LayerManager();
  LayerType? _selectedLayer;
  LinearGradient? cardColor;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  double get statusBarHeight => MediaQuery.of(context).padding.top;
  final DrawingDataNotifier drawingDataNotifier = DrawingDataNotifier([]);
  @override
  void initState() {
    super.initState();
    fontFamilies = widget.resources.fonts;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureRect();
      _initialBackground();
      _startDialog();
    });
  }

  @override
  void didChangeMetrics() {
    bottomInsetNotifier.value = MediaQuery.of(context).viewInsets.bottom;
  }

  @override
  void dispose() {
    layerManager.clearLayers();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startDialog() async {
    List<LayerItem>? result = await widget.onStartDialog?.call();
    if (result != null && result.isNotEmpty) {
      layerManager.loadLayers(result);
      setState(() {});
    }
  }

  void _captureRect() {
    GlobalRect()
      ..cardRect = GlobalRect().getRect(GlobalRect().cardAreaKey)
      ..objectRect = GlobalRect().getRect(GlobalRect().objectAreaKey)
      ..statusBarSize = statusBarHeight;
  }

  void _initialBackground() {
    LayerItem layer = LayerItem(
      UniqueKey(),
      type: const BackgroundType.color(),
      object: Colors.white,
      rect: GlobalRect().cardRect.zero,
    );
    layerManager.addLayer(layer);
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => swapWidget(null),
      child: Theme(
        data: theme,
        child: Scaffold(
          key: scaffoldGlobalKey,
          resizeToAvoidBottomInset: false,
          backgroundColor: background,
          body: SafeArea(
            top: true,
            bottom: false,
            left: false,
            right: false,
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double fullAspectRatio = 360 / 760;
                  const double padding = 16;
                  double maxHeight = constraints.maxHeight;
                  double maxWidth = (constraints.maxHeight) * fullAspectRatio;
                  return Container(
                    alignment: Alignment.center,
                    constraints: BoxConstraints(
                      // 최소/최대 너비와 높이를 정의합니다.
                      minWidth: maxWidth / 3,
                      minHeight: maxHeight / 3,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => swapWidget(null),
                              child: Padding(
                                padding: const EdgeInsets.all(padding),
                                child: AspectRatio(
                                  aspectRatio: widget.aspectRatio,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(widget.cardRadius),
                                    child: buildImageLayer(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: padding,
                            ),
                            Expanded(
                              child: IgnorePointer(
                                key: GlobalRect().objectAreaKey,
                                ignoring: _animationController.isAnimating,
                                child: buildItemArea(),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(microseconds: 100),
                            child: SlideTransition(
                              position: _offsetAnimation,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  // GlobalRect().objectRect.height 와 GlobalRect().cardRect.height / 2 중 큰 쪽으로
                                  maxHeight: GlobalRect().objectRect.height > GlobalRect().cardRect.height / 2
                                      ? GlobalRect().objectRect.height
                                      : GlobalRect().cardRect.height / 2,
                                ),
                                child: switchingWidget(),
                              ),
                            ),
                          ),
                        ),
                        /* debug code
                           IgnorePointer(
                            ignoring: true,
                            child: Container(
                              width: maxWidth,
                              height: maxHeight,
                              color: Colors.lightGreen.withOpacity(0.2),
                            ),
                          )
                          */
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImageLayer(BuildContext context) {
    return CaptureWidget(
      controller: widget.captureController,
      child: Container(
        key: GlobalRect().cardAreaKey,
        decoration: cardColor != null
            ? BoxDecoration(
                gradient: cardColor,
              )
            : const BoxDecoration(color: Colors.white),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ...layerManager.layers.map((layer) => buildLayerWidgets(layer)),
          ],
        ),
      ),
    );
  }

  Widget buildLayerWidgets(LayerItem layer) {
    return DraggableResizable(
      key: Key('${layer.key}_draggableResizable'),
      canTransform: layerManager.selectedLayerItem?.key == layer.key ? true : false,
      onTap: (LayerItem item) async {
        if (item.type is TextType) {
          setState(() {
            layerManager.removeLayerByKey(item.key);
          });
          (TextBoxInput, Rect)? result = await showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              pageBuilder: (context, animation, secondaryAnimation) {
                return TextEditor(
                  textEditorStyle: item.object as TextBoxInput,
                );
              });

          if (result == null) {
            layerManager.addLayer(item);
            setState(() {});
          } else {
            // TextBoxInput value = result.$1;
            // InlineSpan? span = TextSpan(text: value.text, style: value.style);

            // Size size = textSize(span, context, maxWidth: GlobalRect().cardRect.width);
            LayerItem newItem = item.copyWith(
              object: result.$1,
              rect: (item.rect.topLeft & result.$2.size),
            )..newKey();
            layerManager.addLayer(newItem);
            setState(() {});
          }
        }
      },
      onTapDown: (LayerItem item) async {
        if (item.type.isObject) {
          layerManager.swap(item);
        }
      },
      onDragStart: (LayerItem item) {
        setState(() {
          layerManager.selectedLayerItem = item;
          if (item.type.isObject) {
            layerManager.swap(item);
          }
        });
      },
      onDragEnd: (LayerItem item) {
        layerManager.updateLayer(item);
        setState(() {
          layerManager.selectedLayerItem = null;
        });
      },
      onDelete: (layerItem) => layerManager.removeLayerByKey(layerItem.key),
      layerItem: layer,
    );
  }

  Widget buildItemArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleIconButton(
                iconData: DUIcons.picture,
                onPressed: () {
                  swapWidget(const BackgroundType());
                },
              ),
              CircleIconButton(
                iconData: DUIcons.tool_marquee,
                onPressed: () {
                  swapWidget(FrameType());
                },
              ),
              CircleIconButton(
                iconData: DUIcons.sticker,
                onPressed: () {
                  swapWidget(StickerType());
                },
              ),
              CircleIconButton(
                iconData: DUIcons.letter_case,
                onPressed: () {
                  switchingDialog(TextType(), context);
                },
              ),
              CircleIconButton(
                iconData: DUIcons.paint_brush,
                onPressed: () {
                  switchingDialog(DrawingType(), context);
                },
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        bottomButtons(),
      ],
    );
  }

  Padding bottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          CircleIconButton(
            iconData: DUIcons.back,
            onPressed: () async {
              bool? result = await widget.onCancelDialog?.call();

              if (result ?? false) {
                widget.onCancel?.call(layerManager.layers);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: InkWell(
                splashFactory: NoSplash.splashFactory,
                onTap: () {
                  widget.onComplete?.call(layerManager.layers);
                },
                child: widget.completed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void swapWidget(LayerType? type) {
    if (!_animationController.isAnimating) {
      if (type == null) {
        _animationController.reverse().then((value) => setState(() {
              _selectedLayer = null;
            }));
      } else {
        _animationController.forward(from: 0.0);
        setState(() {
          _selectedLayer = type;
        });
      }
    }
  }

  void switchingDialog(LayerType type, BuildContext context) async {
    setState(() {
      _selectedLayer = type;
    });
    switch (type) {
      case TextType():
        (TextBoxInput, Rect)? result = await showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const TextEditor();
          },
        );

        setState(() {});

        if (result == null) break;
        TextBoxInput value = result.$1;

        var layer = LayerItem(
          UniqueKey(),
          type: TextType(),
          object: value,
          rect: result.$2,
        );
        layerManager.addLayer(layer);
        setState(() {});
        break;
      case DrawingType():
        if (mounted) {
          setState(() {
            layerManager.removeLayerByType(DrawingType());
          });
          await showGeneralDialog(
            context: context,
            barrierColor: Colors.transparent,
            pageBuilder: (context, animation, secondaryAnimation) {
              return BrushPainter(
                drawingDataNotifier: drawingDataNotifier,
                cardRadius: widget.cardRadius,
              );
            },
          ).whenComplete(() async {
            (Uint8List?, Size?)? data = await drawingDataNotifier.getImageData(context);
            if ((data != null && data.$1 != null)) {
              LayerItem layer = LayerItem(
                UniqueKey(),
                type: DrawingType(),
                object: data.$1,
                rect: GlobalRect().cardRect.zero,
              );
              layerManager.addLayer(layer);
              setState(() {});
            }
          });

          break;
        }
      default:
        break;
    }
  }

  Widget switchingWidget() {
    switch (_selectedLayer) {
      case BackgroundType():
        return _buildBackgroundItems();
      case FrameType():
        return _buildFrameItems();
      case StickerType():
        return _buildStickerItems();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBackgroundItems() {
    return Container(
      decoration: const BoxDecoration(
        color: bottomSheet,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, dialogSetState) {
          LayerItem? background = layerManager.layers.where((element) => element.type is BackgroundType).firstOrNull;
          Color? value = background == null
              ? Colors.white
              : background.type.background == Background.color
                  ? (background.object as Color)
                  : null;
          return Column(
            children: [
              ColorBar(
                value: value,
                onColorChanged: (color) async {
                  await _loadImageColor(null);
                  LayerItem layer = LayerItem(
                    UniqueKey(),
                    type: const BackgroundType.color(),
                    object: color,
                    rect: GlobalRect().cardRect.zero,
                  );
                  layerManager.addLayer(layer);
                  dialogSetState(() {
                    value = color; // <-- Update the local color here
                  });
                  setState(() {});
                },
              ),
              Expanded(
                child: ImageSelector(
                  aspectRatio: widget.aspectRatio,
                  items: widget.resources.backgrounds,
                  firstItem: SelectorFirstItem(
                      onTap: () async {
                        final picker = ImagePicker();
                        var value = await picker.pickImage(source: ImageSource.gallery);
                        if (value == null) return;
                        Uint8List? loadImage = await _loadImage(value);
                        await _loadImageColor(loadImage);
                        LayerItem imageBackground = LayerItem(
                          UniqueKey(),
                          type: const BackgroundType.gallery(),
                          object: Image.memory(loadImage),
                          rect: GlobalRect().cardRect.zero,
                        );
                        dialogSetState(
                          () {
                            value = null; // <-- Reset the local color here
                          },
                        );
                        setState(() {});
                        layerManager.addLayer(imageBackground);
                      },
                      child: const Icon(
                        DUIcons.picture,
                        color: Colors.white,
                      )),
                  onItemSelected: (child) async {
                    await _loadImageColor(null);
                    LayerItem layer = LayerItem(
                      UniqueKey(),
                      type: const BackgroundType.image(),
                      object: child,
                      rect: GlobalRect().cardRect.zero,
                    );
                    dialogSetState(
                      () {
                        value = null; // <-- Reset the local color here
                      },
                    );
                    setState(() {});
                    layerManager.addLayer(layer);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFrameItems() {
    return Container(
      decoration: const BoxDecoration(
        color: bottomSheet,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: ImageSelector(
        aspectRatio: widget.aspectRatio,
        items: widget.resources.frames,
        firstItem: SelectorFirstItem(
          onTap: () {
            layerManager.removeLayerByType(FrameType());
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
            type: FrameType(),
            object: child,
            rect: GlobalRect().cardRect.zero,
          );
          layerManager.addLayer(layer);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildStickerItems() {
    return Container(
      decoration: const BoxDecoration(
        color: bottomSheet,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: StickerSelector(
        items: widget.resources.stickers,
        onSelected: (child) {
          if (child == null) return;

          Size size = GlobalRect().stickerSize;
          Offset offset = Offset(GlobalRect().cardRect.size.width / 2 - size.width / 2,
              GlobalRect().cardRect.size.height / 2 - size.height / 2);

          LayerItem layer = LayerItem(
            UniqueKey(),
            type: StickerType(),
            object: child,
            rect: (offset & size),
          );
          layerManager.addLayer(layer);
          setState(() {});
        },
      ),
    );
  }
}
