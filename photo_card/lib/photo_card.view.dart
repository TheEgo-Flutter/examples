part of 'photo_card.dart';

class PhotoCard extends StatefulWidget {
  final List<LayerItem> tempSavedLayers;
  final AspectRatioEnum aspectRatio;
  const PhotoCard({super.key, required this.tempSavedLayers, this.aspectRatio = AspectRatioEnum.photoCard});

  @override
  State<PhotoCard> createState() => _PhotoCardViewerState();
}

class _PhotoCardViewerState extends State<PhotoCard> {
  LayerManager layerManager = LayerManager();
  BoxDecoration boxDecoration = const BoxDecoration(color: Colors.white);

  @override
  void initState() {
    layerManager.loadLayers(widget.tempSavedLayers);
    layerManager.newKeyLayers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      boxDecoration = await loadBackgroundColor();
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio.ratio ?? 1,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(CARD_RADIUS),
        child: Container(
          decoration: boxDecoration,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(children: [
                ...layerManager.layers.map(
                  (layer) {
                    Rect newRect = computeNewObjectRect(
                        backgroundOld: layerManager.layers.first.rect,
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
      ),
    );
  }

  Future<BoxDecoration> loadBackgroundColor() async {
    if (layerManager.backgroundLayer?.type.background == Background.gallery) {
      var gradient = await loadImageColor(layerManager.backgroundLayer?.object as Image);
      return BoxDecoration(gradient: gradient ?? const LinearGradient(colors: [Colors.white, Colors.white]));
    } else if (layerManager.backgroundLayer?.type.background == Background.color) {
      return BoxDecoration(color: layerManager.backgroundLayer?.object as Color);
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
