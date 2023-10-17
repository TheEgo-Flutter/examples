part of 'photo_card.dart';

class DialogValue {
  final Widget dialog;
  final Widget no;
  final Widget yes;

  DialogValue({required this.dialog, required this.no, required this.yes});
}

class PhotoEditor extends ConsumerStatefulWidget {
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
    this.aspectRatio = 300 / 464,
    this.cardRadius = const Radius.circular(16),
    this.completed = const Text('저장'),
    this.onComplete,
    this.onCancel,
    this.onStartDialog,
    this.onCancelDialog,
  }) : super(key: key);
  @override
  ConsumerState<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends ConsumerState<PhotoEditor> with WidgetsBindingObserver, TickerProviderStateMixin {
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  // var layerManager = LayerManager();

  LinearGradient? cardColor;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  double get statusBarHeight => MediaQuery.of(context).padding.top;
  @override
  void initState() {
    super.initState();
    fontFamilies = widget.resources.fonts;
    drawingData = [];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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
    // ref.invalidate(layerManagerNotifierProvider);
    // layerManager.clearLayers();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startDialog() async {
    List<LayerItem>? result = await widget.onStartDialog?.call();
    if (result != null && result.isNotEmpty) {
      ref.read(layerManagerNotifierProvider.notifier).loadLayers(result);
      // layerManager.loadLayers(result);
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
    // layerManager.addLayer(layer);
    ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
  }

  Future<void> _loadImageColor(Uint8List? imageFile) async {
    if (imageFile != null) {
      ColorScheme newScheme = await ColorScheme.fromImageProvider(provider: MemoryImage(imageFile));

      cardColor = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          newScheme.primaryContainer,
          newScheme.primary,
        ],
      );
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
    ref.watch(layerManagerNotifierProvider);
    return Theme(
      data: theme,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: scaffoldGlobalKey,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => swapWidget(null),
              child: Container(
                color: background,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                double space = kToolbarHeight / 3;
                int cardFlex = 70;
                double maxWidth = (constraints.maxHeight) * cardFlex / 100 * widget.aspectRatio;

                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: Column(
                      children: [
                        SizedBox(
                          height: statusBarHeight,
                        ),
                        const SizedBox(
                          height: kToolbarHeight,
                        ),
                        SizedBox(
                          height: space,
                        ),
                        Expanded(
                          flex: cardFlex,
                          child: GestureDetector(
                            onTap: () => swapWidget(null),
                            child: AspectRatio(
                              aspectRatio: widget.aspectRatio,
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(widget.cardRadius),
                                child: buildImageLayer(context),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 100 - cardFlex,
                          child: Container(
                            padding: EdgeInsets.only(top: space),
                            child: Stack(
                              key: GlobalRect().objectAreaKey,
                              children: [
                                IgnorePointer(
                                  ignoring: _animationController.isAnimating,
                                  child: buildItemArea(),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(microseconds: 100),
                                  child: SlideTransition(
                                    position: _offsetAnimation,
                                    child: switchingWidget(),
                                  ),
                                ),
                              ],
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
      key: GlobalRect().cardAreaKey,
      decoration: cardColor != null
          ? BoxDecoration(
              gradient: cardColor,
            )
          : const BoxDecoration(color: Colors.white),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ref.watch(layerManagerNotifierProvider).layers != null)
            ...ref.watch(layerManagerNotifierProvider).layers!.map((layer) => buildLayerWidgets(layer)),
        ],
      ),
    );
  }

  Widget buildLayerWidgets(LayerItem layer) {
    return GestureDetector(
      key: Key('${layer.key}'),
      child: DraggableResizable(
        key: Key('${layer.key}_draggableResizable'),
        isFocus: layer.type.isDraggable,
        onLayerTapped: (LayerItem item) async {
          if (item.type is TextType) {
            ref.read(layerManagerNotifierProvider.notifier).removeLayerByKey(item.key);

            (TextBoxInput, Offset)? result = await showGeneralDialog(
                context: context,
                barrierColor: Colors.transparent,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return TextEditor(
                    textEditorStyle: item.object as TextBoxInput,
                  );
                });

            if (result == null) {
              ref.read(layerManagerNotifierProvider.notifier).addLayer(item);
            } else {
              TextBoxInput value = result.$1;
              InlineSpan? span = TextSpan(text: value.text, style: value.style);

              Size size = textSize(span, context, maxWidth: GlobalRect().cardRect.width);
              LayerItem newItem = item.copyWith(
                object: value,
                rect: (item.rect.topLeft & size),
              )..newKey();
              ref.read(layerManagerNotifierProvider.notifier).addLayer(newItem);
            }
          }

          if (item.type.isObject) {
            ref.read(layerManagerNotifierProvider.notifier).swap(item);
          }
        },
        onDragStart: (LayerItem item) {
          if (item.type.isObject) {
            ref.read(layerManagerNotifierProvider.notifier).swap(item);
          }
        },
        onDragEnd: (LayerItem item) {
          ref.read(layerManagerNotifierProvider.notifier).updateLayer(item);
        },
        onDelete: (layerItem) => ref.read(layerManagerNotifierProvider.notifier).removeLayerByKey(layerItem.key),
        layerItem: layer,
      ),
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
                widget.onCancel?.call(ref.read(layerManagerNotifierProvider).layers!);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: InkWell(
                splashFactory: NoSplash.splashFactory,
                onTap: () {
                  widget.onComplete?.call(ref.read(layerManagerNotifierProvider).layers!);
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
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.red,
          );
        }).then(
      (value) => ref.read(layerManagerNotifierProvider.notifier).setSelectedLayer(null),
    );
    // if (!_animationController.isAnimating) {
    //   if (type == null) {
    //     _animationController
    //         .reverse()
    //         .then((value) => ref.read(layerManagerNotifierProvider.notifier).setSelectedLayer(null));
    //   } else {
    //     _animationController.forward(from: 0.0);
    //     ref.read(layerManagerNotifierProvider.notifier).setSelectedLayer(type);
    //   }
    // }
  }

  void switchingDialog(LayerType type, BuildContext context) async {
    ref.read(layerManagerNotifierProvider.notifier).setSelectedLayer(type);
    switch (type) {
      case TextType():
        (TextBoxInput, Offset)? result = await showGeneralDialog(
          context: context,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) {
            return const TextEditor();
          },
        );

        if (result == null) break;
        TextBoxInput value = result.$1;
        InlineSpan? span = TextSpan(text: value.text, style: value.style);
        Size size = textSize(span, context, maxWidth: GlobalRect().cardRect.width);
        var layer = LayerItem(
          UniqueKey(),
          type: TextType(),
          object: value,
          rect: result.$2 & size,
        );
        ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);

        break;
      case DrawingType():
        (Uint8List?, Size?)? data = await showGeneralDialog(
          context: context,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) {
            return BrushPainter(
              cardRadius: widget.cardRadius,
            );
          },
        );

        if ((data != null && data.$1 != null)) {
          var layer = LayerItem(
            UniqueKey(),
            type: DrawingType(),
            object: data.$1!,
            rect: GlobalRect().cardRect.zero,
          );
          ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
        }
        break;
      default:
        break;
    }
  }

  Widget switchingWidget() {
    switch (ref.watch(layerManagerNotifierProvider).selectedLayerType) {
      case BackgroundType():
        return Container(
          decoration: const BoxDecoration(
            color: bottomSheet,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              LayerItem? background = ref
                  .watch(layerManagerNotifierProvider)
                  .layers!
                  .where((element) => element.type is BackgroundType)
                  .firstOrNull;

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
                      ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);

                      dialogSetState(() {
                        value = color; // <-- Update the local color here
                      });
                    },
                  ),
                  Expanded(
                    child: ImageSelector(
                      aspectRatio: widget.aspectRatio,
                      items: widget.resources.backgrounds,
                      firstItem: GestureDetector(
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
                            ref.read(layerManagerNotifierProvider.notifier).addLayer(imageBackground);
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
                        ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      case FrameType():
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
            firstItem: GestureDetector(
              onTap: () {
                ref.read(layerManagerNotifierProvider.notifier).removeLayerByType(FrameType());
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
              ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
            },
          ),
        );
      case StickerType():
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
              ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
            },
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
