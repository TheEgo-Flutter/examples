part of 'photo_card.dart';

const double _cardAspectRatio = 300 / 464;

class PhotoCard extends ConsumerStatefulWidget {
  final List<LayerItem> tempSavedLayers;
  final double aspectRatio;
  const PhotoCard({
    super.key,
    required this.tempSavedLayers,
    this.aspectRatio = _cardAspectRatio,
  });

  @override
  ConsumerState<PhotoCard> createState() => _PhotoCardViewerState();
}

class _PhotoCardViewerState extends ConsumerState<PhotoCard> {
  // LayerManager layerManager = LayerManager();
  BoxDecoration boxDecoration = const BoxDecoration(color: Colors.white);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(layerManagerNotifierProvider.notifier).loadLayers(widget.tempSavedLayers);
      ref.read(layerManagerNotifierProvider.notifier).newKeyLayers();

      boxDecoration = await loadBackgroundColor();
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: boxDecoration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(children: [
              ...ref.watch(layerManagerNotifierProvider).layers!.map(
                (layer) {
                  Rect newRect = computeNewObjectRect(
                      backgroundOld: ref.watch(layerManagerNotifierProvider).layers!.first.rect,
                      objectOld: layer.rect,
                      backgroundNewSize: constraints.biggest);

                  LayerItem newItem = layer.copyWith(rect: newRect);

                  return Transform(
                    transform: Matrix4.identity()
                      ..translate(newRect.topLeft.dx, newRect.topLeft.dy)
                      ..rotateZ(layer.angle),
                    child: ChildLayerItem(
                      layerItem: newItem,
                    ),
                  );
                },
              ).toList(),
            ]);
          },
        ),
      ),
    );
    // ClipRRect(
    //   borderRadius: const BorderRadius.all(CARD_RADIUS),
    //   child: ,
    // );
  }

  Future<BoxDecoration> loadBackgroundColor() async {
    if (ref.watch(layerManagerNotifierProvider).backgroundLayer?.type.background == Background.gallery) {
      var gradient = await loadImageColor(ref.watch(layerManagerNotifierProvider).backgroundLayer?.object as Image);
      return BoxDecoration(gradient: gradient ?? const LinearGradient(colors: [Colors.white, Colors.white]));
    } else if (ref.watch(layerManagerNotifierProvider).backgroundLayer?.type.background == Background.color) {
      return BoxDecoration(color: ref.watch(layerManagerNotifierProvider).backgroundLayer?.object as Color);
    } else {
      return const BoxDecoration(color: Colors.white);
    }
  }

  Future<LinearGradient?> loadImageColor(Image image) async {
    ColorScheme newScheme = await ColorScheme.fromImageProvider(provider: image.image);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomCenter,
      colors: [
        newScheme.primaryContainer,
        newScheme.primary,
      ],
    );
  }
}

Rect computeNewObjectRect({
  required Rect backgroundOld,
  required Rect objectOld,
  required Size backgroundNewSize,
}) {
  double xScale = backgroundNewSize.width / backgroundOld.width;
  double yScale = backgroundNewSize.height / backgroundOld.height;
  double objectNewWidth = objectOld.width * xScale;
  double objectNewHeight = objectOld.height * yScale;
  double objectNewLeft = objectOld.left * xScale;
  double objectNewTop = objectOld.top * yScale;
  return Rect.fromLTWH(objectNewLeft, objectNewTop, objectNewWidth, objectNewHeight);
}
