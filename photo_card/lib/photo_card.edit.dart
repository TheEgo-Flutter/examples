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

  double get statusBarHeight => MediaQuery.of(context).padding.top;
  @override
  void initState() {
    super.initState();
    fontFamilies = widget.resources.fonts;
    drawingData = [];

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
      key: UniqueKey(),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            double space = kToolbarHeight / 3;
            int cardFlex = 70;
            // double maxWidth = (constraints.maxHeight) * cardFlex / 100 * widget.aspectRatio;

            return Center(
              child: SizedBox(
                // width: maxWidth,
                child: Column(
                  children: [
                    SizedBox(
                      height: statusBarHeight + space,
                    ),
                    Expanded(
                      flex: cardFlex,
                      child: AspectRatio(
                        aspectRatio: widget.aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(widget.cardRadius),
                          child: buildImageLayer(context),
                        ),
                      ),
                    ),
                    Expanded(
                      key: GlobalRect().objectAreaKey,
                      flex: 100 - cardFlex,
                      child: Container(
                        padding: EdgeInsets.only(top: space),
                        child: buildItemArea(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
          // if (ref.watch(layerManagerNotifierProvider).layers != null)
          ...ref.watch(layerManagerNotifierProvider).layers!.map((layer) => buildLayerWidgets(layer)),
        ],
      ),
    );
  }

  Widget buildLayerWidgets(LayerItem layer) {
    return DraggableResizable(
      key: Key('${layer.key}_draggableResizable'),
      canTransform: ref.watch(layerManagerNotifierProvider).objectLayers.lastOrNull?.key == layer.key,
      onTap: (LayerItem item) async {
        if (item.type is TextType) {
          ref.read(layerManagerNotifierProvider.notifier).removeLayerByKey(item.key);

          (TextBoxInput, Rect)? result = await showGeneralDialog(
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
            // TextBoxInput value = result.$1;
            // InlineSpan? span = TextSpan(text: value.text, style: value.style);

            // Size size = textSize(span, context, maxWidth: GlobalRect().cardRect.width);
            LayerItem newItem = item.copyWith(
              object: result.$1,
              rect: (item.rect.topLeft & result.$2.size),
            )..newKey();
            ref.read(layerManagerNotifierProvider.notifier).addLayer(newItem);
          }
        }
      },
      onTapDown: (LayerItem item) async {
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

        // 초기화는 backgroundType으로 변경
        ref.read(layerManagerNotifierProvider.notifier).initSelectedLayerItem();
      },
      onDelete: (layerItem) => ref.read(layerManagerNotifierProvider.notifier).removeLayerByKey(layerItem.key),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleIconButton(
                iconData: DUIcons.picture,
                onPressed: () {
                  swapWidget(const BackgroundType());
                },
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                iconData: DUIcons.tool_marquee,
                onPressed: () {
                  swapWidget(FrameType());
                },
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                iconData: DUIcons.sticker,
                onPressed: () {
                  swapWidget(StickerType());
                },
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                iconData: DUIcons.letter_case,
                onPressed: () {
                  switchingDialog(TextType(), context);
                },
              ),
              const SizedBox(width: 8),
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
    if (type == null) return;
    customBottomSheet(
      context: context,
      contents: _buildContents(type),
    ).then(
      (value) => ref.read(layerManagerNotifierProvider.notifier).setSelectedLayerType(null),
    );
  }

  void switchingDialog(LayerType type, BuildContext context) async {
    ref.read(layerManagerNotifierProvider.notifier).setSelectedLayerType(type);
    switch (type) {
      case TextType():
        (TextBoxInput, Rect)? result = await showGeneralDialog(
          context: context,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) {
            return const TextEditor();
          },
        );

        if (result == null) break;
        TextBoxInput value = result.$1;
        // InlineSpan? span = TextSpan(text: value.text, style: value.style);
        // Size size = textSize(span, context, maxWidth: GlobalRect().cardRect.width);
        var layer = LayerItem(
          key: UniqueKey(),
          type: TextType(),
          object: value,
          rect: result.$2,
        );
        ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);

        break;
      case DrawingType():
        if (mounted) {
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
              key: UniqueKey(),
              type: DrawingType(),
              object: data.$1!,
              rect: GlobalRect().cardRect.zero,
            );
            ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
          }
        }
        break;
      default:
        break;
    }
  }

  Widget _buildContents(type) {
    switch (type) {
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
    return StatefulBuilder(
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
                  key: UniqueKey(),
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
                        key: UniqueKey(),
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
                    key: UniqueKey(),
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
    );
  }

  Widget _buildFrameItems() {
    return ImageSelector(
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
          key: UniqueKey(),
          type: FrameType(),
          object: child,
          rect: GlobalRect().cardRect.zero,
        );
        ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
      },
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
          GifController controller = GifController();
          LayerItem layer = LayerItem(
            key: UniqueKey(),
            type: StickerType(),
            object: GifView(
              controller: controller,
              fadeDuration: const Duration(milliseconds: 300),
              image: child,
              width: size.width,
              height: size.height,
            ),
            rect: (offset & size),
          );

          ref.read(layerManagerNotifierProvider.notifier).addLayer(layer);
        },
      ),
    );
  }
}
